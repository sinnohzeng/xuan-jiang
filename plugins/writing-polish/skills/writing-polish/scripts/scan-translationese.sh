#!/usr/bin/env bash
# scan-translationese.sh —— writing-polish v10.1 翻译腔句法软扫描
#
# 用法：
#   bash scan-translationese.sh <file.md>
#   bash scan-translationese.sh --target <file.md> --json
#   bash scan-translationese.sh --help
#
# 所有检测均为软 WARN（⚠），不产生硬 FAIL。
# 翻译腔是结构性问题，需要 reviewer 语义判断，regex 只做辅助提示。
#
# 四族翻译腔模式：
#   1. 长定语族：连续"的"字定语链、"对于…来说/而言"密集
#   2. 被动/名词化族：被动句、"进行了/实现了/完成了"名词化
#   3. 连接词族：书面连接词密集（因此/然而/此外/与此同时/不仅如此）
#   4. 形式主语族：形式主语密集（有必要/值得注意的是/应该指出/需要指出的是）
#
# 退出码：
#   0  无翻译腔警告
#   2  有软警告（非阻断）
#   3  使用错误（缺参数 / 文件不存在）

set -uo pipefail

# --- 参数解析 ---
FILE=""
MODE="human"

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    cat <<'HELP'
scan-translationese.sh —— writing-polish v10.1 翻译腔句法软扫描

用法：
  bash scan-translationese.sh <file.md>
  bash scan-translationese.sh --target <file.md> [--json]
  bash scan-translationese.sh --help

所有检测均为软 WARN（⚠），不产生硬 FAIL。
翻译腔是结构性问题，regex 只做辅助提示，需 reviewer 语义判断。

四族检测：
  1. 长定语族    连续"的"字定语链 + "对于…来说/而言"密集
  2. 被动/名词化族  被动句 + "进行了/实现了/完成了"名词化
  3. 连接词族    书面连接词密集（因此/然而/此外/与此同时/不仅如此）
  4. 形式主语族   形式主语密集（有必要/值得注意的是/应该指出）

退出码：
  0  无翻译腔警告
  2  有软警告（非阻断）
  3  使用错误
HELP
    exit 0
fi

# legacy positional arg support
if [ "${1:-}" != "" ] && [ "${1:0:2}" != "--" ]; then
    FILE="$1"
    shift
fi
while [ $# -gt 0 ]; do
    case "$1" in
        --json) MODE="json"; shift ;;
        --target) FILE="${2:-}"; shift; [ $# -gt 0 ] && shift ;;
        *) shift ;;
    esac
done

if [ -z "$FILE" ]; then
    echo "用法: bash scan-translationese.sh <file.md|--target file.md> [--json]" >&2
    exit 3
fi
if [ ! -f "$FILE" ]; then
    echo "错误: 文件不存在: $FILE" >&2
    exit 3
fi

ORIG_FILE="$FILE"

# --- 颜色 ---
if [ -t 1 ] && [ "$MODE" = "human" ]; then
    YEL='\033[0;33m'; GRN='\033[0;32m'; NC='\033[0m'
else
    YEL=''; GRN=''; NC=''
fi

# --- 主检测逻辑（内嵌 python，与 scan-ai-taste.sh 风格一致）---
python3 - "$ORIG_FILE" "$MODE" << 'PYEOF'
import re, json, sys, os
from datetime import datetime, timezone

file_path = sys.argv[1]
mode = sys.argv[2]

try:
    text = open(file_path, encoding='utf-8').read()
except Exception as e:
    print(f"错误: 无法读取文件: {e}", file=sys.stderr)
    sys.exit(3)

# Strip YAML frontmatter
if text.startswith('---'):
    end = text.find('---', 3)
    if end != -1:
        text = text[end+3:].strip()

# Strip markdown headings and code blocks for cleaner analysis
lines = text.split('\n')
clean_lines = []
in_code = False
for line in lines:
    if line.strip().startswith('```'):
        in_code = not in_code
        clean_lines.append('')
        continue
    if in_code or line.strip().startswith('#'):
        clean_lines.append('')
        continue
    clean_lines.append(line)
clean_text = '\n'.join(clean_lines)

char_count = len(clean_text)
# Estimate "per 500 chars" unit
unit_500 = max(1, char_count / 500)
unit_300 = max(1, char_count / 300)

warnings = []  # list of {family, rule, count, threshold, examples}

