#!/usr/bin/env bash
# scan-ai-taste.sh —— writing-polish v7.0 L1 hard gate
#
# 角色：交付前 AI 味自检（L1 硬扫）+ JSON 输出供主对话 / writing-reviewer 路由决策。
# 在交付任何修改稿前必跑。任何硬约束未达标，禁止交付。
#
# 用法：
#   bash scan-ai-taste.sh <file.md>                                # 标准扫描（人类可读）
#   bash scan-ai-taste.sh --target <file.md>                       # 同上（显式 flag）
#   bash scan-ai-taste.sh --target <file.md> --suggest-fix         # 含改写建议
#   bash scan-ai-taste.sh --target <file.md> --json                # JSON 输出（主对话消费）
#   bash scan-ai-taste.sh --target <file.md> --log-to <jsonl-path> # opt-in 离线 eval 日志（供 evals/offline-harness/ 消费）
#   bash scan-ai-taste.sh --target <file.md> --json --log-to <p>   # 二者可叠加
#
# 退出码：
#   0  全部红线达标
#   1  红线违规，需要重写
#   2  软阈值违规，建议重写但非阻断
#   3  使用错误（缺参数 / 文件不存在）
#
# JSON 契约：schemas/scan-output.schema.json
# 日志契约：evals/offline-harness/eval-record.schema.json（离线 dev-eval）
# 规则定义：references/anti-ai-taste-anchors.md（230+ 条 SSOT，编号一一对应）

set -uo pipefail

FILE=""
MODE="standard"
LOG_TO=""
# legacy positional arg support
if [ "${1:-}" != "" ] && [ "${1:0:2}" != "--" ]; then
    FILE="$1"
    shift
fi
while [ $# -gt 0 ]; do
    case "$1" in
        --suggest-fix) MODE="suggest"; shift ;;
        --json) MODE="json"; shift ;;
        --target) FILE="${2:-}"; shift 2 ;;
        --log-to) LOG_TO="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done

if [ -z "$FILE" ]; then
    echo "用法: bash scan-ai-taste.sh <file.md|--target file.md> [--suggest-fix|--json|--log-to <jsonl-path>]" >&2
    exit 3
fi
if [ ! -f "$FILE" ]; then
    echo "错误: 文件不存在: $FILE" >&2
    exit 3
fi

# capture stdout into a buffer when JSON mode or --log-to is set.
# emit_results_on_exit (trap EXIT) parses the buffer and emits JSON / appends log line.
if [ "$MODE" = "json" ] || [ -n "$LOG_TO" ]; then
    JSON_BUF=$(mktemp)
    exec 3>&1
    exec 1>"$JSON_BUF"
fi

emit_results_on_exit() {
    local ec=$?
    # always clean up preprocessing temp file (originally guarded by a later inline trap)
    [ -n "${SCAN_TMP:-}" ] && rm -f "$SCAN_TMP"
    [ -z "${JSON_BUF:-}" ] && return
    [ ! -f "${JSON_BUF}" ] && return
    exec 1>&3 || true
    python3 - "$JSON_BUF" "$ORIG_FILE" "$ec" "$MODE" "$LOG_TO" <<'PYEOF'
import sys, re, json, hashlib, os
from datetime import datetime, timezone

buf_path, file_path, exit_code, mode, log_to = (
    sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4], sys.argv[5]
)
try:
    output = open(buf_path, 'r', encoding='utf-8').read()
except Exception:
    output = ""
ansi = re.compile(r'\x1b\[[0-9;]*m')
output_plain = ansi.sub('', output)
red_total = len(re.findall(r'^\s+✗', output_plain, re.MULTILINE))
soft_total = len(re.findall(r'^\s+⚠', output_plain, re.MULTILINE))

cats = []
current = None
for line in output_plain.splitlines():
    cat_m = re.match(r'^▼\s+(.+?)$', line)
    if cat_m:
        current = {'name': cat_m.group(1).strip(), 'red': 0, 'soft': 0}
        cats.append(current)
    elif current is not None:
        if re.match(r'^\s+✗', line):
            current['red'] += 1
        elif re.match(r'^\s+⚠', line):
            current['soft'] += 1
cats = [c for c in cats if c['red'] > 0 or c['soft'] > 0]

try:
    text = open(file_path, 'r', encoding='utf-8').read()
