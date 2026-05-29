#!/usr/bin/env bash
# select-fewshot.sh — deterministic + 易难分层 few-shot anchor 选取（offline dev-eval，v7.0）
#
# v7.0：离线 dev-eval 工具，**不在 per-use 路径**（per-use reviewer 直接读 constitution §5 before→after）。
# 用于离线一致性实验时，从 evals/anchor-set.jsonl 抽 2 条 verified 样本（1 易 1 难）拼 few-shot。
# 用 sha256(draft_text) 做 seed → 同一 draft 跑两次结果一致。
# 排除与本次 draft 同 source_commit 的样本（防 Grader Gaming）。
#
# 用法：bash select-fewshot.sh <draft-path> <dimension>
#   <dimension>   D1 | D2 | D3 | D4 | D5（离线 eval 维度标签）
#
# stdout：2 行 jsonl（可空，anchor-set 为空或全被排除时）
# stderr：人类可读说明

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANCHOR="$SCRIPT_DIR/../anchor-set.jsonl"   # offline-harness/ 的父目录 evals/ 下

if [[ $# -ne 2 ]]; then
    echo "用法：bash select-fewshot.sh <draft-path> <dimension>" >&2
    exit 1
fi

DRAFT="$1"
DIM="$2"

if [[ ! "$DIM" =~ ^D[1-5]$ ]]; then
    echo "✗ dimension 必须是 D1..D5，得到：$DIM" >&2
    exit 1
fi
if [[ ! -f "$DRAFT" ]]; then
    echo "✗ draft 文件不存在：$DRAFT" >&2
    exit 1
fi
if [[ ! -f "$ANCHOR" ]]; then
    echo "⚠ anchor-set.jsonl 不存在；先跑 split-calibration.sh。当前 fallback 到 zero-shot。" >&2
    exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "✗ 需要 python3" >&2
    exit 1
fi

# 尝试用 git 拿 draft 当前 commit 短 sha；非 git 环境留空（即不排除）
DRAFT_COMMIT=""
if command -v git >/dev/null 2>&1; then
    DRAFT_COMMIT=$(git log -1 --pretty=format:%h -- "$DRAFT" 2>/dev/null || echo "")
fi

python3 - "$DRAFT" "$ANCHOR" "$DIM" "$DRAFT_COMMIT" <<'PY'
import hashlib
import json
import random
import sys

draft_path, anchor_path, dim, draft_commit = sys.argv[1:5]

with open(draft_path, "rb") as f:
    seed_bytes = f.read()
seed = int(hashlib.sha256(seed_bytes).hexdigest()[:16], 16)
rng = random.Random(seed)

easy, hard = [], []
with open(anchor_path, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            rec = json.loads(line)
        except json.JSONDecodeError:
            continue
        scores = rec.get("scores", {})
        s = scores.get(dim)
        if s == "unknown" or s is None:
            continue
        if not isinstance(s, int):
            continue
        # 同 commit 排除（防 Grader Gaming）
        src_commit = (rec.get("auto_evidence", {}).get("source_commit") or rec.get("source_commit", ""))[:7]
        if draft_commit and src_commit and src_commit == draft_commit:
            continue
        if s <= 1:
            easy.append(line)
        else:
            hard.append(line)

picks = []
if easy:
    picks.append(rng.choice(easy))
if hard:
    picks.append(rng.choice(hard))

if not picks:
    print(
        f"⚠ anchor-set 中无适用 {dim} 样本（同 commit 或 unknown 已排除）；fallback zero-shot",
        file=sys.stderr,
    )
    sys.exit(0)

for line in picks:
    print(line)

stratum = "1易+1难" if len(picks) == 2 else f"{len(picks)} 条"
print(
    f"[fewshot {dim}] picked {stratum} (seed=sha256(draft)[:16], excluded commit={draft_commit or 'none'})",
    file=sys.stderr,
)
PY
