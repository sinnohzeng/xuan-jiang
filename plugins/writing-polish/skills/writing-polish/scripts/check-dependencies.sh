#!/usr/bin/env bash
# check-dependencies.sh —— writing-polish v7.0 依赖检查 + 单向依赖自检
#
# 默认行为：触发 SKILL 前预检 pandoc / Python / docx-editor 是否齐备。
# 缺什么给什么命令，不让用户卡在"为什么 pandoc 找不到"上。
#
# 子命令：
#   bash check-dependencies.sh                  默认依赖检查
#   bash check-dependencies.sh --check-cycles   v6.1 新增：单向依赖自检（references/ 反引 SKILL.md → 报警）
#
# 退出码（默认模式）：
#   0  全部齐备
#   1  有缺失依赖（基础功能受限）
#   2  有缺失依赖（DOCX 功能受限）
#
# 退出码（--check-cycles 模式）：
#   0  零循环依赖
#   3  发现反向引用

if [[ "${1:-}" == "--check-cycles" ]]; then
    set -uo pipefail
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SKILL_ROOT="$SCRIPT_DIR/.."
    VIOLATIONS=0

    # 只检测**执行性**反向引用，prose 提及 SKILL.md 作 progressive disclosure 注释是合规的。
    # 执行性 = markdown 链接 [X](../SKILL.md) 或 bash source/exec SKILL.md。
    echo "▼ 单向依赖自检 v7.0（依赖方向 SKILL.md → { references/, scripts/, assets/ }；agents/ 由主对话经 Task 调用）"
    echo

    echo "  ▼ references/ 不应有 markdown 链接指回 SKILL.md"
    while IFS= read -r -d '' f; do
        if grep -nE '\]\(\.\./SKILL\.md' "$f" >/dev/null 2>&1; then
            echo "    ✗ $f"
            grep -nE '\]\(\.\./SKILL\.md' "$f" | head -2 | sed 's/^/        /'
            VIOLATIONS=$((VIOLATIONS + 1))
        fi
    done < <(find "$SKILL_ROOT/references" -name "*.md" -print0 2>/dev/null)

    echo "  ▼ scripts/ 不应 source/bash/exec SKILL.md（自身脚本除外）"
    while IFS= read -r -d '' f; do
        # 跳过本脚本（pattern 自身会 self-match）
        [[ "$(basename "$f")" == "check-dependencies.sh" ]] && continue
        if grep -nE '^[^#]*\b(source|bash|exec)\b[[:space:]]+[^#]*SKILL\.md' "$f" >/dev/null 2>&1; then
            echo "    ✗ $f"
            VIOLATIONS=$((VIOLATIONS + 1))
        fi
    done < <(find "$SKILL_ROOT/scripts" -type f \( -name "*.sh" -o -name "*.py" \) -print0 2>/dev/null)

    echo
    if [[ $VIOLATIONS -eq 0 ]]; then
        echo "✅ 零循环依赖"
        exit 0
    else
        echo "✗ 发现 $VIOLATIONS 处执行性反向引用"
        exit 3
    fi
fi

set -uo pipefail

if [ -t 1 ]; then
    RED='\033[0;31m'; YEL='\033[0;33m'; GRN='\033[0;32m'; NC='\033[0m'
else
    RED=''; YEL=''; GRN=''; NC=''
fi

MISSING_CORE=0
MISSING_DOCX=0

echo "================================================"
echo "  writing-polish v7.0 依赖检查"
echo "================================================"
echo

# ---- 核心依赖 ----
echo "▼ 核心依赖（Markdown / 纯文本场景必需）"

if command -v python3 >/dev/null 2>&1; then
    PYV=$(python3 --version 2>&1 | awk '{print $2}')
    PYMAJOR=$(echo "$PYV" | cut -d. -f1)
    PYMINOR=$(echo "$PYV" | cut -d. -f2)
    if [ "$PYMAJOR" -ge 3 ] && [ "$PYMINOR" -ge 7 ]; then
        printf "  ${GRN}✓ python3 %s${NC}\n" "$PYV"
    else
        printf "  ${YEL}⚠ python3 %s（需 3.7+）${NC}\n" "$PYV"
        MISSING_CORE=$((MISSING_CORE + 1))
    fi
else
    printf "  ${RED}✗ python3 未安装${NC}\n"
    echo "    macOS: brew install python3"
    echo "    Ubuntu: apt install python3"
    MISSING_CORE=$((MISSING_CORE + 1))
fi

if command -v bash >/dev/null 2>&1; then
    BASHV=$(bash --version | head -1 | awk '{print $4}')
    printf "  ${GRN}✓ bash %s${NC}\n" "$BASHV"
else
    printf "  ${RED}✗ bash 未安装（不应发生）${NC}\n"
    MISSING_CORE=$((MISSING_CORE + 1))
fi

if command -v grep >/dev/null 2>&1; then
    printf "  ${GRN}✓ grep${NC}\n"
else
    printf "  ${RED}✗ grep 未安装（不应发生）${NC}\n"
    MISSING_CORE=$((MISSING_CORE + 1))
fi

echo

# ---- DOCX 依赖 ----
echo "▼ DOCX 依赖（Word 文档读写场景必需）"

if command -v pandoc >/dev/null 2>&1; then
    PANV=$(pandoc --version 2>&1 | head -1 | awk '{print $2}')
    printf "  ${GRN}✓ pandoc %s${NC}\n" "$PANV"
else
    printf "  ${YEL}⚠ pandoc 未安装（DOCX 读取受限）${NC}\n"
    echo "    macOS: brew install pandoc"
    echo "    Ubuntu: apt install pandoc"
    echo "    Debian: apt install pandoc"
    echo "    docs: https://pandoc.org/installing.html"
    MISSING_DOCX=$((MISSING_DOCX + 1))
fi

if python3 -c "import docx" 2>/dev/null; then
    printf "  ${GRN}✓ python-docx${NC}\n"
else
    printf "  ${YEL}⚠ python-docx 未安装（DOCX 编辑受限）${NC}\n"
    echo "    pip install python-docx"
    MISSING_DOCX=$((MISSING_DOCX + 1))
fi

if python3 -c "import docx_editor" 2>/dev/null; then
    printf "  ${GRN}✓ docx-editor${NC}\n"
else
    printf "  ${YEL}⚠ docx-editor 未安装（修订模式受限）${NC}\n"
    echo "    pip install docx-editor"
    MISSING_DOCX=$((MISSING_DOCX + 1))
fi

echo

# ---- 总结 ----
echo "================================================"
if [ "$MISSING_CORE" -eq 0 ] && [ "$MISSING_DOCX" -eq 0 ]; then
    printf "${GRN}✅ 全部依赖齐备${NC}\n"
    exit 0
elif [ "$MISSING_CORE" -gt 0 ]; then
    printf "${RED}✗ 核心依赖缺失 %d 项，基础 scan 功能受限${NC}\n" "$MISSING_CORE"
    exit 1
else
    printf "${YEL}⚠ DOCX 依赖缺失 %d 项，Markdown 功能正常${NC}\n" "$MISSING_DOCX"
    echo "如不处理 Word 文档可忽略此警告"
    exit 2
fi
