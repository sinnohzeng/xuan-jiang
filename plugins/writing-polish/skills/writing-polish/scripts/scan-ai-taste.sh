#!/usr/bin/env bash
# scan-ai-taste.sh —— writing-polish v9.2 L1 hard gate
#
# 角色：交付前 AI 味自检（L1 硬扫）+ JSON 输出供主对话 / writing-reviewer 路由决策。
# 在交付任何修改稿前必跑。任何硬约束未达标，禁止交付。
#
# v9.0 白熊效应治理：精简硬红线 ~40 条（删除英文词汇红线、低频近义变体），
#   软信号下沉 reviewer NL 判断，保留上下文白名单 + 句长方差 + 结构检测。
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
# JSON 契约：assets/scan-output.schema.json
# 日志契约：evals/offline-harness/eval-record.schema.json（离线 dev-eval）
# 规则定义：references/anti-ai-taste-anchors.md（~80 条 SSOT，v9.0 精简版）

set -uo pipefail

FILE=""
MODE="standard"
LOG_TO=""
# GENRE 决定体裁豁免档：base（默认，CI 硬闸 / audit / dogfood，无体裁豁免，保留 context 语境白名单）
# | G1-G8（Coach/Polish 由体裁推断显式传入，开启对应体裁的软化豁免）| auto（暂等同 base，未来做体裁自动判别）
GENRE="base"
# legacy positional arg support
if [ "${1:-}" != "" ] && [ "${1:0:2}" != "--" ]; then
    FILE="$1"
    shift
fi
while [ $# -gt 0 ]; do
    case "$1" in
        --suggest-fix) MODE="suggest"; shift ;;
        --json) MODE="json"; shift ;;
        --target) FILE="${2:-}"; shift; [ $# -gt 0 ] && shift ;;
        --log-to) LOG_TO="${2:-}"; shift; [ $# -gt 0 ] && shift ;;
        --genre) GENRE="${2:-base}"; shift; [ $# -gt 0 ] && shift ;;
        *) shift ;;
    esac
done
# 归一 GENRE：auto 暂等同 base（体裁自动判别未实现，诚实降级不假装）
[ "$GENRE" = "auto" ] && GENRE="base"

if [ -z "$FILE" ]; then
    echo "用法: bash scan-ai-taste.sh <file.md|--target file.md> [--suggest-fix|--json|--log-to <jsonl-path>]" >&2
    exit 3
fi
if [ ! -f "$FILE" ]; then
    echo "错误: 文件不存在: $FILE" >&2
    exit 3
fi

# capture stdout into buffer when JSON mode or --log-to is set
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
violations = []  # v8.0 evidence span：行级 {rule, severity, line, matched}
current = None
current_rule = None
current_sev = None
for line in output_plain.splitlines():
    cat_m = re.match(r'^▼\s+(.+?)$', line)
    if cat_m:
        current = {'name': cat_m.group(1).strip(), 'red': 0, 'soft': 0}
        cats.append(current)
        current_rule = None
        continue
    if current is None:
        continue
    red_m = re.match(r'^\s+✗\s+(.+?)[:：]', line)
    soft_m = re.match(r'^\s+⚠\s+(.+?)[:：]', line)
    if red_m:
        current['red'] += 1
        current_rule, current_sev = red_m.group(1).strip(), 'red'
    elif soft_m:
        current['soft'] += 1
        current_rule, current_sev = soft_m.group(1).strip(), 'soft'
    elif re.match(r'^\s+✗', line):
        current['red'] += 1; current_rule = None
    elif re.match(r'^\s+⚠', line):
        current['soft'] += 1; current_rule = None
    elif re.match(r'^\s+✓', line):
        current_rule = None
    elif current_rule is not None:
        dm = re.match(r'^\s+(\d+):(.*)$', line)  # grep -nE 明细行："    <n>:<content>"
        if dm:
            violations.append({
                'rule': current_rule,
                'severity': current_sev,
                'line': int(dm.group(1)),
                'matched': dm.group(2).strip()[:200],
            })
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
        "version": "9.2",
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
        "violations": violations,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))

