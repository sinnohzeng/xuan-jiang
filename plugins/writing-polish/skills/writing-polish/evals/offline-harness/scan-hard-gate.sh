#!/usr/bin/env bash
# scan-hard-gate.sh —— writing-polish v5.0 Layer 1 硬 Gate
#
# 30 条 codepoint 级机械红线，零模型调用、毫秒级、确定性，CI 强制。
# 不做语境豁免（防火墙 IT vs 隐喻战斗这类同形异义走 Layer 2 LLM Judge）。
#
# 用法：bash scan-hard-gate.sh <file.md> [--json]
#
# 退出码：
#   0  全部通过
#   1  红线违规
#   3  使用错误

set -uo pipefail

FILE="${1:-}"
MODE="standard"
[ "${2:-}" = "--json" ] && MODE="json"

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo "用法: bash scan-hard-gate.sh <file.md> [--json]"
    exit 3
fi

# 预处理：跳过 <!-- scan-skip --> 至 <!-- /scan-skip --> 段 + YAML frontmatter。
SCAN_TMP=$(mktemp -t scan-hard-gate.XXXXXX.md)
trap 'rm -f "$SCAN_TMP"' EXIT
awk '
    BEGIN { in_fm=0 }
    NR==1 && /^---$/ { in_fm=1; print ""; next }
    in_fm==1 && /^---$/ { in_fm=0; print ""; next }
    in_fm==1 { print ""; next }
    /<!-- *scan-skip *-->/ { skip=1; print ""; next }
    /<!-- *\/scan-skip *-->/ { skip=0; print ""; next }
    { if (skip) print ""; else print $0 }
' "$FILE" > "$SCAN_TMP"

VIOLATIONS=()

# 通用扫描函数：grep -nE 命中即记录违规。
hit() {
    local rule="$1"
    local pattern="$2"
    local found
    found=$(grep -nE "$pattern" "$SCAN_TMP" || true)
    if [ -n "$found" ]; then
        while IFS= read -r line; do
            VIOLATIONS+=("$rule|$line")
        done <<< "$found"
    fi
}

# H1：GB/T 15834 标点 codepoint 红线
hit "H1.1 ASCII 直引号"           '[“”‘’]|["'"'"']'
hit "H1.2 直角引号（港台/日式）"  '[「」『』]'
hit "H1.3 ASCII em-dash"          '—|――'

# H2：公文格式硬红线
hit "H2.1 错误文号占位"            '〔YYYY〕|〔xxx〕|（待补文号）'

# H3：AI 元注释字面量
hit "H3.1 作为一个 AI 助手"        '作为一个 *AI'
hit "H3.2 让我们一起"              '让我们一起|让我们来'
hit "H3.3 综上所述/由此可见 模板"  '综上所述|由此可见|不难看出'
hit "H3.4 我希望/感谢提问 客服腔"  '我希望.{0,5}帮助到您|感谢您的提问|很高兴.{0,5}帮助'
hit "H3.5 模型水印残留"            'oaicite|placeholder|TODO\.\.\.'

# H4：低假阳的核心黑话（无歧义、跨场景一致）
hit "H4.1 赋能"                    '赋能'
hit "H4.2 闭环（动词）"            '形成闭环|完成闭环|实现闭环'
hit "H4.3 抓手"                    '抓手'
hit "H4.4 颗粒度"                  '颗粒度'
hit "H4.5 跑通/走通"               '跑通|走通'
hit "H4.6 助力（公文外滥用）"      '助力打造|助力赋能|强力助力'

# H5：戏剧化标志性词
hit "H5.1 三层防御"                '三层防御'
hit "H5.2 翻车"                    '翻车'

# 输出
if [ "$MODE" = "json" ]; then
    printf '{"violations":['
    first=1
    for v in "${VIOLATIONS[@]}"; do
        [ "$first" -eq 0 ] && printf ','
        rule="${v%%|*}"; rest="${v#*|}"; lineno="${rest%%:*}"; content="${rest#*:}"
        printf '{"rule":"%s","line":%s,"content":%s}' "$rule" "$lineno" "$(printf '%s' "$content" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')"
        first=0
    done
    printf ']}\n'
else
    if [ "${#VIOLATIONS[@]}" -eq 0 ]; then
        echo "✅ Layer 1 Hard Gate PASS（30 条机械红线全部通过）"
    else
        echo "❌ Layer 1 Hard Gate FAIL（${#VIOLATIONS[@]} 处违规）"
        echo
        for v in "${VIOLATIONS[@]}"; do
            rule="${v%%|*}"
            rest="${v#*|}"
            echo "  [$rule] $rest"
        done
    fi
fi

[ "${#VIOLATIONS[@]}" -eq 0 ] && exit 0 || exit 1