except Exception:
    text = ""
char_count = len(text)
sentence_count = len(re.findall(r'[。！？；]', text))
paragraph_count = len([p for p in text.split('\n\n') if p.strip()])
draft_hash = hashlib.sha256(text.encode('utf-8')).hexdigest()[:16]

if mode == 'json':
    result = {
        "version": "7.0",
        "file": os.path.abspath(file_path),
        "draft_hash": draft_hash,
        "exit_code": exit_code,
        "summary": {
            "red_line_violations_total": red_total,
            "soft_warnings_total": soft_total,
            "categories": cats,
        },
        "stats": {
            "char_count": char_count,
            "sentence_count": sentence_count,
            "paragraph_count": paragraph_count,
        },
        "human_readable_output": output_plain,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))

if log_to:
    log_dir = os.path.dirname(os.path.abspath(log_to))
    if log_dir:
        os.makedirs(log_dir, exist_ok=True)
    final_action = "passed" if exit_code == 0 else ("fixed" if exit_code == 2 else "rolled_back")
    log_entry = {
        "version": "7.0",
        "timestamp": datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
        "draft_hash": draft_hash,
        "protocol": "v7.0",
        "mode": "audit",
        "scan_summary": {
            "red_line_violations_total": red_total,
            "soft_warnings_total": soft_total,
            "categories": cats,
        },
        "final_action": final_action,
    }
    with open(log_to, 'a', encoding='utf-8') as f:
        f.write(json.dumps(log_entry, ensure_ascii=False) + '\n')

try:
    os.unlink(buf_path)
except Exception:
    pass
PYEOF
}
trap emit_results_on_exit EXIT

# 预处理：豁免 <!-- scan-skip --> 至 <!-- /scan-skip --> 之间的段落
# 元论述（规则定义、错误对照、引用违规词举例）专用
# 同时跳过 YAML frontmatter（开头 --- 至下一个 ---），因为 YAML 段
# 内不能用 HTML 注释，且 SKILL.md frontmatter description 必然
# 列举触发词作为元论述。
ORIG_FILE="$FILE"
SCAN_TMP=$(mktemp -t scan-ai-taste.XXXXXX.md)
# SCAN_TMP cleanup is handled by emit_results_on_exit (trap EXIT set earlier)
awk '
    BEGIN { in_fm=0; fm_done=0 }
    NR==1 && /^---$/ { in_fm=1; print ""; next }
    in_fm==1 && /^---$/ { in_fm=0; fm_done=1; print ""; next }
    in_fm==1 { print ""; next }
    /<!-- *scan-skip *-->/ { skip=1; print ""; next }
    /<!-- *\/scan-skip *-->/ { skip=0; print ""; next }
    { if (skip) print ""; else print $0 }
' "$ORIG_FILE" > "$SCAN_TMP"
FILE="$SCAN_TMP"

# 颜色（终端可识别时启用）
if [ -t 1 ]; then
    RED='\033[0;31m'; YEL='\033[0;33m'; GRN='\033[0;32m'; NC='\033[0m'
else
    RED=''; YEL=''; GRN=''; NC=''
fi

VIOLATIONS=0
WARNINGS=0
# 分组密度统计：用普通变量避免 macOS bash 3.2 不支持 declare -A
SC_s11=0; SC_s12=0; SC_s13=0; SC_s14=0; SC_s15=0; SC_s16=0; SC_s17=0

# 分组累加器
inc_section() {
    local sec="$1"
    local n="$2"
    case "$sec" in
        s11) SC_s11=$((SC_s11 + n)) ;;
        s12) SC_s12=$((SC_s12 + n)) ;;
        s13) SC_s13=$((SC_s13 + n)) ;;
        s14) SC_s14=$((SC_s14 + n)) ;;
        s15) SC_s15=$((SC_s15 + n)) ;;
        s16) SC_s16=$((SC_s16 + n)) ;;
        s17) SC_s17=$((SC_s17 + n)) ;;
    esac
}

# 安全计数函数：grep -c 在无匹配时正确返回 0
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
    result=$(echo "$result" | head -1 | tr -d ' \n\r')
    [ -z "$result" ] && result=0
    echo "$result"
}

