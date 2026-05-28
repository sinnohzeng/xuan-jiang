# L3 Reviewer Spawn Template

> Load when：Polish protocol §2.2 step 3 触发 L3 多智能体审校时，主对话按本模板组装 Agent prompt。
> 契约：[../schemas/reviewer-output.schema.json](../schemas/reviewer-output.schema.json)
> 配套：[../references/peer-vs-self-revision.md](../references/peer-vs-self-revision.md) 必读（"他批"语气约束）

---

## 主对话调用方式

L3 触发条件（满足任一）：

- draft 字数 > 2000
- 体裁 ∈ {规范公文 / 调研报告 / 述职报告 / 咨询报告}
- L2 self-judge 任一维度 < 3

满足后，主对话在 **单条消息** 内调 3 个 `Agent` 工具（`subagent_type: general-purpose`），每个 reviewer 专评一维，prompt 用下面 §"Reviewer prompt 模板" 节内容，按 D{X} 替换。

并行原则参考 Anthropic Building Effective Agents §Orchestrator-Workers + Cognition Walden Yan：reviewer 阶段并行（评分相互独立），但修改 draft 阶段必须单线程（见 SKILL.md §4.6）。

---

## Reviewer prompt 模板

> 替换占位符：`{{DIMENSION_ID}}`（D1-D5 之一）、`{{DIMENSION_NAME}}`（如"标点 / 格式"）、`{{DRAFT_TEXT}}`（完整 draft）、`{{CONSTITUTION_SECTION}}`（constitution.md 对应 §D{X} 完整内容）

```
你是 writing-polish v6.0 的独立审稿人。
你 **没有看过** 主对话历史；你只看本 prompt 提供的材料。
你只评 **{{DIMENSION_ID}}（{{DIMENSION_NAME}}）** 一维。

# 输入

## 1. Draft（待评稿）

{{DRAFT_TEXT}}

## 2. 评分细则（references/constitution.md §{{DIMENSION_ID}}）

{{CONSTITUTION_SECTION}}

## 3. 审稿语气约束（references/peer-vs-self-revision.md）

你是在"批改他人稿"。tone 必须：

- 尊重作者意图：先复述作者想表达什么，再指出表达没达成的位置
- 外科手术：指具体行/句，不泛泛而谈"整体偏 AI 味"
- 解释 why：说"违反了什么原则"而不是只说"写得不好"
- 不夸不贬：不要用"作者很有水平"、"写得很烂"、"这种水平也敢交付"等评价人的表述

# 任务

按 0-5 整数为本维度打分，并给出 rationale + 至多 3 条 issues + 至多 3 条 fixes。

如果你在 draft 中读到 "明显 AI 味但 anti-ai-taste-anchors.md 230 条规则未覆盖" 的模式，
将其填入 `rules_not_covered_but_feels_off`（≤3 条，可空），供 v6.1 evolution-queue 学习。

# 输出格式（严格 JSON，无前后缀文本）

{
  "dimension": "{{DIMENSION_ID}}",
  "score": <1-5 整数>,
  "rationale": "<不超 300 中文字>",
  "top_issues": ["<具体行/句>", ...],
  "top_fixes": ["<改成什么>", ...],
  "rules_not_covered_but_feels_off": ["...", ...]
}

# 严禁

- 评 {{DIMENSION_ID}} 之外的维度
- 修改 draft（你只评分 + 提建议，不动笔）
- 在 JSON 外加任何 markdown / 解说 / 代码块标记
- 用 "作为 AI" / "我作为评审" 等元注释起手
- 输出超过 1 个 JSON 对象
```

---

## 主对话端 fail handling

reviewer 返回后，主对话按下表处理：

| reviewer 返回情况 | 主对话动作 |
|---|---|
| 60s 内未返回任何输出 | 记 `missing-vote: D{X}`，本维度跳过 |
| 返回非 JSON 或 JSON schema 校验失败 | 同上：记 missing-vote |
| 返回 score < 0 或 > 5 | 视为 invalid，记 missing-vote |
| 多个 JSON 对象 | 取第一个有效对象，其余丢弃 |
| `top_issues` / `top_fixes` 多于 3 条 | 截断到前 3 条 |
| `rules_not_covered_but_feels_off` 多于 3 条 | 截断到前 3 条 |

汇总策略：D1-D5 五维各取主对话 L2 self-score 与 L3 reviewer score 的 **min**（保守裁判：任一审稿人觉得低，就以低分为准）。
missing-vote 时该维度只用 L2 self-score。

---

## v6.1 evolution-queue 用法预告

所有 reviewer 返回的 `rules_not_covered_but_feels_off` 字段，主对话在 polish session 收尾时合并写入：

- 若用户开启 `--log-to <path>`：append 到 eval-record.jsonl 的 `rules_not_covered_but_feels_off` 字段
- v6.1 evolution-queue 消费这批日志，按出现频次排序后人工评审晋升为新规则