if log_to:
    log_dir = os.path.dirname(os.path.abspath(log_to))
    if log_dir:
        os.makedirs(log_dir, exist_ok=True)
    final_action = "soft_warning" if exit_code == 2 else "failed" if exit_code == 1 else "error" if exit_code == 3 else "passed"
    log_entry = {
        "version": "9.2",
        "timestamp": datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
        "draft_hash": draft_hash,
        "protocol": "v9.2",
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

# 预处理：豁免 scan-skip 注释块 + YAML frontmatter
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
SC_s11=0; SC_s13=0; SC_s14=0; SC_s15=0; SC_s16=0; SC_s17=0; SC_s18=0; SC_s19=0

# 分组累加器
inc_section() {
    local sec="$1"
    local n="$2"
    case "$sec" in
        s11) SC_s11=$((SC_s11 + n)) ;;
        s13) SC_s13=$((SC_s13 + n)) ;;
        s14) SC_s14=$((SC_s14 + n)) ;;
        s15) SC_s15=$((SC_s15 + n)) ;;
        s16) SC_s16=$((SC_s16 + n)) ;;
        s17) SC_s17=$((SC_s17 + n)) ;;
        s18) SC_s18=$((SC_s18 + n)) ;;
        s19) SC_s19=$((SC_s19 + n)) ;;
    esac
}

# 安全计数函数
count_pattern() {
    local pattern="$1" file="$2" case_insensitive="${3:-}" result
    if [ "$case_insensitive" = "i" ]; then
        result=$(grep -ciE "$pattern" "$file" 2>/dev/null || true)
    else
        result=$(grep -cE "$pattern" "$file" 2>/dev/null || true)
    fi
    result=$(echo "$result" | head -1 | tr -d ' \n\r')
    [ -z "$result" ] && result=0
    echo "$result"
}

# 硬红线检查助手：check_red <PATTERN> <FILE> <LABEL> <SECTION> [SUGGEST_KEY]
check_red() {
    local pattern="$1" file="$2" label="$3" sec="$4" suggest="${5:-}"
    local count
    count=$(count_pattern "$pattern" "$file")
    if [ "$count" -gt 0 ]; then
        printf "  ${RED}✗ %s: %d 处${NC}\n" "$label" "$count"
        grep -nE "$pattern" "$file" | head -5 | sed 's/^/    /'
        [ -n "$suggest" ] && [ "$MODE" = "suggest" ] && suggest_for "$suggest"
        VIOLATIONS=$((VIOLATIONS + 1))
        inc_section "$sec" "$count"
        return 1
    else
        printf "  ${GRN}✓ %s = 0${NC}\n" "$label"
        return 0
    fi
}

# v4.3 上下文感知白名单：词命中后看 ±2 行窗口是否含白名单关键词，含则豁免
# 用法：count_with_context_whitelist <WORD> <WHITELIST> <FILE>
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
        ascii_quote) echo "    改写：替换为大陆国标弯引号 "" '' （U+201C / U+201D / U+2018 / U+2019）";;
        math_symbol) echo "    改写：重构整段表述。例：'A + B + C' → 'A、B 和 C 三大要素'";;
        neg_parallel) echo "    改写：把'不是 X 而是 Y'改成直接陈述 Y";;
        cn_hard) echo "    改写：详见 anti-ai-taste-anchors.md §1.1，改成具体动词或事实陈述";;
        sanduan) echo "    改写：'首先 / 其次 / 最后'改成'一是 / 二是 / 三是'党政公文体例";;
        drama) echo "    改写：如确为 IT 实物语境（机房 / 等保 / WAF），±2 行内含 IT 关键词即可豁免";;
        jargon) echo "    改写：如确为党政咨询语境（同级对标 / 对标先进），±2 行内含公文关键词即可豁免";;
        meta) echo "    改写：删除元注释 / 自我介绍 / 免责声明 / 服务话术，直接进入正文";;
        wp_long) echo "    改写：详见 anti-ai-taste-anchors.md §1.3，清理 AI 工具输出残留";;
    esac
}

