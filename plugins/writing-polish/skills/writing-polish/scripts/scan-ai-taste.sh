#!/usr/bin/env bash
# scan-ai-taste.sh —— writing-polish v4.0 交付前 AI 味自检
#
# L3 Gate：在交付任何修改稿前必跑。任何硬约束未达标，禁止交付。
#
# 用法：
#   bash scan-ai-taste.sh /path/to/file.md
#
# 退出码：
#   0  全部红线达标
#   1  红线违规，需要重写
#   2  软阈值违规，建议重写但非阻断
#   3  使用错误（缺参数 / 文件不存在）

set -uo pipefail

FILE="${1:-}"
if [ -z "$FILE" ]; then
    echo "用法: bash scan-ai-taste.sh <file.md>"
    exit 3
fi
if [ ! -f "$FILE" ]; then
    echo "错误: 文件不存在: $FILE"
    exit 3
fi

# 颜色（终端可识别时启用）
if [ -t 1 ]; then
    RED='\033[0;31m'; YEL='\033[0;33m'; GRN='\033[0;32m'; NC='\033[0m'
else
    RED=''; YEL=''; GRN=''; NC=''
fi

VIOLATIONS=0
WARNINGS=0

# 安全计数函数：grep -c 在无匹配时正确返回 0，避免管道残留
count_pattern() {
    local pattern="$1"
    local file="$2"
    local case_insensitive="${3:-}"
    local result
    if [ "$case_insensitive" = "i" ]; then
        result=$(grep -ciE "$pattern" "$file" 2>/dev/null || true)
    else
        result=$(grep -cE "$pattern" "$file" 2>/dev/null || true)
    fi
    # 清理换行和异常空白
    result=$(echo "$result" | head -1 | tr -d ' \n\r')
    [ -z "$result" ] && result=0
    echo "$result"
}

echo "================================================"
echo "       AI 味红线扫描 v4.0"
echo "       文件：$FILE"
echo "================================================"
echo

# ----------------------------------------------------------
# §1.4 标点红线（必须 = 0）
# ----------------------------------------------------------
echo "▼ §1.4 标点红线（阈值 = 0）"
DASH=$(count_pattern "——|—" "$FILE")
PAREN=$(count_pattern "（如|（即|（也就是说" "$FILE")

if [ "$DASH" -gt 0 ]; then
    printf "  ${RED}✗ 破折号: %d 处${NC} (须 = 0)\n" "$DASH"
    grep -nE '——|—' "$FILE" | head -5 | sed 's/^/    /'
    VIOLATIONS=$((VIOLATIONS + 1))
else
    printf "  ${GRN}✓ 破折号 = 0${NC}\n"
fi

if [ "$PAREN" -gt 0 ]; then
    printf "  ${RED}✗ 括号内补充: %d 处${NC} (须 = 0)\n" "$PAREN"
    grep -nE '（如|（即|（也就是说' "$FILE" | head -5 | sed 's/^/    /'
    VIOLATIONS=$((VIOLATIONS + 1))
else
    printf "  ${GRN}✓ 括号内补充 = 0${NC}\n"
fi
echo

# ----------------------------------------------------------
# §1.3 句式红线（必须 = 0）
# ----------------------------------------------------------
echo "▼ §1.3 句式红线（阈值 = 0）"
NEG_PARALLEL=$(count_pattern "不是.{1,15}而是|不仅.{1,15}更是|不只是.{1,15}而是|与其说.{1,10}不如说" "$FILE")
RUOSHUO=$(count_pattern "如果说.{1,5}那么" "$FILE")

if [ "$NEG_PARALLEL" -gt 0 ]; then
    printf "  ${RED}✗ 否定平行结构: %d 处${NC}\n" "$NEG_PARALLEL"
    grep -nE "不是.{1,15}而是|不仅.{1,15}更是|不只是.{1,15}而是|与其说.{1,10}不如说" "$FILE" | head -3 | sed 's/^/    /'
    VIOLATIONS=$((VIOLATIONS + 1))
else
    printf "  ${GRN}✓ 否定平行结构 = 0${NC}\n"