# v4.3 上下文感知白名单：词命中后看 ±2 行窗口是否含白名单关键词，含则豁免
# 用法：count_with_context_whitelist <WORD_REGEX> <WHITELIST_REGEX> <FILE>
# 返回：被判违规的命中数（总命中 - 落在白名单上下文的命中）
count_with_context_whitelist() {
    local word="$1"
    local whitelist="$2"
    local file="$3"
    local total whitelisted=0
    total=$(count_pattern "$word" "$file")
    [ "$total" -eq 0 ] && { echo 0; return; }
    while IFS=: read -r ln _; do
        [ -z "$ln" ] && continue
        local start=$((ln > 2 ? ln - 2 : 1))
        local end=$((ln + 2))
        if sed -n "${start},${end}p" "$file" 2>/dev/null | grep -qE "$whitelist"; then
            whitelisted=$((whitelisted + 1))
        fi
    done < <(grep -nE "$word" "$file" 2>/dev/null)
    echo $((total - whitelisted))
}

# v4.3 句子数计算（与句长方差段口径一致）
sentence_count() {
    local file="$1"
    python3 -c "
import re, sys
try:
    text = open('$file').read()
    sents = [s for s in re.split('[。！？；]', text) if 5 < len(s) < 200]
    print(len(sents))
except Exception:
    print(0)
" 2>/dev/null || echo 0
}

# v4.3 软阈值动态化：按千句密度 ≤ base 计算阈值
# 短文（< 200 句）= base；中文（200-500）= base*2；长文（500-1000）= base*3；超长（≥1000）= base*5
threshold_for_length() {
    local base="$1"
    local sents="$2"
    if   [ "$sents" -lt 200 ];  then echo "$base"
    elif [ "$sents" -lt 500 ];  then echo $((base * 2))
    elif [ "$sents" -lt 1000 ]; then echo $((base * 3))
    else echo $((base * 5))
    fi
}

# 改写建议表（仅在 --suggest-fix 模式下输出）
suggest_for() {
    case "$1" in
        dash) echo "    改写：删除破折号，把句子拆成两句或用逗号 / 句号";;
        paren) echo "    改写：把括号内补充独立成句，或用顿号融入正文";;
        ascii_quote) echo "    改写：替换为大陆国标弯引号 \"\" '' （U+201C / U+201D / U+2018 / U+2019）";;
        corner_quote) echo "    改写：替换为大陆国标弯引号 \"\" '' ，「」是港台或日式";;
        math_symbol) echo "    改写：重构整段表述。例：'A + B + C' → 'A、B 和 C 三大要素'，不要机械替换为'和'";;
        neg_parallel) echo "    改写：把'不是 X 而是 Y'改成直接陈述 Y，或承认观点是判断";;
        cn_hard) echo "    改写：详见 anti-ai-taste-anchors.md §1.1，改成具体动词或事实陈述";;
        en_hard) echo "    改写：详见 anti-ai-taste-anchors.md §1.2，删修饰留事实";;
        sanduan) echo "    改写：'首先 / 其次 / 最后'改成'一是 / 二是 / 三是'党政公文体例";;
        drama) echo "    改写：详见 anti-ai-taste-anchors.md §1.5.1，去战斗化叙事";
               echo "         如确为 IT 实物语境（机房 / 等保 / WAF / 入侵检测 / NGFW），±2 行内含 IT 关键词即可豁免";;
        jargon) echo "    改写：详见 anti-ai-taste-anchors.md §1.5.2，去大厂黑话";
                echo "         如确为党政咨询语境（同级对标 / 对标先进 / 对标启示），±2 行内含公文关键词即可豁免";;
        netspeak) echo "    改写：详见 anti-ai-taste-anchors.md §1.5.3，去网络口语";;
        meta) echo "    改写：删除元注释 / 自我介绍 / 免责声明 / 服务话术，直接进入正文";;
        wp_long) echo "    改写：详见 anti-ai-taste-anchors.md §1.7，清理 AI 工具输出残留";;
    esac
}

echo "================================================"
echo "       AI 味红线扫描 v4.3"
echo "       文件：$FILE"
[ "$MODE" = "suggest" ] && echo "       模式：建议改写"
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
    [ "$MODE" = "suggest" ] && suggest_for dash
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s14" "$DASH"
else
    printf "  ${GRN}✓ 破折号 = 0${NC}\n"
fi

