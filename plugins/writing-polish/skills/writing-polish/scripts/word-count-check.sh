#!/usr/bin/env bash
# word-count-check.sh —— 句长方差 + 段落同质化检查
#
# 单独跑：bash word-count-check.sh <file.md>
# 通常作为 scan-ai-taste.sh 的子检查。
#
# 阈值：
#   句长标准差 ≥ 8（人类写作有长短交错）
#   段落字数标准差 ≥ 30（段落长短不一）

set -uo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo "用法: bash word-count-check.sh <file.md>"
    exit 1
fi

python3 << EOF
import re, statistics
text = open("$FILE").read()

# 句长分析
sents = [len(s) for s in re.split('[。！？；]', text) if 5 < len(s) < 200]
print("=== 句长分析 ===")
if len(sents) > 5:
    print(f"句子数: {len(sents)}")
    print(f"平均: {statistics.mean(sents):.1f} 字")
    print(f"标准差: {statistics.stdev(sents):.1f} (阈值 ≥ 8)")
    print(f"最短: {min(sents)} 字 / 最长: {max(sents)} 字")
    if statistics.stdev(sents) < 8:
        print("⚠ 句长过于均匀，AI 味嫌疑")
else:
    print(f"文本过短（{len(sents)} 句），跳过")

# 段落长度分析
print()
print("=== 段落长度分析 ===")
paras = [len(p) for p in re.split(r'\n\s*\n', text) if 30 < len(p) < 2000]
if len(paras) > 3:
    print(f"段落数: {len(paras)}")
    print(f"平均: {statistics.mean(paras):.0f} 字")
    print(f"标准差: {statistics.stdev(paras):.0f} (阈值 ≥ 30)")
    print(f"最短: {min(paras)} 字 / 最长: {max(paras)} 字")
    if statistics.stdev(paras) < 30:
        print("⚠ 段落字数过于均匀，AI 味嫌疑")
else:
    print(f"段落数过少（{len(paras)} 段），跳过")
EOF