# ============================================================
# 族 1: 长定语族
# ============================================================
# 1a: 连续 4+ 个"的"的定语链
pattern_de_chain = r'的.{1,20}的.{1,20}的.{1,20}的.{1,20}的'
de_chain_matches = []
for i, line in enumerate(lines, 1):
    if re.search(pattern_de_chain, line):
        de_chain_matches.append((i, line.strip()[:120]))

if len(de_chain_matches) > 0:
    warnings.append({
        'family': '长定语族',
        'rule': '连续4+个"的"字定语链',
        'count': len(de_chain_matches),
        'threshold': '任何出现即警告',
        'examples': de_chain_matches[:5]
    })

# 1b: "对于…来说/而言"密集（阈值 ≤ 2/500字）
pattern_for = r'对于.{2,30}(来说|而言)'
for_matches = []
for i, line in enumerate(lines, 1):
    for m in re.finditer(pattern_for, line):
        for_matches.append((i, line.strip()[:120]))

for_count = len(for_matches)
for_pct = (for_count / char_count * 100) if char_count > 0 else 0
if for_pct > 0.01:
    warnings.append({
        'family': '长定语族',
        'rule': '"对于…来说/而言"密集',
        'count': for_count,
        'threshold': f'{for_pct:.3f}% > 0.01%',
        'examples': for_matches[:5]
    })

# ============================================================
# 族 2: 被动/名词化族
# ============================================================
# 2a: 被动句（阈值 ≤ 3/500字）
pattern_passive = r'被.{1,20}(所|地|给|认为|视为|看作|当作|称为|誉为|评为|列为|纳入|归入|划入)'
pattern_passive_fixed = r'(被认为是|被视为|被看作|被当作|被称为|被誉为|被评为|被列为|被纳入|被归入)'
passive_matches = []
passive_seen_lines = set()  # dedup: each line counted at most once
for i, line in enumerate(lines, 1):
    if i in passive_seen_lines:
        continue
    for pat in (pattern_passive, pattern_passive_fixed):
        m = re.search(pat, line)
        if m:
            passive_seen_lines.add(i)
            passive_matches.append((i, m.group()))
            break  # only first match per line

passive_count = len(passive_matches)
passive_pct = (passive_count / char_count * 100) if char_count > 0 else 0
if passive_pct > 0.005:
    warnings.append({
        'family': '被动/名词化族',
        'rule': '被动句"被…所/地/给/认为/视为…"密集',
        'count': passive_count,
        'threshold': f'{passive_pct:.3f}% > 0.005%',
        'examples': passive_matches[:5]
    })

# 2b: 名词化（进行了/实现了/完成了 + 的）
pattern_nominal = r'(进行了|实现了|完成了|开展了|推进了|实施了|落实了|推动了|加强了|完善了).{1,20}(的|工作|建设|发展|管理|治理)'
pattern_nominal_shell = r'(进行|实现|完成|开展|推进)(了|着)?(全面的|深入的|系统的|有效的|积极的).{2,15}(工作|建设|发展|改革|治理|管理|评估|分析|研究)'
nominal_matches = []
nominal_seen_lines = set()
for i, line in enumerate(lines, 1):
    if i in nominal_seen_lines:
        continue
    for pat in (pattern_nominal, pattern_nominal_shell):
        m = re.search(pat, line)
        if m:
            nominal_seen_lines.add(i)
            nominal_matches.append((i, m.group()))
            break

nominal_count = len(nominal_matches)
if nominal_count > 0:
    warnings.append({
        'family': '被动/名词化族',
        'rule': '"进行了/实现了/完成了…的"名词化 或 套壳结构',
        'count': nominal_count,
        'threshold': '任何出现即警告',
        'examples': nominal_matches[:5]
    })

# ============================================================
# 族 3: 连接词族
# ============================================================
# 书面连接词密集（阈值 ≤ 3/300字）
pattern_connectors = r'(因此|然而|此外|与此同时|不仅如此|从而|进而|继而|在此基础上|在这种情况下|从这个意义上说|随之而来的是)'
conn_matches = []
conn_seen_lines = set()  # dedup: each line counted at most once
for i, line in enumerate(lines, 1):
    if i in conn_seen_lines:
        continue
    m = re.search(pattern_connectors, line)
    if m:
        conn_seen_lines.add(i)
        conn_matches.append((i, m.group(), line.strip()[:120]))