# 逐词替换建议表（仅在 --suggest-fix 模式下输出）
fix_word() {
    case "$1" in
        赋能) echo "帮 / 支持 / 让…能" ;;
        抓手) echo "着力点 / 办法 / 突破口" ;;
        闭环) echo "全流程管好 / 形成完整流程" ;;
        打造) echo "建 / 做成 / 建成" ;;
        助力) echo "帮 / 推动" ;;
        链路) echo "环节 / 流程" ;;
        拉通) echo "打通 / 协调" ;;
        深度融合) echo "深度结合" ;;
        提质增效) echo "提高质量和效率" ;;
        多维度) echo "多方面 / 从几个角度" ;;
        体系化) echo "成体系 / 系统地" ;;
        跨界融合) echo "跨领域结合" ;;
        重塑) echo "重新调整 / 重建" ;;
        切实推动) echo "推动 / 抓落实" ;;
        *) return 1 ;;
    esac
}

# §1.4.0 破折号检测（含法律/政策语境白名单，v9.1 新增）
check_dash_with_legal_exempt() {
    local file="$1"
    local legal_kw="法律|法规|条例|条款|立法|司法|执法|法治|依法行政|《.*法》|《.*条例》|《.*规定》"
    local dash_re="——|—|――|―"
    local hits=0
    local exempted=0
    while IFS=: read -r lineno _rest; do
        [ -z "$lineno" ] && continue
        hits=$((hits + 1))
        local lo=$((lineno - 2))
        local hi=$((lineno + 2))
        [ "$lo" -lt 1 ] && lo=1
        local context
        context=$(sed -n "${lo},${hi}p" "$file")
        if echo "$context" | grep -qE "$legal_kw"; then
            exempted=$((exempted + 1))
            printf "  ${GRN}✓ §1.4 破折号 L%s: 法律/政策语境豁免${NC}\n" "$lineno"
        else
            VIOLATIONS=$((VIOLATIONS + 1))
            inc_section "s14" 1
            printf "  ${RED}✗ §1.4 破折号 L%s${NC}\n" "$lineno"
            sed -n "${lineno}p" "$file" | sed 's/^/    /'
        fi
    done < <(grep -nE "$dash_re" "$file")
    if [ "$hits" -eq 0 ]; then
        printf "  ${GRN}✓ §1.4 破折号 = 0${NC}\n"
    elif [ "$hits" -eq "$exempted" ]; then
        printf "  ${GRN}✓ §1.4 破折号: %d 处全部法律语境豁免${NC}\n" "$hits"
    fi
}

echo "================================================"
echo "       AI 味红线扫描 v9.2"
echo "       文件：$ORIG_FILE"
[ "$MODE" = "suggest" ] && echo "       模式：建议改写"
echo "================================================"
echo

# ----------------------------------------------------------
# §1.4 标点红线（必须 = 0）
# ----------------------------------------------------------
echo "▼ §1.4 标点红线（阈值 = 0）"
check_dash_with_legal_exempt "$FILE"
check_red "（如|（即|（也就是说" "$FILE" "括号内补充" "s14" "paren" || true

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

# §1.4.114 每段加粗冒号开头
check_red '\*\*[^*]{1,8}：\*\*|\*\*重点\*\*|\*\*关键\*\*|\*\*注意\*\*|\*\*核心要点\*\*' "$FILE" "每段加粗冒号开头" "s14" || true

echo