if [ "$PAREN" -gt 0 ]; then
    printf "  ${RED}✗ 括号内补充: %d 处${NC} (须 = 0)\n" "$PAREN"
    grep -nE '（如|（即|（也就是说' "$FILE" | head -5 | sed 's/^/    /'
    [ "$MODE" = "suggest" ] && suggest_for paren
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s14" "$PAREN"
else
    printf "  ${GRN}✓ 括号内补充 = 0${NC}\n"
fi

# §1.4.111-113 中文标点与中英混排（外置 python 检测器，分项报告）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
QUOTE_OUTPUT=$(python3 "$SCRIPT_DIR/check-cn-quotes.py" "$FILE" 2>/dev/null || true)
QUOTE_TOTAL=$(echo "$QUOTE_OUTPUT" | grep -oE 'TOTAL=[0-9]+' | head -1 | sed 's/TOTAL=//')
[ -z "$QUOTE_TOTAL" ] && QUOTE_TOTAL=0

while IFS= read -r line; do
    if [[ "$line" == RULE=* ]]; then
        rule_name=$(echo "$line" | sed 's/RULE=//' | sed 's/|COUNT=.*//')
        rule_count=$(echo "$line" | grep -oE 'COUNT=[0-9]+' | sed 's/COUNT=//')
        if [ "$rule_count" -gt 0 ]; then
            printf "  ${RED}✗ %s: %d${NC}\n" "$rule_name" "$rule_count"
            VIOLATIONS=$((VIOLATIONS + 1))
            inc_section "s14" "$rule_count"
        else
            printf "  ${GRN}✓ %s = 0${NC}\n" "$rule_name"
        fi
    elif [[ "$line" == "  "* ]] && [ "$rule_count" -gt 0 ]; then
        echo "$line"
    fi
done <<< "$QUOTE_OUTPUT"

# §1.4.114 每段加粗冒号开头（v4.2 新增）
BOLDCOLON=$(count_pattern '\*\*[^*]{1,8}：\*\*|\*\*重点\*\*|\*\*关键\*\*|\*\*注意\*\*|\*\*核心要点\*\*' "$FILE")
if [ "$BOLDCOLON" -gt 0 ]; then
    printf "  ${RED}✗ §1.4.114 每段加粗冒号开头: %d 处${NC}\n" "$BOLDCOLON"
    grep -nE '\*\*[^*]{1,8}：\*\*' "$FILE" | head -3 | sed 's/^/    /'
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s14" "$BOLDCOLON"
else
    printf "  ${GRN}✓ §1.4.114 每段加粗冒号开头 = 0${NC}\n"
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
    [ "$MODE" = "suggest" ] && suggest_for neg_parallel
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s13" "$NEG_PARALLEL"
else
    printf "  ${GRN}✓ 否定平行结构 = 0${NC}\n"
fi

if [ "$RUOSHUO" -gt 0 ]; then
    printf "  ${RED}✗ 如果说...那么...: %d 处${NC}\n" "$RUOSHUO"
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s13" "$RUOSHUO"
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
    [ "$MODE" = "suggest" ] && suggest_for cn_hard
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s11" "$CN_COUNT"
else
    printf "  ${GRN}✓ 中文红线词命中 = 0${NC}\n"
fi
echo

# ----------------------------------------------------------
# §1.2 英文词汇红线（v4.2 扩到 50 条）
# ----------------------------------------------------------
echo "▼ §1.2 英文词汇红线（阈值 = 0）"
EN_HARD="\\bdelve\\b|\\btapestry\\b|\\btestament\\b|\\bunderscore\\b|\\bpivotal\\b|\\bintricate\\b|\\bnuanced\\b|\\bvibrant\\b|\\bshowcase\\b|\\bfoster\\b|\\bmultifaceted\\b|\\bmeticulous\\b|\\bseamless\\b|\\bfurthermore\\b|\\bmoreover\\b|in conclusion|it'?s worth noting|\\bin essence\\b|at its core|game-changer|paradigm shift|\\bboasts\\b|\\bbolstered\\b|\\bgarner\\b|embark on|dive deeper|\\binterplay\\b|\\bconcrete\\b evidence|\\btangible\\b|\\bleverage\\b|\\bstreamline\\b|cutting-edge|state-of-the-art|groundbreaking|transformative|\\bharness\\b|\\bcatalyze\\b|usher in"
EN_RAW=$(grep -oiE "$EN_HARD" "$FILE" 2>/dev/null || true)
EN_COUNT=$(echo "$EN_RAW" | grep -c . 2>/dev/null || true)
EN_COUNT=$(echo "$EN_COUNT" | head -1 | tr -d ' \n\r')
[ -z "$EN_COUNT" ] && EN_COUNT=0

