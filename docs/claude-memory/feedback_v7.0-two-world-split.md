---
name: feedback_v7.0-two-world-split
description: v7.0 决策——写作评价拆两世界（per-use 自然语言反馈 + 离线数值评分），为何删 per-use 评分链，补任仲然立文实质轴
metadata:
  type: feedback
---

# v7.0 两世界拆分：评分链放错了层

**决策**：写作评价拆两个世界。per-use 热路径（每次改稿）= clean-context reviewer 返回**自然语言可执行反馈 + 粗判**（够好了/要改/红线未清）；数值逐维评分整体下沉 `evals/offline-harness/` 离线 dev-eval。同时补齐任仲然「立文实质」正向轴（立意/结构与论据/材料·事实），表达为 reviewer 焦点 + Coach checkpoint，**不是** W1-W5 数值。

**Why**：用户直觉「评分链跑偏了」是对的。firecrawl 实测全行业（Self-Refine / Reflexion / CRITIC / Constitutional-AI / Anthropic evaluator-optimizer cookbook）的**改稿循环都用自然语言反馈 + PASS/NEEDS_IMPROVEMENT/FAIL 粗判**；数值逐维打分（G-Eval / Prometheus / MT-Bench / AlpacaEval）是**离线给模型排名**的工具。v6 把离线打榜的做法（0-3 逐维矩阵 + `.writing-polish-trace` 文件 + max 汇总 + κ）搬进了每次改稿热路径——全行业没人这么做，且 Anthropic「最简方案 / grade outcome not path」明确反对。铁证：`anchor-set.jsonl` 空了半年没人发现（根因是 calibration 173 条全 `verified:false`），证明那条数值链根本不承重。另：v6 的 rubric 全是 D1-D5 防 AI 味的负向检测，Anthropic 2026-01「单边评测导致单边优化」——任仲然真正重视的立意/材料/结构从未进评价，故 v7.0 补正向轴。

**How to apply**：
- 改 SKILL 评价机制时，先分清「让这一篇变好」（→ NL 反馈，热路径）还是「衡量 polisher 好不好」（→ 数值，离线）。别再把数值打分塞进 per-use。
- reviewer 是 clean-context 子代理（`agents/writing-reviewer.md`，只读工具结构性强制「只评不改」），输出 `<feedback>` + `<verdict>`，禁数值/JSON/逐维矩阵。
- 补评价轴时优先正向实质（写得好不好），不要只堆负向黑名单词。
- 离线 eval 加 anchor 数据时要标 `verified:true` 并加非空 guard，否则静默空无人知。
- 关联 [[feedback_v4.3-context-whitelist]]（过度工程边界、LLM-as-judge 路线图的前身）、[[feedback_auto-commit-push]]。