fi

if [ "$RUOSHUO" -gt 0 ]; then
    printf "  ${RED}✗ 如果说...那么...: %d 处${NC}\n" "$RUOSHUO"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    printf "  ${GRN}✓ 如果说...那么... = 0${NC}\n"
fi
echo

# ----------------------------------------------------------
# §1.1 中文词汇红线（核心 50 条，阈值 = 0）
# ----------------------------------------------------------
echo "▼ §1.1 中文词汇红线（阈值 = 0）"
CN_HARD="赋能|重塑|闭环|抓手|链路|打造|助力|切实推动|深度融合|多维度|体系化|话语建构|跨界融合|提质增效|接住|共情|看见你|令人印象深刻|令人惊叹|不可或缺|至关重要|独树一帜|蓬勃发展|熠熠生辉|经久不衰|在某种意义上说|不可磨灭的|可谓是|值得注意的是|值得一提的是|不难发现|综上所述|由此可见|本质上|更深层次|需要指出的是|必须强调的是|不可否认的是|业内人士指出|相关研究表明|大量实践证明|普遍认为"
CN_RAW=$(grep -oE "$CN_HARD" "$FILE" 2>/dev/null || true)
CN_COUNT=$(echo "$CN_RAW" | grep -c . 2>/dev/null || true)
CN_COUNT=$(echo "$CN_COUNT" | head -1 | tr -d ' \n\r')
[ -z "$CN_COUNT" ] && CN_COUNT=0

if [ "$CN_COUNT" -gt 0 ]; then
    printf "  ${RED}✗ 中文红线词命中: %d 处${NC}\n" "$CN_COUNT"
    grep -nE "$CN_HARD" "$FILE" | head -10 | sed 's/^/    /'
    VIOLATIONS=$((VIOLATIONS + 1))
else
    printf "  ${GRN}✓ 中文红线词命中 = 0${NC}\n"
fi
echo

# ----------------------------------------------------------
# §1.2 英文词汇红线（阈值 = 0）
# ----------------------------------------------------------
echo "▼ §1.2 英文词汇红线（阈值 = 0）"
EN_HARD="\\bdelve\\b|\\btapestry\\b|\\btestament\\b|\\bunderscore\\b|\\bpivotal\\b|\\bintricate\\b|\\bnuanced\\b|\\bvibrant\\b|\\bshowcase\\b|\\bfoster\\b|\\bmultifaceted\\b|\\bmeticulous\\b|\\bseamless\\b|\\bfurthermore\\b|\\bmoreover\\b|in conclusion|it'?s worth noting|\\bin essence\\b|at its core|game-changer|paradigm shift|\\bboasts\\b|\\bbolstered\\b|\\bgarner\\b|embark on|dive deeper"
EN_RAW=$(grep -oiE "$EN_HARD" "$FILE" 2>/dev/null || true)
EN_COUNT=$(echo "$EN_RAW" | grep -c . 2>/dev/null || true)
EN_COUNT=$(echo "$EN_COUNT" | head -1 | tr -d ' \n\r')
[ -z "$EN_COUNT" ] && EN_COUNT=0

if [ "$EN_COUNT" -gt 0 ]; then
    printf "  ${RED}✗ 英文红线词命中: %d 处${NC}\n" "$EN_COUNT"
    grep -niE "$EN_HARD" "$FILE" | head -10 | sed 's/^/    /'
    VIOLATIONS=$((VIOLATIONS + 1))
else
    printf "  ${GRN}✓ 英文红线词命中 = 0${NC}\n"
fi
echo

# ----------------------------------------------------------
# §1.1 三段式套壳（阈值 = 0）
# ----------------------------------------------------------
echo "▼ §1.1 三段式套壳（阈值 = 0）"
SANDUAN=$(count_pattern "首先.{0,30}其次.{0,30}最后" "$FILE")
if [ "$SANDUAN" -gt 0 ]; then
    printf "  ${RED}✗ 首先...其次...最后: %d 处${NC}\n" "$SANDUAN"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    printf "  ${GRN}✓ 首先...其次...最后 = 0${NC}\n"
fi
echo