if [ "$EN_COUNT" -gt 0 ]; then
    printf "  ${RED}✗ 英文红线词命中: %d 处${NC}\n" "$EN_COUNT"
    grep -niE "$EN_HARD" "$FILE" | head -10 | sed 's/^/    /'
    [ "$MODE" = "suggest" ] && suggest_for en_hard
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s12" "$EN_COUNT"
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
    [ "$MODE" = "suggest" ] && suggest_for sanduan
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s11" "$SANDUAN"
else
    printf "  ${GRN}✓ 首先...其次...最后 = 0${NC}\n"
fi
echo

# ----------------------------------------------------------
# §4 软阈值（密度限制，v4.3 按文长动态化）
# ----------------------------------------------------------
SENT_COUNT=$(sentence_count "$FILE")
HEXIN_THRESH=$(threshold_for_length 3 "$SENT_COUNT")
YIJING_THRESH=$(threshold_for_length 3 "$SENT_COUNT")
ZHEYI_THRESH=$(threshold_for_length 2 "$SENT_COUNT")

echo "▼ §4 软阈值（密度限制，文长 ${SENT_COUNT} 句 → 千句密度阈值动态计算）"
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

check_density "已经" "$YIJING" "$YIJING_THRESH"
check_density "核心" "$HEXIN" "$HEXIN_THRESH"
check_density "这一" "$ZHEYI" "$ZHEYI_THRESH"
echo

# ----------------------------------------------------------
# §1.5 戏剧化偏好 / 互联网大厂黑话 / 网络口语
# ----------------------------------------------------------
echo "▼ §1.5 戏剧化 / 大厂黑话 / 网络口语（阈值 = 0）"

# §1.5.1 战斗化 / 戏剧化叙事（v4.3 防火墙拆出走 IT 上下文白名单）
DRAMA_GENERIC="三件武器|三大武器|杀手锏|撒手锏|三层防御|多重防御|立体防御|闸门|自动闸门|兜底闸门|战场|主战场|阵地|武器化|装备化|装上一套|加装一套|跑通|走通|起飞|吐文字|吐结果|喷出|蹦出|王炸|大招|终极武器|杀招|打怪升级|通关"
# IT 实物语境白名单：等保 / 网络架构 / 设备类别 / 部署语句
DRAMA_IT_WHITELIST="机房|等保|GB/T 22239|服务器|端口|协议|入侵检测|网络架构|网络分区|网络边界|访问控制|安全组|子网|VPC|VPN|路由|交换机|WAF|Web 应用|UTM|IDS|IPS|NGFW|部署.{0,5}台|配置规则|防护设备|安全设备|网络安全|数据中心|云服务|裸金属"
FW_DRAMA=$(count_with_context_whitelist "防火墙" "$DRAMA_IT_WHITELIST" "$FILE")
DRAMA_COUNT=$(count_pattern "$DRAMA_GENERIC" "$FILE")
DRAMA_COUNT=$((DRAMA_COUNT + FW_DRAMA))
DRAMA="$DRAMA_GENERIC|防火墙"  # 仅用于 grep -nE 行号展示
if [ "$DRAMA_COUNT" -gt 0 ]; then
    printf "  ${RED}✗ §1.5.1 战斗化叙事: %d 处${NC}\n" "$DRAMA_COUNT"
    grep -nE "$DRAMA" "$FILE" | head -3 | sed 's/^/    /'
    [ "$MODE" = "suggest" ] && suggest_for drama
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s15" "$DRAMA_COUNT"
else
    printf "  ${GRN}✓ §1.5.1 战斗化叙事 = 0${NC}\n"
fi

