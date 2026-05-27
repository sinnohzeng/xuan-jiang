"""Self-Refine 闭环（xuan-jiang v5.0）。

**DEV-ONLY / DEPRECATED for production path（v5.0.0 起）**

v5.0.0 模型解耦后，生产路径的 Self-Refine 闭环由 Claude Code 主对话同上下文内完成
（judge → rewrite → judge 全部由主对话一个模型走，最多 3 轮）。本脚本仅用于跨模型 calibration
对比，验证不同 base model 在同一 prompt 下的 self-refine 收敛性。

机制：
  for round_i in range(max_rounds):
      score_t = judge(file)
      if score_t.passes(threshold): break
      rewrite_prompt = build_rewrite_prompt(file, score_t.findings)
      new_file = rewriter.call(rewrite_prompt)
      score_t1 = judge(new_file)
      if score_t1 <= score_t - min_delta: break   # 没有提升，停止（防越改越差）
      file = new_file

CLI:
    python self-refine-loop.py --file <md> --genre research-report [--max-rounds 3]
        [--min-delta 0.5] [--out-dir ./refined] [--rounds 3]

依赖：scripts/llm-judge-runner.py（同目录），scripts/model_adapter.py。

设计纪律：
- 单调性 break：D_total 没下降 >= min_delta 即停止，避免 rewriter 引入新问题
- 写盘留痕：每轮 rewrite 输出为 <stem>.refine-r<i>.md + judge result 同名 .json
- 配套 Layer 1 硬扫：每轮 rewrite 后调用 scan-hard-gate.sh，硬红线命中即继续
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
import importlib.util

_spec = importlib.util.spec_from_file_location("runner", Path(__file__).resolve().parent / "llm-judge-runner.py")
runner = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(runner)

from model_adapter import ModelAdapter, load_config  # noqa: E402

SKILL_ROOT = Path(__file__).resolve().parent.parent
HARD_GATE = SKILL_ROOT / "scripts" / "scan-hard-gate.sh"
DIMENSIONS = ["D1", "D2", "D3", "D4", "D5"]


def total_score(summary: dict[str, Any]) -> float:
    """对 5 维 max 求和作为 segment 级最严判分。None / unknown 视为 0。"""
    total = 0.0
    for dim in DIMENSIONS:
        v = summary.get(dim, {}).get("max")
        if isinstance(v, (int, float)):
            total += float(v)
    return total


def passes_threshold(summary: dict[str, Any], threshold: float) -> bool:
    """通过门槛：5 维 max 全部 ≤ 1 即过。threshold 是 D_total 上限。"""
    if total_score(summary) > threshold:
        return False
    for dim in DIMENSIONS:
        v = summary.get(dim, {}).get("max")
        if isinstance(v, int) and v >= 2:
            return False
    return True


def build_rewrite_prompt(text: str, judge_result: dict[str, Any], genre: str) -> tuple[str, str]:
    """根据 judge 反馈构造改写 prompt。返回 (system, user)。"""
    findings: list[str] = []
    for seg in judge_result["segments"]:
        scores = seg["scores"]
        ev = seg.get("evidence", {})
        for dim, val in scores.items():
            if isinstance(val, int) and val >= 2 and ev.get(dim):
                anchors = "、".join(ev[dim])
                findings.append(f"  - 段 {seg['segment_id']} {dim}={val}：命中 {anchors}")

    findings_text = "\n".join(findings) if findings else "  - 无具体发现，但综合评分偏高，请整体重写更克制。"

    system = (
        f"你是中文写作 AI 味改写专家，按照党政公文 / 第三方咨询报告（{genre}）的语体改写。\n\n"
        "改写铁律：\n"
        "1. 严禁机械替换（如把「赋能」改成「赋予能力」）——必须重构整段表述，回到事实陈述。\n"
        "2. 保留原文事实、数字、专有名词、技术术语；只改 AI 味的句式与套话。\n"
        "3. 中文标点统一用 GB/T 15834-2011 弯引号「」「』正式格式（双引号 “ ” / 单引号 ‘ ’）。\n"
        "4. 禁用 — 破折号、（如…）补充叙事、半中半英术语（操作 checklist 等）。\n"
        "5. 「一是 / 二是 / 三是」党政标准列举法可保留；「首先 / 其次 / 最后」三段式套壳必须删除。\n"
        "6. 输出**仅改写后的中文正文**，不要前后说明、不要解释、不要 markdown 包裹。\n\n"
        "若原文结构难以局部修复，可整段重组；但禁止扩写。\n"
    )

    user = (
        f"## 待改写文本（{genre}）\n\n```\n{text}\n```\n\n"
        f"## Judge 发现的问题（按段定位）\n\n{findings_text}\n\n"
        "## 输出要求\n\n"
        "仅输出改写后的中文正文。若有 frontmatter（---...---），原样保留在文首。\n"
        f"当前日期：{date.today().isoformat()}（防止误判已发布的政策文号为未来日期）。\n"
    )

    return system, user


def hard_gate_pass(file_path: Path) -> bool:
    """Layer 1 硬扫：exit 0 才通过。脚本不存在或异常视为软通过。"""
    if not HARD_GATE.exists():
        return True
    try:
        result = subprocess.run(
            ["bash", str(HARD_GATE), str(file_path)],
            capture_output=True,
            text=True,
            timeout=30,
        )
        return result.returncode == 0
    except (subprocess.TimeoutExpired, OSError):
        return True


def refine_once(
    text: str,
    judge_result: dict[str, Any],
    genre: str,
    rewriter: ModelAdapter,
) -> str:
    system, user = build_rewrite_prompt(text, judge_result, genre)
    return rewriter.call(system, user).strip()


def run(
    file_path: Path,
    genre: str | None,
    max_rounds: int,
    rounds: int,
    threshold: float,
    min_delta: float,
    out_dir: Path,
) -> dict[str, Any]:
    out_dir.mkdir(parents=True, exist_ok=True)
    stem = file_path.stem

    rewriter = ModelAdapter("rewriter")
    print(f"[refine] file={file_path.name} rewriter={rewriter.config.model} max_rounds={max_rounds}", file=sys.stderr)

    # round-0：先 judge 原文
    current_path = file_path
    history: list[dict[str, Any]] = []

    for round_i in range(max_rounds + 1):
        judge_result = runner.run(
            file_path=current_path,
            genre=genre,
            rounds=rounds,
            seg_size=200,
            overlap=30,
            out_path=out_dir / f"{stem}.judge-r{round_i}.json",
        )
        score = total_score(judge_result["summary"])
        gate_ok = hard_gate_pass(current_path)
        history.append({
            "round": round_i,
            "file": str(current_path),
            "total_score": score,
            "summary": judge_result["summary"],
            "hard_gate_pass": gate_ok,
        })
        print(
            f"[refine] round={round_i} total_score={score:.2f} "
            f"hard_gate={'PASS' if gate_ok else 'FAIL'} "
            f"D_max={[judge_result['summary'][d]['max'] for d in DIMENSIONS]}",
            file=sys.stderr,
        )

        if passes_threshold(judge_result["summary"], threshold) and gate_ok:
            print(f"[refine] PASS at round {round_i}", file=sys.stderr)
            break

        if round_i == max_rounds:
            print(f"[refine] max_rounds reached without passing", file=sys.stderr)
            break

        # 单调性 check：除 round-0，要求至少改善 min_delta；不改善即停（防越改越差）
        if round_i > 0:
            prev_score = history[-2]["total_score"]
            if score >= prev_score - min_delta + 0.001:
                # 没有显著下降，停止
                print(
                    f"[refine] no improvement (prev={prev_score:.2f}, now={score:.2f}, need ≤ {prev_score - min_delta:.2f}), stopping",
                    file=sys.stderr,
                )
                break

        # 改写一轮
        text = current_path.read_text(encoding="utf-8")
        new_text = refine_once(text, judge_result, genre or judge_result["genre"], rewriter)
        next_path = out_dir / f"{stem}.refine-r{round_i + 1}.md"
        next_path.write_text(new_text, encoding="utf-8")
        current_path = next_path
        print(f"[refine] wrote {next_path}", file=sys.stderr)

    final = {
        "file_original": str(file_path),
        "file_final": str(current_path),
        "genre": genre or history[0]["summary"],
        "max_rounds": max_rounds,
        "threshold": threshold,
        "min_delta": min_delta,
        "rounds_per_judge": rounds,
        "history": history,
        "passed": history[-1]["total_score"] <= threshold
        and all(
            not isinstance(history[-1]["summary"][d]["max"], int) or history[-1]["summary"][d]["max"] < 2
            for d in DIMENSIONS
        )
        and history[-1]["hard_gate_pass"],
    }
    (out_dir / f"{stem}.refine-summary.json").write_text(
        json.dumps(final, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    return final


def main() -> None:
    parser = argparse.ArgumentParser(description="xuan-jiang v5 Self-Refine 闭环")
    parser.add_argument("--file", type=Path, required=True)
    parser.add_argument("--genre", choices=list(runner.GENRE_KEYWORDS.keys()))
    parser.add_argument("--max-rounds", type=int, default=None, help="默认读 config self_refine_max_rounds")
    parser.add_argument("--rounds", type=int, default=None, help="每轮 judge pass^k 次数，默认读 config")
    parser.add_argument("--threshold", type=float, default=2.0, help="D_total 上限，默认 ≤ 2.0")
    parser.add_argument("--min-delta", type=float, default=None, help="单调性 break 阈值，默认读 config")
    parser.add_argument("--out-dir", type=Path, default=Path("./refined"))
    args = parser.parse_args()

    if not args.file.exists():
        print(f"File not found: {args.file}", file=sys.stderr)
        sys.exit(2)

    # 默认值从 default.yaml 读
    cfg_judge = load_config("judge")
    import yaml

    raw_cfg = yaml.safe_load((SKILL_ROOT / "config" / "default.yaml").read_text(encoding="utf-8"))
    layer = raw_cfg.get("layer_thresholds", {})
    max_rounds = args.max_rounds if args.max_rounds is not None else int(layer.get("self_refine_max_rounds", 3))
    min_delta = args.min_delta if args.min_delta is not None else float(layer.get("self_refine_min_score_delta", 0.5))
    rounds = args.rounds if args.rounds is not None else cfg_judge.vote_rounds

    result = run(
        file_path=args.file,
        genre=args.genre,
        max_rounds=max_rounds,
        rounds=rounds,
        threshold=args.threshold,
        min_delta=min_delta,
        out_dir=args.out_dir,
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
