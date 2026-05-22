"""从 Sprint 1 calibration-set.jsonl 衍生 Sprint 2 gold-standard 候选池。

Sprint 2 gold-standard spec.md §0 anti-leakage 5 条原则的工程落地：
1. trigram Jaccard 与 constitution §5 Example A-F 6 个 few-shot 比对，> 0.3 丢弃
2. 剥离 scores / auto_evidence / annotator / verified 字段（防 annotator 被锚定）
3. 按 WS1/WS3 → G3 调研报告、WS2/WS4 → G8 咨询报告映射 genre
4. 配对优先采样：每文体抽 before/after 配对段，平衡 marginal
5. 输出含 char_len + hash_trigram + leakage_check 可审计字段

CLI:
    python derive-from-calibration.py \\
        --calibration ../calibration-set.jsonl \\
        --constitution ../../references/constitution.md \\
        --g3-target 60 --g8-target 50 \\
        --jaccard-threshold 0.3 \\
        --out raw-segments-cicpa.jsonl
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from collections import Counter, defaultdict
from pathlib import Path


def char_trigrams(text: str) -> set[str]:
    text = re.sub(r"\s+", "", text)
    return {text[i : i + 3] for i in range(len(text) - 2)} if len(text) >= 3 else set()


def jaccard(a: set[str], b: set[str]) -> float:
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)


def extract_constitution_examples(constitution_path: Path) -> list[tuple[str, str]]:
    """从 constitution.md §5 Example A-F 抓 before/after 段文本。"""
    text = constitution_path.read_text(encoding="utf-8")
    examples: list[tuple[str, str]] = []
    in_section_5 = False
    for line in text.splitlines():
        if line.startswith("## §5"):
            in_section_5 = True
            continue
        if line.startswith("## §6"):
            break
        if not in_section_5:
            continue
        if line.startswith("### Example"):
            examples.append((line.strip(), ""))
        elif examples and line.startswith(">"):
            ex_id, prev = examples[-1]
            examples[-1] = (ex_id, prev + " " + line.lstrip("> ").strip())
    return examples


def derive_genre(source_file: str | None) -> str | None:
    if not source_file:
        return None
    if "WS1" in source_file or "WS3" in source_file:
        return "research-report"  # G3 调研报告
    if "WS2" in source_file or "WS4" in source_file:
        return "consulting-report"  # G8 咨询报告
    return None


def hash_trigram(text: str) -> str:
    tris = sorted(char_trigrams(text))
    digest = hashlib.sha256(("".join(tris)).encode("utf-8")).hexdigest()
    return digest[:16]


def main() -> None:
    parser = argparse.ArgumentParser()
    here = Path(__file__).parent
    parser.add_argument("--calibration", type=Path, default=here.parent / "calibration-set.jsonl")
    parser.add_argument("--constitution", type=Path, default=here.parent.parent / "references" / "constitution.md")
    parser.add_argument("--g3-target", type=int, default=60)
    parser.add_argument("--g8-target", type=int, default=50)
    parser.add_argument("--jaccard-threshold", type=float, default=0.3)
    parser.add_argument("--min-chars", type=int, default=80)
    parser.add_argument("--max-chars", type=int, default=400)
    parser.add_argument("--out", type=Path, default=here / "raw-segments-cicpa.jsonl")
    parser.add_argument("--report-out", type=Path, default=here / "leakage-report.md")
    args = parser.parse_args()

    examples = extract_constitution_examples(args.constitution)
    print(f"[leakage] loaded {len(examples)} few-shot examples from constitution §5")
    example_trigrams = [(ex_id, char_trigrams(text)) for ex_id, text in examples if text]

    candidates: dict[str, list[dict]] = defaultdict(list)
    leakage_log: list[dict] = []
    stats = Counter()

    with args.calibration.open() as f:
        for line in f:
            item = json.loads(line)
            text = item["text"]
            stats["total"] += 1
            if not (args.min_chars <= len(text) <= args.max_chars):
                stats["skipped_length"] += 1
                continue
            genre = derive_genre(item.get("source_file"))
            if not genre:
                stats["skipped_no_genre"] += 1
                continue
            text_tri = char_trigrams(text)
            max_jaccard = 0.0
            max_ex_id = ""
            for ex_id, ex_tri in example_trigrams:
                j = jaccard(text_tri, ex_tri)
                if j > max_jaccard:
                    max_jaccard = j
                    max_ex_id = ex_id
            if max_jaccard > args.jaccard_threshold:
                stats["dropped_leakage"] += 1
                leakage_log.append({
                    "segment_id": item["id"],
                    "matched_example": max_ex_id,
                    "jaccard": round(max_jaccard, 3),
                })
                continue
            candidates[genre].append({
                "_original_id": item["id"],
                "_source_file": item.get("source_file"),
                "_commit": item.get("source_commit"),
                "_kind": item["kind"],
                "text": text,
                "genre": genre,
                "max_jaccard_vs_few_shot": round(max_jaccard, 3),
            })

    print(f"[leakage] stats: {dict(stats)}")
    for g, segs in candidates.items():
        print(f"[candidate] {g}: {len(segs)} (before={sum(1 for s in segs if s['_kind']=='before')}, after={sum(1 for s in segs if s['_kind']=='after')})")

    def sample_balanced(pool: list[dict], target: int) -> list[dict]:
        before = [s for s in pool if s["_kind"] == "before"]
        after = [s for s in pool if s["_kind"] == "after"]
        half = target // 2
        picked: list[dict] = []
        picked.extend(before[: min(half, len(before))])
        picked.extend(after[: target - len(picked)])
        if len(picked) < target:
            picked.extend(before[len(picked) - len(after) :][: target - len(picked)])
        return picked[:target]

    g3 = sample_balanced(candidates["research-report"], args.g3_target)
    g8 = sample_balanced(candidates["consulting-report"], args.g8_target)

    if len(g3) < args.g3_target:
        print(f"⚠️  G3 不足：要 {args.g3_target}，实得 {len(g3)}")
    if len(g8) < args.g8_target:
        print(f"⚠️  G8 不足：要 {args.g8_target}，实得 {len(g8)}")

    out_records: list[dict] = []
    for idx, seg in enumerate(g3 + g8):
        genre_tag = "g3" if seg["genre"] == "research-report" else "g8"
        record = {
            "segment_id": f"{genre_tag}-cicpa-{idx:04d}",
            "genre": seg["genre"],
            "source": {
                "type": "cicpa-diff-derived",
                "commit": seg["_commit"],
                "file": seg["_source_file"],
                "kind": seg["_kind"],
                "derived_from": seg["_original_id"],
            },
            "text": seg["text"],
            "char_len": len(seg["text"]),
            "hash_trigram": hash_trigram(seg["text"]),
            "leakage_check": {
                "vs_few_shot_jaccard": seg["max_jaccard_vs_few_shot"],
                "threshold": args.jaccard_threshold,
                "passed": True,
            },
        }
        out_records.append(record)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as f:
        for r in out_records:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")

    with args.report_out.open("w", encoding="utf-8") as f:
        f.write("# Leakage Report（gold-standard 衍生过程）\n\n")
        f.write(f"- 候选池：{stats['total']} 段（Sprint 1 calibration-set.jsonl）\n")
        f.write(f"- 长度过滤丢弃：{stats['skipped_length']} 段\n")
        f.write(f"- 无 genre 映射丢弃：{stats['skipped_no_genre']} 段\n")
        f.write(f"- leakage > {args.jaccard_threshold} 丢弃：{stats['dropped_leakage']} 段\n")
        f.write(f"- G3 入选：{len(g3)} / {args.g3_target}\n")
        f.write(f"- G8 入选：{len(g8)} / {args.g8_target}\n")
        f.write(f"- 总入选：{len(out_records)} / {args.g3_target + args.g8_target}\n\n")
        if leakage_log:
            f.write(f"## 丢弃的 {len(leakage_log)} 段（按 Jaccard 倒序）\n\n")
            f.write("| segment_id | matched_example | jaccard |\n|---|---|---|\n")
            for entry in sorted(leakage_log, key=lambda x: -x["jaccard"])[:30]:
                f.write(f"| `{entry['segment_id']}` | {entry['matched_example']} | {entry['jaccard']} |\n")

    print(f"✅ wrote {len(out_records)} segments to {args.out}")
    print(f"✅ wrote leakage report to {args.report_out}")
    print(f"📊 schema check: no scores/auto_evidence/annotator/verified fields in output")


if __name__ == "__main__":
    main()
