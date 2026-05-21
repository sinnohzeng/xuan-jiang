"""Layer 2 LLM Judge 编排器（xuan-jiang v5.0）。

调用流程：
1. 加载 default.yaml + 用户/项目 yaml + env 兜底（由 model_adapter.py 实现）
2. 识别文种（先 frontmatter `type:`，否则简单规则分类）
3. 加载对应 prompts/llm-judge-<genre>.md
4. 段切（默认 200 字一段，跨段重叠 30 字）
5. 每段 pass^k 调 ModelAdapter（默认 vote_rounds=3，防 position bias）
6. 多数投票合成最终 score
7. 输出 JSON: {file, genre, segments: [{seg_id, scores: {D1..D5}, evidence, reasoning}], summary}

CLI:
    python llm-judge-runner.py --file <path> --genre research-report [--out result.json] [--rounds 3] [--seg-size 200]

设计原则：
- 「能 grep 走 grep，不能 grep 走 LLM」：本脚本是 Layer 2，Layer 1 由 scan-hard-gate.sh 完成。
- pass^k 投票防 position bias：每段独立采样 k 次，每个维度按 mode 决定终值；unknown 不参与投票。
- Calibration mode：--calibration-set 模式专为 evals/calibration-runner.sh 调用，输出按 segment_id 索引。
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from datetime import date
from pathlib import Path
from typing import Any

# 允许从同目录导入 model_adapter
sys.path.insert(0, str(Path(__file__).resolve().parent))
from model_adapter import ModelAdapter, load_config  # noqa: E402

SKILL_ROOT = Path(__file__).resolve().parent.parent
PROMPTS_DIR = SKILL_ROOT / "prompts"
DIMENSIONS = ["D1", "D2", "D3", "D4", "D5"]

GENRE_KEYWORDS = {
    "research-report": ["调研", "咨询", "实施方案", "现状", "建议", "对照"],
    "public-document": ["通知", "决定", "命令", "印发", "通报"],
    "speech": ["讲话", "致辞", "同志们", "在座的"],
    "position-report": ["述职", "本人", "任期", "汇报如下"],
    "essay": ["随笔", "杂文", "我认为", "我倾向"],
    "social-media": ["公众号", "本号", "粉丝", "种草"],
}


def parse_frontmatter(text: str) -> tuple[dict[str, Any], str]:
    """提取 markdown frontmatter（YAML）+ 正文。"""
    if not text.startswith("---"):
        return {}, text
    end = text.find("\n---", 4)
    if end < 0:
        return {}, text
    import yaml

    try:
        fm = yaml.safe_load(text[4:end]) or {}
    except yaml.YAMLError:
        fm = {}
    body = text[end + 4 :].lstrip("\n")
    return fm if isinstance(fm, dict) else {}, body


def detect_genre(text: str, frontmatter: dict[str, Any]) -> str:
    """文体识别：先看 frontmatter type，否则关键词计分。"""
    fm_type = frontmatter.get("type") or frontmatter.get("genre")
    if isinstance(fm_type, str) and fm_type in GENRE_KEYWORDS:
        return fm_type

    scores: dict[str, int] = {g: 0 for g in GENRE_KEYWORDS}
    head = text[:1500]
    for genre, keywords in GENRE_KEYWORDS.items():
        for kw in keywords:
            scores[genre] += head.count(kw)
    winner = max(scores.items(), key=lambda kv: kv[1])
    return winner[0] if winner[1] > 0 else "research-report"


def segment_text(text: str, seg_size: int = 200, overlap: int = 30) -> list[tuple[str, str]]:
    """按字符长度切段，跨段保留 overlap 字重叠。

    返回 [(seg_id, seg_text), ...]。seg_id 形如 "seg-0001"。
    切段优先按段落（双换行 / 句号）边界，再按字数兜底。
    """
    paragraphs = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]
    segments: list[str] = []
    buf = ""
    for para in paragraphs:
        if len(buf) + len(para) + 1 <= seg_size:
            buf = f"{buf}\n{para}" if buf else para
            continue
        if buf:
            segments.append(buf)
        if len(para) <= seg_size:
            buf = para
        else:
            sentences = re.split(r"(?<=[。！？；])", para)
            cur = ""
            for sent in sentences:
                if len(cur) + len(sent) <= seg_size:
                    cur += sent
                else:
                    if cur:
                        segments.append(cur)
                    cur = sent
            buf = cur
    if buf:
        segments.append(buf)

    if overlap > 0 and len(segments) > 1:
        overlapped = [segments[0]]
        for i in range(1, len(segments)):
            tail = segments[i - 1][-overlap:]
            overlapped.append(tail + segments[i])
        segments = overlapped

    return [(f"seg-{i:04d}", s) for i, s in enumerate(segments)]


def load_prompt(genre: str) -> str:
    """加载 prompts/llm-judge-<genre>.md。"""
    path = PROMPTS_DIR / f"llm-judge-{genre}.md"
    if not path.exists():
        fallback = PROMPTS_DIR / "llm-judge-research-report.md"
        if not fallback.exists():
            raise FileNotFoundError(f"No judge prompt for genre {genre} and no fallback")
        path = fallback
    return path.read_text(encoding="utf-8")


def extract_system_user(prompt_md: str) -> tuple[str, str]:
    """从 prompt md 切出 SYSTEM 段 + USER TEMPLATE 段。

    约定：md 内含 `## SYSTEM PROMPT` 和 `## USER PROMPT TEMPLATE` 两个 H2。
    """
    sys_match = re.search(r"## SYSTEM PROMPT\s*\n(.+?)(?=\n## (?:USER PROMPT|FEW-SHOT))", prompt_md, re.S)
    user_match = re.search(r"## USER PROMPT TEMPLATE\s*\n(.+?)(?=\n## (?:[A-Z]|评审纪律))", prompt_md, re.S)
    fewshot_match = re.search(r"## FEW-SHOT EXAMPLES.*?\n(.+?)(?=\n## USER PROMPT)", prompt_md, re.S)
    discipline_match = re.search(r"## 评审纪律\s*\n(.+)", prompt_md, re.S)

    system_parts = []
    if sys_match:
        system_parts.append(sys_match.group(1).strip())
    if fewshot_match:
        system_parts.append("\n\n## FEW-SHOT EXAMPLES\n\n" + fewshot_match.group(1).strip())
    if discipline_match:
        system_parts.append("\n\n## 评审纪律\n\n" + discipline_match.group(1).strip())

    user_template = user_match.group(1).strip() if user_match else (
        "段 ID：{{segment_id}}\n\n{{segment_text}}\n\n按 JSON Schema 输出 5 维评分。"
    )
    return "\n".join(system_parts), user_template


def render_template(template: str, mapping: dict[str, str]) -> str:
    out = template
    for k, v in mapping.items():
        out = out.replace("{{" + k + "}}", v)
    return out


def normalize_score(val: Any) -> int | str | None:
    """合法值：0/1/2/3 或 "unknown"，其他返回 None。"""
    if val == "unknown":
        return "unknown"
    if isinstance(val, bool):
        return None
    if isinstance(val, int) and 0 <= val <= 3:
        return val
    if isinstance(val, float) and val == int(val) and 0 <= int(val) <= 3:
        return int(val)
    if isinstance(val, str):
        s = val.strip().lower()
        if s == "unknown":
            return "unknown"
        if s.isdigit() and 0 <= int(s) <= 3:
            return int(s)
    return None


def vote_dimension(samples: list[Any]) -> Any:
    """多数投票：unknown 票仅在 ≥ 半数时获胜，否则用数值众数。"""
    valid = [normalize_score(s) for s in samples]
    valid = [v for v in valid if v is not None]
    if not valid:
        return "unknown"
    unknown_count = sum(1 for v in valid if v == "unknown")
    numeric = [v for v in valid if isinstance(v, int)]
    if unknown_count > len(valid) / 2 or not numeric:
        return "unknown"
    counter = Counter(numeric)
    winner, _ = counter.most_common(1)[0]
    return winner


def merge_evidence(samples: list[dict[str, Any]]) -> dict[str, list[str]]:
    """合并多轮 evidence：每个维度取所有非空证据的去重并集（保序）。"""
    merged: dict[str, list[str]] = {}
    for s in samples:
        ev = s.get("evidence") or {}
        if not isinstance(ev, dict):
            continue
        for dim, items in ev.items():
            if not isinstance(items, list):
                continue
            merged.setdefault(dim, [])
            for it in items:
                if isinstance(it, str) and it not in merged[dim]:
                    merged[dim].append(it)
    return merged


def judge_segment(
    adapter: ModelAdapter,
    system: str,
    user_template: str,
    seg_id: str,
    seg_text: str,
    rounds: int,
) -> dict[str, Any]:
    """对单段调用 judge 模型 rounds 次，pass^k 投票。"""
    samples: list[dict[str, Any]] = []
    user = render_template(user_template, {"segment_id": seg_id, "segment_text": seg_text})
    user_with_json_hint = user + "\n\n必须只输出合法 JSON 对象，不要任何解释。"
    for i in range(rounds):
        # 多轮采样用阶梯温度（0.0 / 0.1 / 0.2）扩样本空间，抑制 position bias 的同时不失精度
        temp = adapter.config.temperature if rounds == 1 else min(0.3, 0.1 * i)
        try:
            raw = adapter.call(system, user_with_json_hint, temperature=temp)
            try:
                parsed = json.loads(raw)
            except json.JSONDecodeError:
                start, end = raw.find("{"), raw.rfind("}")
                if start >= 0 and end > start:
                    parsed = json.loads(raw[start : end + 1])
                else:
                    raise
        except Exception as e:
            parsed = {"_error": str(e)}
        samples.append(parsed)

    voted = {dim: vote_dimension([s.get(dim) for s in samples]) for dim in DIMENSIONS}
    evidence = merge_evidence(samples)
    reasonings = [s.get("reasoning", "") for s in samples if isinstance(s.get("reasoning"), str)]

    return {
        "segment_id": seg_id,
        "scores": voted,
        "evidence": evidence,
        "reasoning_samples": reasonings,
        "rounds": rounds,
        "raw_samples": samples if "--debug" in sys.argv else None,
    }


def summarize(segments: list[dict[str, Any]]) -> dict[str, Any]:
    summary: dict[str, Any] = {}
    for dim in DIMENSIONS:
        numeric = [s["scores"][dim] for s in segments if isinstance(s["scores"][dim], int)]
        unknown = sum(1 for s in segments if s["scores"][dim] == "unknown")
        summary[dim] = {
            "mean": round(sum(numeric) / len(numeric), 2) if numeric else None,
            "max": max(numeric) if numeric else None,
            "unknown_count": unknown,
            "n_scored": len(numeric),
        }
    summary["total_segments"] = len(segments)
    summary["overall_fail"] = any(
        isinstance(summary[d]["max"], int) and summary[d]["max"] >= 3 for d in DIMENSIONS
    )
    return summary


def run(
    file_path: Path,
    genre: str | None,
    rounds: int,
    seg_size: int,
    overlap: int,
    out_path: Path | None,
) -> dict[str, Any]:
    text = file_path.read_text(encoding="utf-8")
    frontmatter, body = parse_frontmatter(text)
    if not genre:
        genre = detect_genre(body, frontmatter)

    prompt_md = load_prompt(genre)
    system_raw, user_template = extract_system_user(prompt_md)

    # 注入当前日期 + 项目例外（默认 cicpa 6 类已 inline 在 prompt 内）
    system = render_template(
        system_raw,
        {
            "current_date": date.today().isoformat(),
            "project_exemptions": "",  # 留给项目级 .xuan-jiang.yaml 后续注入
        },
    )

    segments = segment_text(body, seg_size=seg_size, overlap=overlap)
    adapter = ModelAdapter("judge")

    print(
        f"[judge] file={file_path.name} genre={genre} segments={len(segments)} "
        f"model={adapter.config.model} rounds={rounds}",
        file=sys.stderr,
    )

    results: list[dict[str, Any]] = []
    for seg_id, seg_text in segments:
        result = judge_segment(adapter, system, user_template, seg_id, seg_text, rounds)
        results.append(result)
        scores_str = " ".join(f"{d}={result['scores'][d]}" for d in DIMENSIONS)
        print(f"  {seg_id} [{len(seg_text)}字] {scores_str}", file=sys.stderr)

    output = {
        "file": str(file_path),
        "genre": genre,
        "model": adapter.config.model,
        "rounds": rounds,
        "current_date": date.today().isoformat(),
        "segments": results,
        "summary": summarize(results),
    }

    if out_path:
        out_path.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"[judge] wrote {out_path}", file=sys.stderr)

    return output


def main() -> None:
    parser = argparse.ArgumentParser(description="xuan-jiang v5 LLM Judge 编排器")
    parser.add_argument("--file", type=Path, required=True, help="待评分 markdown 文件")
    parser.add_argument("--genre", choices=list(GENRE_KEYWORDS.keys()), help="覆盖文体识别")
    parser.add_argument("--rounds", type=int, default=None, help="pass^k 采样轮数（默认读 config vote_rounds）")
    parser.add_argument("--seg-size", type=int, default=200, help="段切字符长度")
    parser.add_argument("--overlap", type=int, default=30, help="段间字符重叠")
    parser.add_argument("--out", type=Path, help="输出 JSON 路径（默认 stdout）")
    parser.add_argument("--debug", action="store_true", help="输出 raw_samples")
    args = parser.parse_args()

    if not args.file.exists():
        print(f"File not found: {args.file}", file=sys.stderr)
        sys.exit(2)

    rounds = args.rounds
    if rounds is None:
        cfg = load_config("judge")
        rounds = cfg.vote_rounds

    output = run(
        file_path=args.file,
        genre=args.genre,
        rounds=rounds,
        seg_size=args.seg_size,
        overlap=args.overlap,
        out_path=args.out,
    )

    if not args.out:
        print(json.dumps(output, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
