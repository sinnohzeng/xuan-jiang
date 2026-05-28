#!/usr/bin/env bash
# split-calibration.sh — anchor / eval 物理隔离工具（v6.1）
#
# 把 evals/calibration-set.jsonl 按 verified 字段静态拆分为两个视图：
#   evals/anchor-set.jsonl  ← verified == true，供 reviewer few-shot 注入
#   evals/eval-set.jsonl    ← 其余样本，供 κ 一致性 / regression（禁注入 prompt）
#
# 设计：拆分是只读派生（不动 calibration-set.jsonl 内容），多次跑结果稳定。
# 用法：bash split-calibration.sh [--force]
#         --force  覆盖已存在的 anchor-set / eval-set

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVALS_DIR="$SCRIPT_DIR/../evals"
SRC="$EVALS_DIR/calibration-set.jsonl"
ANCHOR="$EVALS_DIR/anchor-set.jsonl"
EVAL="$EVALS_DIR/eval-set.jsonl"

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

if [[ ! -f "$SRC" ]]; then
    echo "✗ 源文件不存在：$SRC" >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "✗ 需要 python3（解析 jsonl）" >&2
    exit 1
fi

if [[ -f "$ANCHOR" && $FORCE -eq 0 ]]; then
    echo "⚠ $ANCHOR 已存在，--force 覆盖" >&2
    exit 2
fi
if [[ -f "$EVAL" && $FORCE -eq 0 ]]; then
    echo "⚠ $EVAL 已存在，--force 覆盖" >&2
    exit 2
fi

python3 - "$SRC" "$ANCHOR" "$EVAL" <<'PY'
import json
import sys

src, anchor_path, eval_path = sys.argv[1:4]
n_total = n_anchor = n_eval = 0
with (
    open(src, "r", encoding="utf-8") as f_in,
    open(anchor_path, "w", encoding="utf-8") as f_anchor,
    open(eval_path, "w", encoding="utf-8") as f_eval,
):
    for line in f_in:
        line = line.strip()
        if not line:
            continue
        n_total += 1
        try:
            rec = json.loads(line)
        except json.JSONDecodeError as e:
            print(f"✗ 第 {n_total} 行不是合法 JSON：{e}", file=sys.stderr)
            sys.exit(3)
        if rec.get("verified") is True:
            f_anchor.write(line + "\n")
            n_anchor += 1
        else:
            f_eval.write(line + "\n")
            n_eval += 1

print(f"✓ split done: {n_total} total → anchor={n_anchor} (verified) + eval={n_eval} (others)")
print(f"  anchor: {anchor_path}")
print(f"  eval:   {eval_path}")
if n_anchor == 0:
    print("⚠ 当前 calibration-set 内无 verified=true 样本；reviewer few-shot 暂无可用 anchor。", file=sys.stderr)
    print("  → 人工 verify 后重跑，或暂时让 select-fewshot.sh fallback 到 zero-shot。", file=sys.stderr)
PY
