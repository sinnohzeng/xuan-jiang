#!/usr/bin/env bash
# split-calibration.sh — anchor / eval 物理隔离工具（offline dev-eval，v7.0）
#
# 把 evals/calibration-set.jsonl 按 verified 字段静态拆分为两个视图：
#   evals/anchor-set.jsonl  ← verified == true，供离线 few-shot 校准 + before→after 来源
#   evals/eval-set.jsonl    ← 其余样本，供离线一致性 / regression（禁注入任何 prompt）
#
# v7.0：本脚本是离线 dev-eval 工具（在 evals/offline-harness/），不在 per-use 路径。
# 设计：拆分是只读派生（不动 calibration-set.jsonl 内容），多次跑结果稳定。
# 用法：bash split-calibration.sh [--force]
#         --force  覆盖已存在的 anchor-set / eval-set
# 退出码：0 成功且 anchor 非空 / 2 文件已存在需 --force / 3 jsonl 解析失败 / 4 anchor 为空（防静默空）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVALS_DIR="$SCRIPT_DIR/.."   # offline-harness/ 的父目录就是 evals/
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
    print("✗ anchor=0：calibration-set 内无 verified=true 样本。", file=sys.stderr)
    print("  → 人工 verify 至少 1 条后重跑（防静默空 anchor 再次发生）。", file=sys.stderr)
    sys.exit(4)
PY