# ----------------------------------------------------------
# §1.3 句式红线（必须 = 0）
# ----------------------------------------------------------
# §1.3 句式软信号：否定平行段内 ≥3 次才软 WARN，低密度下沉 reviewer
echo "▼ §1.3 句式软信号（否定平行，下沉 L3 reviewer）"
NEG_PARALLEL_RE="不是.{1,15}?而是|不仅.{1,15}?更是|不只是.{1,15}?而是|并非.{1,15}?而是|与其说.{1,10}?不如说"
NEG_TOTAL=$(count_pattern "$NEG_PARALLEL_RE" "$FILE")
# per-block 最大密度：按空行切段，标题行 / 列表项各自成块
NEG_BLOCK_MAX=$(python3 - "$FILE" <<'PYEOF'
import re, sys
try:
    text = open(sys.argv[1], encoding='utf-8').read()
except Exception:
    print(0); sys.exit(0)
neg = re.compile(r'不是.{1,15}?而是|不仅.{1,15}?更是|不只是.{1,15}?而是|并非.{1,15}?而是|与其说.{1,10}?不如说')
blocks, cur = [], []
for line in text.split('\n'):
    s = line.strip()
    if s == '':
        if cur: blocks.append('\n'.join(cur)); cur = []
    elif s.startswith('#') or re.match(r'^([-*]|\d+[.)])\s', s):
        if cur: blocks.append('\n'.join(cur)); cur = []
        blocks.append(line)  # 列表项 / 标题各自成块
    else:
        cur.append(line)
if cur: blocks.append('\n'.join(cur))
print(max((len(neg.findall(b)) for b in blocks), default=0))
PYEOF
)
NEG_BLOCK_MAX=$(echo "$NEG_BLOCK_MAX" | head -1 | tr -d ' \n\r'); [ -z "$NEG_BLOCK_MAX" ] && NEG_BLOCK_MAX=0
if [ "$NEG_BLOCK_MAX" -ge 3 ]; then
    printf "  ${YEL}⚠ 否定平行段内密集: 单段最多 %d 处（≥3 触发软警告，非硬红线；结构同一性交 reviewer）${NC}\n" "$NEG_BLOCK_MAX"
    grep -nE "$NEG_PARALLEL_RE" "$FILE" | head -3 | sed 's/^/    /'
    [ "$MODE" = "suggest" ] && suggest_for neg_parallel
    WARNINGS=$((WARNINGS + 1))
    inc_section "s13" "$NEG_BLOCK_MAX"
elif [ "$NEG_TOTAL" -gt 0 ]; then
    printf "  ${GRN}✓ 否定平行: %d 处（段内 <3，低密度，下沉 reviewer 语义判定）${NC}\n" "$NEG_TOTAL"
else
    printf "  ${GRN}✓ 否定平行结构 = 0${NC}\n"
fi

# “如果说…那么” v9.0 下沉 reviewer，不再 L1 检测
echo

# ----------------------------------------------------------
# §1.1 中文词汇红线（核心 15 条，阈值 = 0）
# ----------------------------------------------------------
echo "▼ §1.1 中文词汇红线（核心 15 条，阈值 = 0）"
CN_HARD="赋能|重塑|深度融合|闭环|抓手|链路|打造|助力|切实推动|多维度|体系化|话语建构|跨界融合|提质增效|拉通"
CN_RAW=$(grep -oE "$CN_HARD" "$FILE" 2>/dev/null || true)
CN_COUNT=$(echo "$CN_RAW" | grep -c . 2>/dev/null || true)
CN_COUNT=$(echo "$CN_COUNT" | head -1 | tr -d ' \n\r')
[ -z "$CN_COUNT" ] && CN_COUNT=0

if [ "$CN_COUNT" -gt 0 ]; then
    printf "  ${RED}✗ 中文红线词命中: %d 处${NC}\n" "$CN_COUNT"
    grep -nE "$CN_HARD" "$FILE" | head -10 | sed 's/^/    /'
    if [ "$MODE" = "suggest" ]; then
        suggest_for cn_hard
        # 逐词替换建议
        for w in $(echo "$CN_RAW" | sort -u); do
            rep=$(fix_word "$w") && printf "      %s → %s\n" "$w" "$rep"
        done
    fi
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s11" "$CN_COUNT"
else
    printf "  ${GRN}✓ 中文红线词命中 = 0${NC}\n"
