#!/usr/bin/env bash
# xuan-jiang v5.0 calibration runner（Sprint 1 gate）
#
# 流程：
#   1. 把 calibration-set.jsonl 每段写成临时文件喂给 llm-judge-runner.py
#   2. 收集所有 judge 输出，展平为 judge-results.jsonl (id + scores 一致 schema)
#   3. 跑 cohen-kappa.py 计算每维 κ + 整体 weighted κ
#   4. 输出 evals/calibration-results/{cohen_kappa.json, disagreement.md, per_segment.csv}
#
# Usage:
#   bash evals/calibration-runner.sh \
#       [--model claude-sonnet-4-6] \
#       [--rounds 3] \
#       [--threshold 0.8] \
#       [--limit 50]   # 只跑前 N 段（debug 用）
#
# 退出码：
#   0 = 通过 κ ≥ threshold；1 = 未达；2 = 运行错误

set -euo pipefail

SKILL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVALS_DIR="$SKILL_ROOT/evals"
SCRIPTS_DIR="$SKILL_ROOT/scripts"
RESULTS_DIR="$EVALS_DIR/calibration-results"

# 默认参数
ROUNDS=3
THRESHOLD="0.80"
LIMIT=""
MODEL=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rounds)    ROUNDS="$2"; shift 2 ;;
        --threshold) THRESHOLD="$2"; shift 2 ;;
        --limit)     LIMIT="$2"; shift 2 ;;
        --model)     MODEL="$2"; shift 2 ;;
        -h|--help)
            grep -E '^# ' "$0" | sed 's/^# //'
            exit 0 ;;
        *) echo "Unknown arg: $1" >&2; exit 2 ;;
    esac
done

if [[ -n "$MODEL" ]]; then
    export XUAN_JIANG_JUDGE_MODEL="$MODEL"
fi

CALIB_SET="$EVALS_DIR/calibration-set.jsonl"
if [[ ! -f "$CALIB_SET" ]]; then
    echo "❌ Missing $CALIB_SET — run extract-from-cicpa-commits.py first" >&2
    exit 2
fi

mkdir -p "$RESULTS_DIR"
TMP_DIR=$(mktemp -d -t xj-calib-XXXXXX)
trap "rm -rf $TMP_DIR" EXIT

JUDGE_RESULTS="$RESULTS_DIR/judge-results.jsonl"
: > "$JUDGE_RESULTS"

TOTAL=$(wc -l < "$CALIB_SET" | tr -d ' ')
if [[ -n "$LIMIT" ]]; then
    TOTAL=$LIMIT
fi

echo "[calib] starting: total=$TOTAL rounds=$ROUNDS threshold=$THRESHOLD model=${MODEL:-from-config}"
START_TS=$(date +%s)

I=0
while IFS= read -r line; do
    I=$((I + 1))
    if [[ -n "$LIMIT" && $I -gt $LIMIT ]]; then
        break
    fi

    SEG_ID=$(echo "$line" | python3 -c "import sys,json; print(json.loads(sys.stdin.read())['id'])")
    SEG_TEXT=$(echo "$line" | python3 -c "import sys,json; print(json.loads(sys.stdin.read())['text'])")
    GENRE=$(echo "$line" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('genre','research-report'))")

    # 写临时 markdown 文件喂给 judge runner
    SEG_FILE="$TMP_DIR/$SEG_ID.md"
    printf '%s\n' "$SEG_TEXT" > "$SEG_FILE"

    OUT_FILE="$TMP_DIR/$SEG_ID.judge.json"

    # 单段无需切段（seg-size 设很大），rounds 默认 3
    if ! python3 "$SCRIPTS_DIR/llm-judge-runner.py" \
            --file "$SEG_FILE" \
            --genre "$GENRE" \
            --rounds "$ROUNDS" \
            --seg-size 9999 \
            --overlap 0 \
            --out "$OUT_FILE" 2>/dev/null; then
        echo "  [$I/$TOTAL] $SEG_ID FAILED" >&2
        continue
    fi

    # 提取第一段的 scores（calibration set 段都是单段）+ 维持原 id
    python3 -c "
import json, sys
data = json.load(open('$OUT_FILE'))
seg = data['segments'][0] if data['segments'] else {'scores': {'D1':None,'D2':None,'D3':None,'D4':None,'D5':None}}
out = {
    'id': '$SEG_ID',
    'scores': seg.get('scores', {}),
    'evidence': seg.get('evidence', {}),
    'reasoning_samples': seg.get('reasoning_samples', []),
}
with open('$JUDGE_RESULTS', 'a', encoding='utf-8') as f:
    f.write(json.dumps(out, ensure_ascii=False) + '\n')
print(f'  [$I/$TOTAL] $SEG_ID scores={out[\"scores\"]}', file=sys.stderr)
"
done < "$CALIB_SET"

END_TS=$(date +%s)
ELAPSED=$((END_TS - START_TS))
echo "[calib] judge phase done in ${ELAPSED}s, results: $JUDGE_RESULTS"

# 计算 κ
python3 "$EVALS_DIR/cohen-kappa.py" \
    --gold "$CALIB_SET" \
    --predict "$JUDGE_RESULTS" \
    --out-dir "$RESULTS_DIR"

# 判定 gate
OVERALL_KAPPA=$(python3 -c "import json; d=json.load(open('$RESULTS_DIR/cohen_kappa.json')); print(d.get('overall_weighted_kappa') or 0.0)")
echo ""
echo "================ Calibration Gate ================"
echo "Overall weighted κ = $OVERALL_KAPPA (threshold = $THRESHOLD)"
echo "Per-dim breakdown: see $RESULTS_DIR/cohen_kappa.json"
echo "Disagreements: see $RESULTS_DIR/disagreement.md"
echo "=================================================="

PASS=$(python3 -c "print(1 if float('$OVERALL_KAPPA') >= float('$THRESHOLD') else 0)")
if [[ "$PASS" == "1" ]]; then
    echo "✅ PASS"
    exit 0
else
    echo "⚠️  κ below threshold — analyze disagreement.md before adjusting prompt"
    exit 1
fi