conn_count = len(conn_matches)
conn_pct = (conn_count / char_count * 100) if char_count > 0 else 0
if conn_pct > 0.03 or conn_count >= 5:
    warnings.append({
        'family': '连接词族',
        'rule': '书面连接词密集（因此/然而/此外/与此同时/不仅如此/从而/进而/继而…）',
        'count': conn_count,
        'threshold': f'{conn_pct:.3f}% > 0.03% 或 count ≥ 5',
        'examples': [(ln, txt) for ln, _, txt in conn_matches[:5]]
    })

# ============================================================
# 族 4: 形式主语族
# ============================================================
# 形式主语密集（阈值 ≤ 2/500字）
pattern_formal_subj = r'(有必要|值得注意的是|应该指出|需要指出的是|需要强调的是|不可忽视的是|不可否认|众所周知|显而易见|毋庸置疑|应当看到|必须承认)'
fs_matches = []
for i, line in enumerate(lines, 1):
    for m in re.finditer(pattern_formal_subj, line):
        fs_matches.append((i, m.group(), line.strip()[:120]))

fs_count = len(fs_matches)
fs_pct = (fs_count / char_count * 100) if char_count > 0 else 0
if fs_pct > 0.01:
    warnings.append({
        'family': '形式主语族',
        'rule': '形式主语密集（有必要/值得注意的是/应该指出/需要指出的是/需要强调的是/不可忽视的是…）',
        'count': fs_count,
        'threshold': f'{fs_pct:.3f}% > 0.01%',
        'examples': [(ln, txt) for ln, _, txt in fs_matches[:5]]
    })

# ============================================================
# 输出
# ============================================================
total_warnings = len(warnings)

if mode == 'json':
    # JSON 输出（与 scan-ai-taste.sh 格式保持一致）
    import hashlib
    draft_hash = hashlib.sha256(text.encode('utf-8')).hexdigest()[:16]
    violations = []
    cats = []
    family_map = {}
    for w in warnings:
        fam = w['family']
        if fam not in family_map:
            family_map[fam] = {'name': fam, 'red': 0, 'soft': 0}
            cats.append(family_map[fam])
        family_map[fam]['soft'] += w['count']
        for ln, txt in w['examples']:
            violations.append({
                'rule': w['rule'],
                'severity': 'soft',
                'line': ln,
                'matched': txt[:200]
            })

    result = {
        "version": "10.1.0",
        "scanner": "translationese",
        "file": os.path.abspath(file_path),
        "draft_hash": draft_hash,
        "exit_code": 2 if total_warnings > 0 else 0,
        "summary": {
            "total_warnings": total_warnings,
            "total_hits": sum(w['count'] for w in warnings),
            "categories": cats,
        },
        "stats": {
            "char_count": char_count,
        },
        "warnings": [
            {
                "family": w['family'],
                "rule": w['rule'],
                "count": w['count'],
                "threshold": w['threshold'],
                "examples": [{"line": ln, "text": txt} for ln, txt in w['examples']]
            }
            for w in warnings
        ],
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
else:
    # 人类可读输出
    print("================================================")
    print("       翻译腔句法软扫描 v10.1")
    print(f"       文件：{file_path}")
    print(f"       字数：{char_count}")
    print("================================================")
    print()

    if not warnings:
        print("  ✓ 未检测到翻译腔模式")
        print()
    else:
        # Group by family
        families = {}
        for w in warnings:
            fam = w['family']
            if fam not in families:
                families[fam] = []
            families[fam].append(w)

        for fam_name in ['长定语族', '被动/名词化族', '连接词族', '形式主语族']:
            if fam_name not in families:
                continue
            fam_warnings = families[fam_name]
            fam_total = sum(w['count'] for w in fam_warnings)
            print(f"▼ {fam_name}（共 {fam_total} 处）")
            for w in fam_warnings:
                print(f"  ⚠ {w['rule']}: {w['count']} 处（阈值 {w['threshold']}）")
                for ln, txt in w['examples']:
                    print(f"    {ln}: {txt[:100]}")
            print()

    print("================================================")
    if total_warnings == 0:
        print("✅ 无翻译腔警告")
    else:
        print(f"⚠ {total_warnings} 项翻译腔软警告（非阻断，建议 reviewer 语义判断）")
    print("================================================")

sys.exit(2 if total_warnings > 0 else 0)
PYEOF

exit $?