fi
echo

# ----------------------------------------------------------
# §1.1 三段式套壳（阈值 = 0）
# ----------------------------------------------------------
echo "▼ 三段式套壳（阈值 = 0）"
check_red "首先.{0,30}其次.{0,30}(最后|再者|然后|最终)" "$FILE" "首先...其次...最后" "s11" "sanduan" || true
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
# §1.5 上下文白名单检测（硬红线 + 白名单豁免）
# ----------------------------------------------------------
echo "▼ §1.5 上下文白名单检测（防火墙 IT 语境 / 对标党政语境）"

# §1.5.1 防火墙：IT 实物语境白名单豁免，非 IT 语境仍为硬红线
DRAMA_IT_WHITELIST="机房|等保|GB/T 22239|服务器|端口|协议|入侵检测|网络架构|网络分区|网络边界|访问控制|安全组|子网|VPC|VPN|路由|交换机|WAF|Web 应用|UTM|IDS|IPS|NGFW|部署.{0,5}台|配置规则|防护设备|安全设备|网络安全|数据中心|云服务|裸金属"
FW_DRAMA=$(count_with_context_whitelist "防火墙" "$DRAMA_IT_WHITELIST" "$FILE")
if [ "$FW_DRAMA" -gt 0 ]; then
    printf "  ${RED}✗ §1.5.1 防火墙（非 IT 语境）: %d 处${NC}\n" "$FW_DRAMA"
    grep -nE "防火墙" "$FILE" | head -3 | sed 's/^/    /'
    [ "$MODE" = "suggest" ] && suggest_for drama
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s15" "$FW_DRAMA"
else
    printf "  ${GRN}✓ §1.5.1 防火墙 = 0（或 IT 语境豁免）${NC}\n"
fi

# §1.5.2 对标：党政咨询语境白名单豁免，纯互联网语境仍为硬红线
JARGON_GOV_WHITELIST="政府工作报告|党中央|党的二十大|二十届|总书记|讲话精神|对标对表|对标先进|对标一流|对标国际|对标国内|同级|同业|国际先进|行业领先|启示|案例|经验|做法|建设方案|实施方案|发展规划|高质量发展|党建|政治学习|十四五|十五五"
DB_JARGON=$(count_with_context_whitelist "对标" "$JARGON_GOV_WHITELIST" "$FILE")
if [ "$DB_JARGON" -gt 0 ]; then
    printf "  ${RED}✗ §1.5.2 对标（非党政语境）: %d 处${NC}\n" "$DB_JARGON"
    grep -nE "对标" "$FILE" | head -3 | sed 's/^/    /'
    [ "$MODE" = "suggest" ] && suggest_for jargon
    VIOLATIONS=$((VIOLATIONS + 1))
    inc_section "s15" "$DB_JARGON"
else
    printf "  ${GRN}✓ §1.5.2 对标 = 0（或党政语境豁免）${NC}\n"
fi

# §1.5.3-1.5.4 网络口语 / 程序员腔：v9.0 下沉 reviewer，仅做软警告提示
PMS="MVP|PMF|冷启动|热启动|解耦|高内聚|新范式"
PMS_COUNT=$(count_pattern "$PMS" "$FILE")
if [ "$PMS_COUNT" -gt 0 ]; then
    printf "  ${YEL}⚠ §1.5.3-4 程序员 / 产品经理腔: %d 处${NC} (技术语境合法，下沉 reviewer 判定)\n" "$PMS_COUNT"
    WARNINGS=$((WARNINGS + 1))
    inc_section "s15" "$PMS_COUNT"
else
    printf "  ${GRN}✓ §1.5.3-4 程序员 / 产品经理腔 = 0${NC}\n"
fi
echo

# ----------------------------------------------------------
# §1.6 元注释 / 客服话术（v4.2 新增）
# ----------------------------------------------------------
echo "▼ §1.6 元注释 / 客服话术（阈值 = 0）"