# ----------------------------------------------------------
# §4 软阈值（密度限制）
# ----------------------------------------------------------
echo "▼ §4 软阈值（密度限制）"
YIJING=$(count_pattern "已经" "$FILE")
HEXIN=$(count_pattern "核心" "$FILE")
ZHEYI=$(count_pattern "这一" "$FILE")

check_density() {
    local label="$1"
    local count="$2"
    local thresh="$3"
    if [ "$count" -gt "$thresh" ]; then
        printf "  ${YEL}⚠ %s: %d / 阈值 ≤ %d${NC}\n" "$label" "$count" "$thresh"
        WARNINGS=$((WARNINGS + 1))
    else
        printf "  ${GRN}✓ %s: %d / 阈值 ≤ %d${NC}\n" "$label" "$count" "$thresh"
    fi
}

check_density "已经" "$YIJING" 3
check_density "核心" "$HEXIN" 3
check_density "这一" "$ZHEYI" 2
echo

# ----------------------------------------------------------
# §3 结构反模式（启发式）
# ----------------------------------------------------------
echo "▼ §3 结构反模式（启发式提示）"
JIEWEI=$(count_pattern "体现了|反映了|彰显了" "$FILE")
TIAOZHAN=$(count_pattern "尽管面临.{0,20}挑战" "$FILE")

if [ "$JIEWEI" -gt 2 ]; then
    printf "  ${YEL}⚠ 段尾分词挂总结（体现了/反映了/彰显了）: %d 处 / 阈值 ≤ 2${NC}\n" "$JIEWEI"
    WARNINGS=$((WARNINGS + 1))
else
    printf "  ${GRN}✓ 段尾分词挂总结: %d 处${NC}\n" "$JIEWEI"
fi

if [ "$TIAOZHAN" -gt 0 ]; then
    printf "  ${YEL}⚠ 挑战与展望套壳: %d 处${NC}\n" "$TIAOZHAN"
    WARNINGS=$((WARNINGS + 1))
else
    printf "  ${GRN}✓ 挑战与展望套壳 = 0${NC}\n"
fi
echo

# ----------------------------------------------------------
# 句长方差（人写有长短）
# ----------------------------------------------------------
echo "▼ 句长方差（阈值 ≥ 8）"
PYRESULT=0
python3 - "$FILE" << 'PYEOF' || PYRESULT=$?
import re, statistics, sys
f = sys.argv[1]
try:
    text = open(f).read()
    sents = [len(s) for s in re.split('[。！？；]', text) if 5 < len(s) < 200]
    if len(sents) > 5:
        stdev = statistics.stdev(sents)
        mean = statistics.mean(sents)
        if stdev < 8:
            print(f'  ⚠ 句长标准差: {stdev:.1f} (阈值 ≥ 8) - 句长过于均匀，AI 味嫌疑')
            sys.exit(2)
        else:
            print(f'  ✓ 句长标准差: {stdev:.1f} / 平均 {mean:.0f} 字 / 句子数 {len(sents)}')
    else:
        print(f'  ⚠ 文本过短（{len(sents)} 句），跳过句长分析')
except Exception as e:
    print(f'  ⚠ 句长分析失败: {e}')
PYEOF

[ "$PYRESULT" -eq 2 ] && WARNINGS=$((WARNINGS + 1))
echo

# ----------------------------------------------------------
# 总结
# ----------------------------------------------------------
echo "================================================"
if [ "$VIOLATIONS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    printf "${GRN}✅ PASS — 全部红线和软阈值通过，可以交付${NC}\n"
    exit 0
elif [ "$VIOLATIONS" -eq 0 ]; then
    printf "${YEL}⚠ WARN — 红线全过，但有 %d 项软阈值警告${NC}\n" "$WARNINGS"
    echo "建议：根据上述软阈值警告进一步润色后交付"
    exit 2
else
    printf "${RED}✗ FAIL — 有 %d 项硬红线违规，禁止交付${NC}\n" "$VIOLATIONS"
    echo
    echo "下一步：重写违规处，再次运行本脚本，直至全部通过"
    exit 1
fi