# §1.5.2 互联网大厂黑话扩展（v4.3 对标拆出走党政 / 咨询语境白名单）
JARGON_GENERIC="拉通|颗粒度|打法|玩法|沉淀下来|抢占心智|占领心智|用户心智|生态化反|赛道|切赛道|抢赛道|抓总|跑出来|跑通模型|下沉市场|底层逻辑|顶层设计|价值锚点|赛马机制|内部赛马|跑赢大盘|跑赢市场|三件套|组合拳|铁三角|冲业绩"
# 党政公文 / 咨询语境白名单：政府工作报告 / 党的二十大 / 同级 / 国际先进等
JARGON_GOV_WHITELIST="政府工作报告|党中央|党的二十大|二十届|总书记|讲话精神|对标对表|对标先进|对标一流|对标国际|对标国内|同级|同业|国际先进|行业领先|启示|案例|经验|做法|建设方案|实施方案|发展规划|高质量发展|党建|政治学习|十四五|十五五"
DB_JARGON=$(count_with_context_whitelist "对标" "$JARGON_GOV_WHITELIST" "$FILE")
JARGON_COUNT=$(count_pattern "$JARGON_GENERIC" "$FILE")
JARGON_COUNT=$((JARGON_COUNT + DB_JARGON))
JARGON="$JARGON_GENERIC|对标"  # 仅用于 grep -nE 行号展示
if [ "$JARGON_COUNT" -gt 0 ]; then
    printf "  ${RED}✗ §1.5.2 互联网大厂黑话: %d 处${NC}\n" "$JARGON_COUNT"
    grep -nE "$JARGON" "$FILE" | head -3 | sed 's/^/    /'
    [ "$MODE" = "suggest" ] && suggest_for jargon
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s15" "$JARGON_COUNT"
else
    printf "  ${GRN}✓ §1.5.2 互联网大厂黑话 = 0${NC}\n"
fi

# §1.5.3 网络口语 / 网感词
NETSPEAK="本仓库|本号|本站|锚点|硬约束|硬规则|硬指标|dogfooding|吃自己狗粮|降智|智商税|裂开|蚌埠住了|绷不住了|绝绝子|YYDS|永远滴神|拉胯|干货|满满的干货|种草|拔草|梭哈|押注|翻车|踩坑"
NETSPEAK_COUNT=$(count_pattern "$NETSPEAK" "$FILE")
if [ "$NETSPEAK_COUNT" -gt 0 ]; then
    printf "  ${RED}✗ §1.5.3 网络口语 / 网感词: %d 处${NC}\n" "$NETSPEAK_COUNT"
    grep -nE "$NETSPEAK" "$FILE" | head -3 | sed 's/^/    /'
    [ "$MODE" = "suggest" ] && suggest_for netspeak
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s15" "$NETSPEAK_COUNT"
else
    printf "  ${GRN}✓ §1.5.3 网络口语 / 网感词 = 0${NC}\n"
fi

# §1.5.4 程序员 / 产品经理腔（在非技术架构语境的滥用）
PMS="MVP|PMF|冷启动|热启动|解耦|高内聚|新范式"
PMS_COUNT=$(count_pattern "$PMS" "$FILE")
if [ "$PMS_COUNT" -gt 0 ]; then
    printf "  ${YEL}⚠ §1.5.4 程序员 / 产品经理腔: %d 处${NC} (技术语境合法)\n" "$PMS_COUNT"
    WARNINGS=$((WARNINGS + 1))
    inc_section "s15" "$PMS_COUNT"
else
    printf "  ${GRN}✓ §1.5.4 程序员 / 产品经理腔 = 0${NC}\n"
fi
echo

# ----------------------------------------------------------
# §1.6 元注释 / 客服话术（v4.2 新增）
# ----------------------------------------------------------
echo "▼ §1.6 元注释 / 客服话术（阈值 = 0）"

META_OPEN="以下是几点说明|以下是几点想法|我将从.{1,3}个方面|我将围绕|让我为您整理|让我帮您梳理|让我先来分析|请允许我|请容我先|接下来我会|我接下来要"
META_OPEN_COUNT=$(count_pattern "$META_OPEN" "$FILE")
if [ "$META_OPEN_COUNT" -gt 0 ]; then
    printf "  ${RED}✗ §1.6.1 元注释开头: %d 处${NC}\n" "$META_OPEN_COUNT"
    grep -nE "$META_OPEN" "$FILE" | head -3 | sed 's/^/    /'
    [ "$MODE" = "suggest" ] && suggest_for meta
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s16" "$META_OPEN_COUNT"
else
    printf "  ${GRN}✓ §1.6.1 元注释开头 = 0${NC}\n"
