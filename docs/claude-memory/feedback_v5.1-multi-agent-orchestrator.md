---
name: v5.1-multi-agent-orchestrator-design
description: v5.1.0 多智能体审校重构经验：从 5 个 placeholder 模板大刀阔斧砍成单一 orchestration-guide.md 判断指南；4 视角 Plan Review 落地 + 灰度上线 + DDD SSOT 同步
metadata:
  type: feedback
---

# v5.1 多智能体 orchestrator-workers 实装经验

> 2026-05-27 v5.0.0 ship 当日晚间紧接 v5.1.0 大刀阔斧重构，从 placeholder 范式转向"主智能体自主判断"范式。

## 核心范式认知（写给未来的设计者）

### 范式 1：placeholder 模板 vs 判断指南——选后者

**反模式（v5.0）**：写一堆带 `{{X}}` 占位符的模板让主对话 fill placeholder。这把主对话降级为机械执行机器人，违背 LLM 智能。

**正模式（v5.1）**：写"教主对话如何思考"的判断指南，让主对话根据任务特征自主决定 K 值（reviewer 数）/ 视角组合 / 触发条件 / 收敛阈值。

**来源**：Anthropic Multi-Agent System 2025-06 论文核心精神 "teach orchestrator how to delegate"。

**Why**: placeholder 范式让用户/Claude 每次手工 fill 7+ 占位符，易漏 + 易错 + 失去"主智能体自主判断"价值。指南范式利用 LLM 真实能力。

**How to apply**: 凡是要 spawn subagent 的场景，第一选择是写"何时启 / 派几个 / 视角组合 / 调用语法 / 收敛逻辑"的判断指南，**不**写 prompt template + placeholder。

### 范式 2：Anthropic 6 范式 + Context Engineering 4 技巧 = 11/11 全覆盖才算合格

设计任何多智能体 / agentic 工作流时按 11 个范式 / 技巧 self-check：

- Anthropic 6 范式：Augmented LLM / Chaining / Routing / Parallelization / Orchestrator-Workers / Evaluator-Optimizer
- Context Engineering 4 技巧：Compaction / Note-Taking / Sub-Agent / Just-in-Time
- Cognition 单线程：1 个 writer + N 个 reviewer，reviewer 不写文件只返回 JSON

**Why**: 跑完 11 个 self-check 后能发现自己漏掉的范式（如 Context Budget 自检 / Note-Taking jsonl 记录 / clean-context 单线程原则）。

**How to apply**: 写 RFC / Plan 时**强制**列出 11 个范式覆盖表，每个范式标注落地点。缺哪条就思考是不是过度简化 / 过度工程。

### 范式 3：模型路由 = Opus lead + Sonnet workers（成本 + 质量平衡）

```
主对话 orchestrator      = Opus 4.7 1M
重型评审 Pre-mod / R2    = Opus 4.7 1M（1 路）
轻型并行评审 R1 多视角   = Sonnet 4.6 1M（3-5 路）
```

**Why**: Anthropic Multi-Agent System 2025-06 论文实测 Opus 4 lead + Sonnet 4 subagents 性能提升 90.2%，token 成本上升 15× 在长稿审校场景值得。Sonnet 4.6 默认 1M context（2026-05-27 firecrawl 实测 Anthropic docs verified）。

**How to apply**: 模型路由真值源放 `config/default.yaml`，未来换 Haiku / Gemini / DeepSeek 改 config 即可，指南本身不动。

### 范式 4：calibration 真实反例直接落 few-shot

**反模式**：手工编 few-shot example，靠想象覆盖各种 D 维。

**正模式**：从 calibration disagreement.md 真实反例直接提炼 example。v5.1 8 个新 example 都来自 v5.0-rc1 calibration 18 个 disagreement，**100% 命中真实痛点**。

**Why**: judge prompt 的 few-shot 必须基于真实失败案例，不能臆造。臆造的 few-shot 不能解决真实 disagreement。

**How to apply**: prompt 改进 = 先看 calibration disagreement → 提炼最高代表性反例 → 加进 example pool → 重新 calibration → 重复。

### 范式 5：SKILL.md 是路由 + 决策树，不是知识库

**反模式（v5.0）**：SKILL.md 344 行混杂 DOCX 处理 + 写作方法论 + 三层架构 + 修改哲学 + 文体路由，与 references/ 大量重复。

**正模式（v5.1）**：SKILL.md 90 行，只保留：触发决策树 + 3 mode 路径 + 三层架构概览表 + 红线 4 铁律速查 + references 路由表 + 修改哲学一句话 + 输出格式表。

**Why**: Anthropic Progressive Disclosure：Metadata (~100 tokens) → SKILL.md (<5k tokens) → Resources/Code（无上限）。SKILL.md 主要服务于"决定加载哪个 reference"，不是装知识。