META_OPEN="以下是几点说明|以下是几点想法|我将从.{1,3}个方面|我将围绕|本文将从.{1,3}个方面|本文将围绕|下文将从|下面从.{0,8}展开|让我为您整理|让我帮您梳理|让我先来分析|请允许我|请容我先|接下来我会|我接下来要"
check_red "$META_OPEN" "$FILE" "§1.6.1 元注释开头" "s16" "meta" || true

SELF_INTRO="作为一个 AI 助手|作为一个 AI 模型|作为一个语言模型|作为大语言模型|作为对话式 AI|我虽然是 AI|我作为 AI 的局限性|我的知识截止日期"
check_red "$SELF_INTRO" "$FILE" "§1.6.2 自我介绍 / 身份声明" "s16" "meta" || true

DISCLAIMER="以上信息仅供参考|仅供参考请以官方为准|建议咨询专业人士|建议咨询医生|建议咨询律师|我无法替代专业建议|以上内容如有错误请指正|如有不当之处请见谅"
check_red "$DISCLAIMER" "$FILE" "§1.6.3 免责声明" "s16" "meta" || true

SERVICE_TAIL="希望对您有帮助|希望这能帮到您|希望这些内容对您有用|如有其他问题.{0,5}欢迎继续提问|还有什么问题尽管问|有任何疑问请随时告诉我|有不清楚的地方请告诉我|谢谢您的提问|谢谢您的信任|感谢您的耐心"
check_red "$SERVICE_TAIL" "$FILE" "§1.6.4 服务话术段尾" "s16" "meta" || true

# §1.6.5 拟人化集体代词：G2/G6/G7 体裁豁免，其余软 WARN
WERON_RE="我们都知道|我们大家|让我们一起来|让我们一起|让我们共同|不妨想象一下|不妨设想|试想一下"
WERON=$(count_pattern "$WERON_RE" "$FILE")
case "$GENRE" in
    G2|G6|G7)
        printf "  ${GRN}✓ §1.6.5 拟人化集体代词: %d 处（%s 体裁动员修辞豁免）${NC}\n" "$WERON" "$GENRE" ;;
    *)
        if [ "$WERON" -gt 0 ]; then
            printf "  ${YEL}⚠ §1.6.5 集体代词: %d 处（软信号；传 --genre G2/G6/G7 可豁免）${NC}\n" "$WERON"
            grep -nE "$WERON_RE" "$FILE" | head -3 | sed 's/^/    /'
            WARNINGS=$((WARNINGS + 1))
            inc_section "s16" "$WERON"
        else
            printf "  ${GRN}✓ §1.6.5 拟人化集体代词 = 0${NC}\n"
        fi ;;
esac
echo

# ----------------------------------------------------------
# §1.7 工具残留（硬红线）
# ----------------------------------------------------------
echo "▼ §1.7 工具残留（阈值 = 0）"

# §1.7.1 Reference markup bugs（确凿 AI 工具输出残留）
check_red ":contentReference|oaicite|oai_citation|attached_file|grok_card|grok-card" "$FILE" "§1.7.1 markup bugs" "s17" "wp_long" || true

# §1.7.2 Placeholder dates + 错误文号占位
check_red "20[0-9][0-9]-xx-xx|XXXX-XX-XX|\\{\\{access-date\\|.*xx-xx|〔YYYY〕|〔xxx〕|（待补文号）" "$FILE" "§1.7.2 Placeholder dates" "s17" || true

echo

echo

