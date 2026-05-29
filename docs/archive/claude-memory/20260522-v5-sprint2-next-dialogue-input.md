# Next Dialogue Input：v5 Sprint 2 prompt 迭代 1 轮 FAIL，4 选 1 决定 v5.0.0 stable 路径

## 入口必读（按顺序）

1. **本 handoff**：[`docs/handoff/20260522-v5-sprint2-prompt-iteration-fail.md`](../../handoff/20260522-v5-sprint2-prompt-iteration-fail.md)（含完整诊断 + 4 路径详细对比 + SLI 命令）
2. **当前 spec.md（v5.1 简化版）**：`plugins/writing-polish/skills/writing-polish/evals/gold-standard/spec.md` §6 发版门槛 D5 acc ≥ 79.5%
3. **前置 handoff（Sprint 1 完成）**：[`docs/handoff/20260520-v5-sprint1-shipped.md`](../../handoff/20260520-v5-sprint1-shipped.md)

## 当前状态一句话

**v5.1 prompt 加 8 段党政公文对标范例后跑 60 段 calibration，D5 accuracy 74.5% → 74.1%（几乎不变），D2 反退 2.5%，overall κ 从 0.368 降到 0.307。判定 FAIL。但 qwen3.7-max 今日发布 DashScope API 已通——开了新路径。**

## 关键新信号（本次对话发现）

- **qwen3.7-max API 可用**：DashScope `qwen3.7-max` 已开通，1500 RMB 资源包内可调，可能是 v5.0.0 stable 的快速胜利路径（纯模型升级 vs prompt 工程）
- **对标段 prompt 工程**：在 D4 上 κ 从 0 跃至 0.655（识别党政语境起作用），但在 D2/D5 上挤压判断空间。说明"对标范例注入"思路对部分维度有效，对核心 D5 contextual judgment 无效

## 4 个待决策路径（产品决策层，必须用户拍板）

| 路径 | 做什么 | 耗时 | 风险/优势 |
|------|--------|------|-----------|
| **A** | git revert prompt + qwen3.7-max 跑 60 段 | ~40 min | 干净变量、今日旗舰、若 PASS 直接 ship |
| **B** | git revert prompt + 接受 baseline ship v5.0-rc1 当 v5.0.0 | ~30 min | 今日肯定能 ship，遵守"尽快"原意；放弃 D5 提升目标 |
| **C** | 缩短对标段 + 反例驱动准则重写 + 重跑 | ~50 min | 第 2 轮仍可能不达标 |
| **D** | A + C 组合 4 路 calibration | 2-3 h | 数据全面但超时 |

**默认推荐 A**（路径理由：今日新发布旗舰是天降信号、cycle 最短、若 PASS 即 ship、若 FAIL 仍可继续走 C 或 B）。

## 必读铁律（top 5）

1. **[[feedback_anthropic_api_policy]]**：永远不通过 Anthropic API 调用 Claude，脚本默认 BYOM Qwen/DeepSeek（本次新增 qwen3.7-max 可用）
2. **[[feedback_no_implementation_choice_questions]]**：实施层多选题 AI 自决，产品决策层（如 4 路径选择）才问用户。本次 4 选 1 属产品决策，必须问
3. **[[inference-vs-verification SKILL]]**：D5 改进必跑 verifier（calibration-runner.sh），禁止只看 prompt diff 推断"应该提升"
4. **spec.md §6 anti-grade-gaming**：D5 发版 gate 79.5% **不可降低**凑 PASS，必须诚实报告 FAIL
5. **GB/T 15834-2011 中文标点**：所有 sediment / handoff / SSOT 用弯引号 `"……"`，禁 ASCII 直引号 / 直角引号

## 已知 blocker / 上游依赖

- **DashScope 1500 RMB 资源包剩余 ≤ 2 天**（2026-05-20 起算 3 天）：路径 A/C/D 必须趁此窗口跑完
- **当前 prompt 是 v5.1 状态**（含对标段，已 push origin）：路径 A/B 启动前必须先 `git show 14a4757:.../llm-judge-research-report.md > .../llm-judge-research-report.md` 或 git revert
- **calibration-results/ 目录当前是 v5.1 结果**：路径 A/B/C 启动前必须 `mv calibration-results calibration-results-v51-qwen36` 防混淆

## 下次对话不要做的事

- ❌ 拿 v5.1 prompt + qwen3.7-max 跑（变量不纯，先 revert prompt 再换模型）
- ❌ 降低 79.5% gate 凑 PASS（违反 spec.md §6 anti-grade-gaming）
- ❌ 改 calibration-set.jsonl / cohen-kappa.py / runner.sh 任何一个（违反 grader 三件套约束）
- ❌ 跑全 173 段做第一次验证（先 60 段 cycle 短，PASS 后再扩 173 段确认）
- ❌ 路径 D（超出"尽快出 v5.0"原意，DashScope 窗口也不够）

## SLI 验证（下次对话冷启动跑）

```bash
cd ~/Workspace/xuan-jiang/plugins/writing-polish/skills/writing-polish

# qwen3.7-max 仍可用
python3 -c "
import os
from openai import OpenAI
c = OpenAI(api_key=os.environ['DASHSCOPE_API_KEY'], base_url='https://dashscope.aliyuncs.com/compatible-mode/v1')
print(c.chat.completions.create(model='qwen3.7-max', messages=[{'role':'user','content':'回答仅一个字：是'}], max_tokens=10).choices[0].message.content)
"

# 看 v5.1 vs baseline 对比（FAIL 证据）
python3 -c "
import json
v51 = json.load(open('evals/calibration-results/cohen_kappa.json'))
v50 = json.load(open('evals/calibration-results-baseline-v50rc1/cohen_kappa.json'))
print('D5 acc: baseline', round(v50['per_dim']['D5']['accuracy']*100,1), '% vs v5.1', round(v51['per_dim']['D5']['accuracy']*100,1), '%')
print('Overall κ:', v50['overall_weighted_kappa'], '→', v51['overall_weighted_kappa'])
"
```

## Sprint 2 收尾决策树（下个对话冷启动用）

```
START
  └─ Q: qwen3.7-max API 仍可用?
       ├─ 是 → 路径 A（默认推荐）
       │      ├─ revert prompt + 切 qwen3.7-max + 跑 60 段
       │      └─ Q: D5 acc ≥ 79.5%?
       │           ├─ 是 → tag v5.0.0 + SKILL.md flag + 沉淀（END：v5.0.0 ship）
       │           └─ 否 → 看路径 B / C 哪个更合算
       │                  ├─ 用户要求快 ship → 路径 B（接受 baseline）
       │                  └─ 用户要求继续迭代 → 路径 C（缩短对标段）
       └─ 否 → 路径 B 或 C（qwen3.6-plus 上跑）
```

## 上下文 token 估算

本次对话结束时估 65-75%。下次对话冷启动加载本 input + handoff 即可，无需读 Sprint 1 所有 commit log。
