"""从 firecrawl scrape 产物切段，输出 gold-standard 候选 raw segments。

工程实现 spec.md §0 anti-leakage：
- 切段：按 \\n\\n 分段，过滤 80-400 字 + 中文比例 ≥ 50% + 排除导航/标题/列表
- anchor 优先：含 anchor 词的段优先入选（D2/D4 marginal 平衡需求）
- trigram Jaccard 查重：与 constitution §5 + cicpa 108 段双源比对，> 0.3 丢弃
- 输出 schema 与 raw-segments-cicpa.jsonl 同（segment_id / genre / source / text /
  char_len / hash_trigram / leakage_check），无 scores / auto_evidence / annotator / verified

CLI:
    python slice-web-segments.py \\
        --input-dir .firecrawl \\
        --genre-prefix g67 \\
        --target 52 \\
        --out raw-segments-web-g67.jsonl
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
from typing import Iterable

CHINESE_RE = re.compile(r"[一-鿿]")
URL_RE = re.compile(r"https?://\S+|www\.\S+")
MD_LINK_RE = re.compile(r"\[[^\]]*\]\([^)]*\)")
MD_IMAGE_RE = re.compile(r"!\[[^\]]*\]\([^)]*\)")

D2_ANCHORS = ["赋能", "重塑", "闭环", "抓手", "链路", "打造", "助力", "深度融合", "多维度",
              "综上所述", "由此可见", "本质上", "值得注意的是", "必须强调的是",
              "至关重要", "不可或缺", "深入贯彻", "全面推进"]
D3_ANCHORS = ["三层防御", "防火墙", "闸门", "跑通", "走通", "翻车", "踩坑", "杀手锏",
              "主战场", "阵地", "组合拳", "三件套", "王炸"]
D4_DACHANG_ANCHORS = ["对标", "拉通", "对齐", "颗粒度", "底层逻辑", "顶层设计", "心智",
                       "赛道", "赛马", "跑赢", "生态化反", "复盘"]
ANCHORS = set(D2_ANCHORS + D3_ANCHORS + D4_DACHANG_ANCHORS)

GENRE_MAP = {
    "g67": "opinion-essay",  # G6 随笔 + G7 自媒体
    "g1": "official-document",  # G1 公文
    "g2": "speech",  # G2 讲话稿
}


def char_trigrams(text: str) -> set[str]:
    text = re.sub(r"\s+", "", text)
    return {text[i : i + 3] for i in range(len(text) - 2)} if len(text) >= 3 else set()


def jaccard(a: set[str], b: set[str]) -> float:
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)


def hash_trigram(text: str) -> str:
    tris = sorted(char_trigrams(text))
    return hashlib.sha256("".join(tris).encode("utf-8")).hexdigest()[:16]


def clean_paragraph(text: str) -> str:
    text = MD_IMAGE_RE.sub("", text)
    text = MD_LINK_RE.sub(lambda m: m.group(0).split("]")[0][1:], text)
    text = URL_RE.sub("", text)
    text = re.sub(r"^\s*[\*\-•]\s+", "", text, flags=re.MULTILINE)
    text = re.sub(r"^\s*#{1,6}\s+", "", text, flags=re.MULTILINE)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def is_valid_segment(text: str, min_chars: int, max_chars: int) -> bool:
    if not (min_chars <= len(text) <= max_chars):
        return False
    chinese_count = len(CHINESE_RE.findall(text))
    if chinese_count < len(text) * 0.5:
        return False
    if text.count("|") > 3 or text.count("\t") > 2:
        return False
    if text.startswith(">") or text.startswith("```"):
        return False
    if re.search(r"^\d+[\.\、]\s+[A-Z]", text):
        return False
    return True


def extract_paragraphs(markdown: str) -> Iterable[str]:
    raw_blocks = markdown.split("\n\n")
    for block in raw_blocks:
        cleaned = clean_paragraph(block)
        if cleaned:
            yield cleaned


def count_anchors(text: str) -> int:
    return sum(1 for a in ANCHORS if a in text)


def load_existing_trigrams(jsonl_paths: list[Path]) -> list[tuple[str, set[str]]]:
    result: list[tuple[str, set[str]]] = []
    for p in jsonl_paths:
        if not p.exists():
            continue
        for line in p.open():
            item = json.loads(line)
            text = item.get("text", "")
            sid = item.get("segment_id") or item.get("id") or "(no-id)"
            result.append((sid, char_trigrams(text)))
    return result


def load_constitution_examples(constitution_path: Path) -> list[tuple[str, set[str]]]:
    text = constitution_path.read_text(encoding="utf-8")
    examples: list[tuple[str, str]] = []
    in_section_5 = False
    current_id = ""
    current_text = ""
    for line in text.splitlines():
        if line.startswith("## §5"):
            in_section_5 = True
            continue
        if line.startswith("## §6") and in_section_5:
            if current_id and current_text:
                examples.append((current_id, current_text))
            break
        if not in_section_5:
            continue
        if line.startswith("### Example"):
            if current_id and current_text:
                examples.append((current_id, current_text))
            current_id = line.strip()
            current_text = ""
        elif line.startswith(">"):
            current_text += " " + line.lstrip("> ").strip()
    return [(eid, char_trigrams(t)) for eid, t in examples if t]


def main() -> None:
    parser = argparse.ArgumentParser()
    here = Path(__file__).parent
    parser.add_argument("--input-dir", type=Path, default=here / ".firecrawl")
    parser.add_argument("--genre-prefix", required=True, choices=["g67", "g1", "g2"])
    parser.add_argument("--target", type=int, required=True)
    parser.add_argument("--min-chars", type=int, default=80)
    parser.add_argument("--max-chars", type=int, default=400)
    parser.add_argument("--jaccard-threshold", type=float, default=0.3)
    parser.add_argument("--constitution", type=Path, default=here.parent.parent / "references" / "constitution.md")
    parser.add_argument("--existing-jsonls", type=Path, nargs="*", default=[here / "raw-segments-cicpa.jsonl"])
    parser.add_argument("--anchor-min", type=int, default=0,
                        help="只保留 anchor 命中数 ≥ 此值的段（G6/G7 适合设 1）")
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--report-out", type=Path, default=None)
    args = parser.parse_args()

    report_out = args.report_out or args.out.with_name(args.out.stem + "-report.md")
    genre = GENRE_MAP[args.genre_prefix]

    fewshot_trigrams = load_constitution_examples(args.constitution)
    existing_trigrams = load_existing_trigrams(args.existing_jsonls)
    print(f"[leakage] {len(fewshot_trigrams)} few-shot examples + {len(existing_trigrams)} existing segments loaded")

    candidates: list[dict] = []
    drop_log: list[dict] = []
    stats = {"raw_paras": 0, "kept_after_filter": 0, "dropped_leakage": 0, "dropped_anchor_min": 0}

    scrape_files = sorted(args.input_dir.glob(f"{args.genre_prefix}-*.json"))
    for sf in scrape_files:
        try:
            data = json.loads(sf.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        markdown = data.get("markdown", "") or ""
        url = (data.get("metadata") or {}).get("sourceURL") or (data.get("metadata") or {}).get("url") or sf.name
        for para in extract_paragraphs(markdown):
            stats["raw_paras"] += 1
            if not is_valid_segment(para, args.min_chars, args.max_chars):
                continue
            anchor_cnt = count_anchors(para)
            if anchor_cnt < args.anchor_min:
                stats["dropped_anchor_min"] += 1
                continue
            text_tri = char_trigrams(para)
            max_jac = 0.0
            max_src = ""
            for src_id, src_tri in fewshot_trigrams + existing_trigrams:
                j = jaccard(text_tri, src_tri)
                if j > max_jac:
                    max_jac = j
                    max_src = src_id
            if max_jac > args.jaccard_threshold:
                stats["dropped_leakage"] += 1
                drop_log.append({"text_preview": para[:60], "matched": max_src, "jaccard": round(max_jac, 3)})
                continue
            stats["kept_after_filter"] += 1
            candidates.append({
                "text": para,
                "_url": url,
                "_anchor_count": anchor_cnt,
                "_max_jaccard": max_jac,
                "_source_file": sf.name,
            })

    candidates.sort(key=lambda c: (-c["_anchor_count"], c["_max_jaccard"]))
    seen_hashes: set[str] = set()
    picked: list[dict] = []
    inter_drop = 0
    for c in candidates:
        h = hash_trigram(c["text"])
        if h in seen_hashes:
            inter_drop += 1
            continue
        seen_hashes.add(h)
        picked.append(c)
        if len(picked) >= args.target:
            break
    stats["dropped_inter_dup"] = inter_drop

    out_records: list[dict] = []
    for idx, seg in enumerate(picked):
        record = {
            "segment_id": f"{args.genre_prefix}-web-{idx:04d}",
            "genre": genre,
            "source": {
                "type": "firecrawl-scrape",
                "url": seg["_url"],
                "scrape_file": seg["_source_file"],
                "anchor_count": seg["_anchor_count"],
            },
            "text": seg["text"],
            "char_len": len(seg["text"]),
            "hash_trigram": hash_trigram(seg["text"]),
            "leakage_check": {
                "vs_few_shot_and_existing_jaccard": round(seg["_max_jaccard"], 3),
                "threshold": args.jaccard_threshold,
                "passed": True,
            },
        }
        out_records.append(record)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as f:
        for r in out_records:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")

    with report_out.open("w", encoding="utf-8") as f:
        f.write(f"# Slice Report（{args.genre_prefix} / {genre}）\n\n")
        f.write(f"- scrape 文件：{len(scrape_files)} 个\n")
        f.write(f"- 原始段落：{stats['raw_paras']}\n")
        f.write(f"- 过滤后保留：{stats['kept_after_filter']}\n")
        f.write(f"- anchor < {args.anchor_min} 丢弃：{stats['dropped_anchor_min']}\n")
        f.write(f"- leakage > {args.jaccard_threshold} 丢弃：{stats['dropped_leakage']}\n")
        f.write(f"- 最终入选：{len(out_records)} / 目标 {args.target}\n\n")
        if drop_log:
            f.write(f"## leakage 丢弃明细（top 20）\n\n")
            f.write("| 预览 | 匹配源 | Jaccard |\n|---|---|---|\n")
            for entry in sorted(drop_log, key=lambda x: -x["jaccard"])[:20]:
                preview = entry["text_preview"].replace("|", "\\|")
                f.write(f"| {preview}... | {entry['matched']} | {entry['jaccard']} |\n")

    print(f"📊 stats: {stats}")
    print(f"✅ wrote {len(out_records)} segments to {args.out}")
    print(f"✅ wrote slice report to {report_out}")


if __name__ == "__main__":
    main()