# ----------------------------------------------------------
# §1.8 开篇模板化检测（v9.1 新增，GAP-1）
# ----------------------------------------------------------
echo "▼ §1.8 开篇模板化检测"
OPENING_RESULT=$(python3 - "$FILE" <<'PYEOF'
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
if text.startswith('---'):
    end = text.find('---', 3)
    if end != -1:
        text = text[end+3:].strip()
first_para = ""
for line in text.split('\n'):
    line = line.strip()
    if not line or line.startswith('#'):
        continue
    first_para = line
    break
templates = [
    r'党中央.{0,10}国务院围绕.{2,30}作出.{2,20}(部署|决定|安排|要求)',
    r'随着.{2,30}(深入|快速|持续|蓬勃)发展',
    r'在.{2,20}(大背景|新形势|新时代|大趋势)下',
    r'当前.{0,5}.{2,30}(正面临|正处于|正在经历)',
    r'近年来.{0,5}.{2,30}(取得了|实现了|达到了).{2,20}(成就|进展|突破)',
]
for t in templates:
    m = re.search(t, first_para)
    if m:
        print(f'WARN|{m.group()[:80]}')
        sys.exit(0)
print('OK')
PYEOF
)
if [[ "$OPENING_RESULT" == WARN* ]]; then
    matched="${OPENING_RESULT#WARN|}"
    printf "  ${YEL}⚠ §1.8 开篇模板复用: 首段匹配常见政策性开篇句式: \"%s\"（跨文档重复时为强信号）${NC}\n" "$matched"
    WARNINGS=$((WARNINGS + 1))
    inc_section "s18" 1
else
    printf "  ${GRN}✓ §1.8 开篇模板复用 = 未检出${NC}\n"
fi
echo

# ----------------------------------------------------------
# §1.9 超长段落检测（v9.1 新增，GAP-3）
# ----------------------------------------------------------
echo "▼ §1.9 超长段落检测"
PARA_RESULT=$(python3 - "$FILE" <<'PYEOF'
import sys

text = open(sys.argv[1], encoding='utf-8').read()
lines = text.split('\n')

paragraphs = []
in_code = False
current_start = None
current_chars = 0

for i, line in enumerate(lines, 1):
    stripped = line.strip()
    if stripped.startswith('```'):
        in_code = not in_code
        if current_start is not None and current_chars > 0:
            paragraphs.append((current_start, current_chars))
            current_start = None
            current_chars = 0
        continue
    if in_code:
        continue
    if stripped.startswith('|') or stripped.startswith('>') or stripped.startswith('#'):
        if current_start is not None and current_chars > 0:
            paragraphs.append((current_start, current_chars))
            current_start = None
            current_chars = 0
        continue
    if not stripped:
        if current_start is not None and current_chars > 0:
            paragraphs.append((current_start, current_chars))
            current_start = None
            current_chars = 0
        continue
    if current_start is None:
        current_start = i
    current_chars += len(stripped)

if current_start is not None and current_chars > 0:
    paragraphs.append((current_start, current_chars))

SOFT = 500
HARD = 800
found = False
for start_line, cc in paragraphs:
    if cc >= HARD:
        print(f'HARD|{start_line}|{cc}')
        found = True
    elif cc >= SOFT:
        print(f'SOFT|{start_line}|{cc}')
        found = True
if not found:
    print('OK')
PYEOF
)
if [[ "$PARA_RESULT" != "OK" ]]; then
    while IFS='|' read -r level line count; do
        if [[ "$level" == "HARD" ]]; then
            printf "  ${YEL}⚠ §1.9 超长段落: 第 %s 行起 %s 字（≥ 800 字，建议拆分）${NC}\n" "$line" "$count"
        else
            printf "  ${YEL}⚠ §1.9 超长段落: 第 %s 行起 %s 字（≥ 500 字，建议拆分）${NC}\n" "$line" "$count"
        fi
    done <<< "$PARA_RESULT"
    WARNINGS=$((WARNINGS + 1))
    inc_section "s19" 1
else
    printf "  ${GRN}✓ §1.9 超长段落 = 无超长段落${NC}\n"
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

echo "▼ 分组密度报表"
for sec in s11 s13 s14 s15 s16 s17 s18 s19; do
    eval "v=\$SC_$sec"
    [ "$v" -gt 0 ] && printf "  %s: %d 处\n" "$sec" "$v"
done
echo

# ----------------------------------------------------------
# 总结
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