fi

SELF_INTRO="作为一个 AI 助手|作为一个 AI 模型|作为一个语言模型|作为大语言模型|作为对话式 AI|我虽然是 AI|我作为 AI 的局限性|我的知识截止日期"
SELF_INTRO_COUNT=$(count_pattern "$SELF_INTRO" "$FILE")
if [ "$SELF_INTRO_COUNT" -gt 0 ]; then
    printf "  ${RED}✗ §1.6.2 自我介绍 / 身份声明: %d 处${NC}\n" "$SELF_INTRO_COUNT"
    grep -nE "$SELF_INTRO" "$FILE" | head -3 | sed 's/^/    /'
    [ "$MODE" = "suggest" ] && suggest_for meta
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s16" "$SELF_INTRO_COUNT"
else
    printf "  ${GRN}✓ §1.6.2 自我介绍 = 0${NC}\n"
fi

DISCLAIMER="以上信息仅供参考|仅供参考请以官方为准|建议咨询专业人士|建议咨询医生|建议咨询律师|我无法替代专业建议|以上内容如有错误请指正|如有不当之处请见谅"
DISCLAIMER_COUNT=$(count_pattern "$DISCLAIMER" "$FILE")
if [ "$DISCLAIMER_COUNT" -gt 0 ]; then
    printf "  ${RED}✗ §1.6.3 免责声明: %d 处${NC}\n" "$DISCLAIMER_COUNT"
    grep -nE "$DISCLAIMER" "$FILE" | head -3 | sed 's/^/    /'
    [ "$MODE" = "suggest" ] && suggest_for meta
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s16" "$DISCLAIMER_COUNT"
else
    printf "  ${GRN}✓ §1.6.3 免责声明 = 0${NC}\n"
fi

SERVICE_TAIL="希望对您有帮助|希望这能帮到您|希望这些内容对您有用|如有其他问题.{0,5}欢迎继续提问|还有什么问题尽管问|有任何疑问请随时告诉我|有不清楚的地方请告诉我|谢谢您的提问|谢谢您的信任|感谢您的耐心"
SERVICE_TAIL_COUNT=$(count_pattern "$SERVICE_TAIL" "$FILE")
if [ "$SERVICE_TAIL_COUNT" -gt 0 ]; then
    printf "  ${RED}✗ §1.6.4 服务话术段尾: %d 处${NC}\n" "$SERVICE_TAIL_COUNT"
    grep -nE "$SERVICE_TAIL" "$FILE" | head -3 | sed 's/^/    /'
    [ "$MODE" = "suggest" ] && suggest_for meta
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s16" "$SERVICE_TAIL_COUNT"
else
    printf "  ${GRN}✓ §1.6.4 服务话术段尾 = 0${NC}\n"
fi

# §1.6.5 拟人化集体代词（高密度才报警）
WERON=$(count_pattern "我们都知道|我们大家|让我们一起来|让我们一起|让我们共同|不妨想象一下|不妨设想|试想一下" "$FILE")
if [ "$WERON" -gt 0 ]; then
    printf "  ${RED}✗ §1.6.5 拟人化集体代词: %d 处${NC}\n" "$WERON"
    grep -nE "我们都知道|我们大家|让我们一起来|让我们一起|让我们共同|不妨想象一下|不妨设想|试想一下" "$FILE" | head -3 | sed 's/^/    /'
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s16" "$WERON"
else
    printf "  ${GRN}✓ §1.6.5 拟人化集体代词 = 0${NC}\n"
fi
echo

# ----------------------------------------------------------
# §1.7 Wikipedia 长尾盲区（v4.2 新增，单条命中即 FAIL）
# ----------------------------------------------------------
echo "▼ §1.7 Wikipedia 长尾盲区（阈值 = 0）"

# §1.7.1 Reference markup bugs（确凿 AI 工具输出残留）
MARKUP_BUGS=":contentReference|oaicite|oai_citation|attached_file|grok_card|grok-card"
MARKUP_COUNT=$(count_pattern "$MARKUP_BUGS" "$FILE")
if [ "$MARKUP_COUNT" -gt 0 ]; then
    printf "  ${RED}✗ §1.7.1 Reference markup bugs (oaicite 等): %d 处${NC}\n" "$MARKUP_COUNT"
    grep -nE "$MARKUP_BUGS" "$FILE" | head -3 | sed 's/^/    /'
    [ "$MODE" = "suggest" ] && suggest_for wp_long
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s17" "$MARKUP_COUNT"
else
    printf "  ${GRN}✓ §1.7.1 Reference markup bugs = 0${NC}\n"
