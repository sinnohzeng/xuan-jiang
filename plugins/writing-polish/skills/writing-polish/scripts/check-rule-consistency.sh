#!/usr/bin/env bash
# check-rule-consistency.sh —— writing-polish v10.1 一致性哨兵
#
# 机械比对 anti-ai-taste-anchors.md §1.1 硬红线词表与 scan-ai-taste.sh CN_HARD
# 正则是否字面一致（提取双方词面、排序、diff）。
#
# 契约来源：references/anti-ai-taste-anchors.md §1.1 一致性契约（v10.1 吸收
# human-writing（MIT）references/revision.md 的文档—脚本一致契约：检查脚本里的
# 硬禁词必须与判据文件完全一致，增删同轮双向修改，不能让脚本偷偷多出一套规则）。
#
# 用法：bash check-rule-consistency.sh
# 退出码：0 = 一致；1 = 词表漂移（打印 diff）；3 = 文件缺失 / 提取失败。
# 兼容：macOS bash 3.2，零新依赖。

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ANCHORS="$SKILL_DIR/references/anti-ai-taste-anchors.md"
SCAN="$SCRIPT_DIR/scan-ai-taste.sh"

[ -f "$ANCHORS" ] || { echo "错误: 缺少 $ANCHORS" >&2; exit 3; }
[ -f "$SCAN" ] || { echo "错误: 缺少 $SCAN" >&2; exit 3; }

# anchors 侧：§1.1 小节内编号清单行，每行取第一个加粗词（如「3. **抓手**（指代抽象时）」→ 抓手）
A_LIST=$(sed -n '/^### §1\.1/,/^### /p' "$ANCHORS" \
    | grep -E '^[0-9]+\.' \
    | sed 's/^[0-9]*\. *//' \
    | sed 's/\*\*\([^*]*\)\*\*.*/\1/')

# 脚本侧：CN_HARD 定义行，按 | 拆词
S_LINE=$(grep -E '^CN_HARD="' "$SCAN" | head -1)
if [ -z "$S_LINE" ]; then
    echo "错误: scan-ai-taste.sh 中未找到 CN_HARD 定义行" >&2
    exit 3
fi
S_LIST=$(echo "$S_LINE" | sed 's/^CN_HARD="//; s/"$//' | tr '|' '\n')

A_SORTED=$(printf '%s\n' "$A_LIST" | sed '/^[[:space:]]*$/d' | LC_ALL=C sort)
S_SORTED=$(printf '%s\n' "$S_LIST" | sed '/^[[:space:]]*$/d' | LC_ALL=C sort)

A_N=$(printf '%s\n' "$A_SORTED" | grep -c . || true)
S_N=$(printf '%s\n' "$S_SORTED" | grep -c . || true)

if [ "${A_N:-0}" -eq 0 ] || [ "${S_N:-0}" -eq 0 ]; then
    echo "错误: 词面提取失败（anchors=$A_N 词, scan=$S_N 词）" >&2
    exit 3
fi

DIFF=$(diff <(printf '%s\n' "$A_SORTED") <(printf '%s\n' "$S_SORTED") || true)

if [ -n "$DIFF" ]; then
    echo "✗ 一致性哨兵 FAIL：anchors §1.1 与 scan 脚本 CN_HARD 词表漂移"
    echo "  （< 为 anchors 独有，> 为脚本独有；增删硬禁词须同一轮双向修改）"
    printf '%s\n' "$DIFF" | sed 's/^/  /'
    exit 1
fi

echo "✓ 一致性哨兵 PASS：anchors §1.1（$A_N 词）与 scan CN_HARD（$S_N 词）逐字一致"
exit 0