**How to apply**: 任何 SKILL.md 写完后跑 `wc -l`，> 200 行立即审视哪些可外迁到 references/。

### 范式 6：灰度上线 + 不卡 release gate

**反模式**：严苛的 acceptance gate（"必须真跑通 X" / "必须 κ ≥ Y"）阻塞发版。

**正模式**：用户已明确"项目始终处于开发阶段，不卡测试 gate"。灰度三档（alpha / beta / stable）按使用风险分级，问题进 v5.1.x patch backlog。

**Why**: 开发期 SKILL 过度严苛的 release gate 拖慢迭代节奏。真实 bug 在用户任务里暴露更快，dogfood 是最高质量信号。

**How to apply**: 任何 v5.x patch / v5.x.x patch 默认走灰度上线，**不**设 acceptance 硬标准。问题反馈通道是用户口头说"这块不对" → Claude 起 patch。

## 工作流经验（写给未来的执行者）

### 4 视角 Plan Review 是值得的（避免过度工程 + 补漏）

用户 2026-05-27 明确要求"对计划做一轮严格评审，UX / 工程化 / 软件架构 / 技能设计 4 视角对照 2026-05 行业最新惯例和最佳实践，所有发现直接迭代回计划本身"。

实测 4 视角 + 过度工程审查共发现 16 个 finding（A1-A3 / B1-B4 / C1-C5 / D1-D4 / E1-E3），全部直接合并入 plan v2 主体。

**Why**: Plan v1 必有盲区。4 视角强制扫一遍能找出"主对话忘记考虑的边界 case"（如 fallback / context budget / progressive disclosure）。

**How to apply**: 任何 Plan v1 写完后必跑 4 视角 Plan Review（`plan-review-auto` skill），所有 finding **直接迭代回 plan 主体**，不留 TODO / 不分优先级。同时记录"过度工程审查"段，主动收缩 schema 字段数 / 取消重复文档 / 合并 P-N。

### DDD SSOT 同步是发版前提

用户 2026-05-27 明确："按文档驱动开发 DDD 与 唯一真值 SSOT 原则推进 ... 编码同时同步更新所有受影响的项目文档"。

v5.1 必须同步 11 处文档：
- CHANGELOG.md（v5.1.0 段）
- README.md（顶部 v5.1 现状段 + v5.0 预告段删除）
- plugins/writing-polish/.claude-plugin/plugin.json（version + description + keywords）
- .claude-plugin/marketplace.json（version + description + keywords）
- docs/handoff/active.md（symlink 指向 v5.1 handoff）
- docs/handoff/20260527-v5.1-multi-agent-implementation.md（新增）
- docs/rfc/v5.1-multi-agent-orchestrator.md（新增）
- evals/README.md（v5.1 L3 段）
- SKILL.md（瘦身 + 3 mode 路径）
- prompts/llm-judge-research-report.md（few-shot 同步）
- references/constitution.md（§5 Example G-N + §6.1 §6.2 雷达 + §2.8 §1.8.6 红线）

**Why**: 文档与代码漂移是技术债的源头。v5.0 ship 时 README.md 还停留在 "v5.0 范式预告" 即是反例。

**How to apply**: 任何 SKILL 改动同时改动**所有受影响**的文档：CHANGELOG + README + plugin/marketplace.json + handoff + RFC + 长期记忆。一次性 commit 全推送。

## 数字 metrics

| 指标 | v5.0.0 | v5.1.0 | Δ |
|---|---|---|---|
| SKILL.md 行数 | 344 | 90 | -254 |
| prompts/multi-agent/ 文件数 | 5 | 1 | -4 |
| prompts/multi-agent/ 行数 | 499 | 196 | -303 |
| constitution.md Example 数 | 6 | 14 | +8 |
| constitution.md 行数 | 377 | 503 | +126 |
| judge prompt 行数 | 306 | 413 | +107 |
| 新增文档（walkthrough / handoff / RFC / feedback） | — | 4 | +4 |

净改动：**-451 行（placeholder + SKILL 瘦身）+ +519 行（new orchestration-guide + walkthrough + 8 examples + 雷达 + 文档同步）= +68 行有效信息密度提升**。

## 关键 commit 与 ship 链路

- v5.0.0 commit `d755ed6` Merge v5.0-rc1 → main: ship v5.0.0
- v5.1.0 commit `<pending>` v5.1 大刀阔斧重构
- v5.1.0 tag `v5.1.0`
- xuan-jiang plugin marketplace update（通过 `claude plugin marketplace update xuan-jiang` 拉新版）

## 待后续 patch 处理

参见 [../handoff/20260527-v5.1-multi-agent-implementation.md](../handoff/20260527-v5.1-multi-agent-implementation.md) §"后续 v5.1.x patch backlog"。