fi

# §1.7.2 Placeholder dates
PLACEHOLDER_DATE="20[0-9][0-9]-xx-xx|XXXX-XX-XX|\\{\\{access-date\\|.*xx-xx"
PLACEHOLDER_COUNT=$(count_pattern "$PLACEHOLDER_DATE" "$FILE")
if [ "$PLACEHOLDER_COUNT" -gt 0 ]; then
    printf "  ${RED}✗ §1.7.2 Placeholder dates: %d 处${NC}\n" "$PLACEHOLDER_COUNT"
    grep -nE "$PLACEHOLDER_DATE" "$FILE" | head -3 | sed 's/^/    /'
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s17" "$PLACEHOLDER_COUNT"
else
    printf "  ${GRN}✓ §1.7.2 Placeholder dates = 0${NC}\n"
fi

# §1.7.5 Inline-header vertical lists（粘贴式段首标题）
INLINE_HEAD="^Background:|^Note:|^Summary:|^Context:|^背景：|^说明：|^小结："
INLINE_COUNT=$(grep -cE "$INLINE_HEAD" "$FILE" 2>/dev/null || echo 0)
INLINE_COUNT=$(echo "$INLINE_COUNT" | head -1 | tr -d ' \n\r')
[ -z "$INLINE_COUNT" ] && INLINE_COUNT=0
if [ "$INLINE_COUNT" -gt 0 ]; then
    printf "  ${YEL}⚠ §1.7.5 Inline-header 段首标题: %d 处${NC}\n" "$INLINE_COUNT"
    WARNINGS=$((WARNINGS + 1))
    inc_section "s17" "$INLINE_COUNT"
else
    printf "  ${GRN}✓ §1.7.5 Inline-header 段首标题 = 0${NC}\n"
fi

# §1.7.7 Thematic breaks before headings（标题前水平线，按文件长度自适应阈值）
THEMATIC=$(grep -cE '^---$' "$FILE" 2>/dev/null || echo 0)
THEMATIC=$(echo "$THEMATIC" | head -1 | tr -d ' \n\r')
[ -z "$THEMATIC" ] && THEMATIC=0
LINES=$(wc -l < "$FILE" 2>/dev/null | tr -d ' ')
[ -z "$LINES" ] && LINES=0
# 阈值：每 30 行允许 1 条 thematic break，最少 5
THEMATIC_THRESH=$((LINES / 30))
[ "$THEMATIC_THRESH" -lt 5 ] && THEMATIC_THRESH=5
if [ "$THEMATIC" -gt "$THEMATIC_THRESH" ]; then
    printf "  ${YEL}⚠ §1.7.7 Thematic breaks: %d 处 / 阈值 ≤ %d${NC}\n" "$THEMATIC" "$THEMATIC_THRESH"
    WARNINGS=$((WARNINGS + 1))
    inc_section "s17" "$THEMATIC"
else
    printf "  ${GRN}✓ §1.7.7 Thematic breaks: %d / 阈值 ≤ %d${NC}\n" "$THEMATIC" "$THEMATIC_THRESH"
fi
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
# 分组密度报表（v4.2 新增）
# ----------------------------------------------------------
echo "▼ 分组密度报表（按 anti-ai-taste-anchors.md 章节）"
printf "  §1.1: %d 处\n" "$SC_s11"
printf "  §1.2: %d 处\n" "$SC_s12"
printf "  §1.3: %d 处\n" "$SC_s13"
printf "  §1.4: %d 处\n" "$SC_s14"
printf "  §1.5: %d 处\n" "$SC_s15"
printf "  §1.6: %d 处\n" "$SC_s16"
printf "  §1.7: %d 处\n" "$SC_s17"
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
    if [ "$MODE" != "suggest" ]; then
        echo "提示：加 --suggest-fix 获取改写建议"
    fi
    echo "下一步：重写违规处，再次运行本脚本，直至全部通过"
    exit 1
fi
