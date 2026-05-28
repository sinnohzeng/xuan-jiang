# L3 Reviewer Spawn Template

> Load when：Polish protocol §2.2 step 3 触发 L3 多智能体审校时，主对话按本模板组装 Agent prompt。
> 契约：[../schemas/reviewer-output.schema.json](../schemas/reviewer-output.schema.json)（v6.1: 0-3 量纲 + source 枚举 + unknown 合法）
> 配套：[../references/peer-vs-self-revision.md](../references/peer-vs-self-revision.md)（"他批"语气）+ [../references/reviewer-routing.md](../references/reviewer-routing.md)（5 维→N reviewer 分摊）

---

## 主对话调用方式

### 默认与升级条件（SSOT 在 reviewer-routing.md，本节是 cached mirror）

| 触发条件 | 分摊 |
|---|---|
| Polish mode 默认 | **D5 spot-check × 1**（用 [`spot-check.md`](spot-check.md)，本文件适用 D2/D3/D5 全 reviewer） |
| draft > 2000 字 / 体裁 ∈ {规范公文/调研报告/述职报告/咨询报告} / L2 任一 ≥ 2 / L2 弃权（trace 缺） | **D2 + D3 + D5 三 reviewer 并行** |
| 体裁 = 规范公文 / 咨询报告 | **D1 + D2 + D5 三 reviewer**（标点最优先） |
| L2 任一维度 score ≥ 2 | 该维度强制全 reviewer（本模板）兜底 |

并行原则参考 Anthropic Building Effective Agents §Orchestrator-Workers + Cognition Walden Yan：reviewer 阶段并行（评分相互独立），但修改 draft 阶段必须单线程（见 SKILL.md §4.5）。

### Spawn 前置：拼 few-shot 校准锚

主对话在 spawn 前必跑：

```bash
bash scripts/select-fewshot.sh <draft-path> <dimension>
# stdout: 2 行 jsonl（1 易 1 难，按 score 分层 + sha256(draft) deterministic + 同 source_commit 排除）
```

将 stdout 注入 prompt §4。

### 进度透明 + retry

- 每 spawn 一个 reviewer 主对话立刻输出一行用户可见：`[spawn reviewer-D{X} (source_commit excluded: <短sha>)]`
- 返回时：`[D{X} score=<n>|unknown ✓]`（fail-fast 可见）
- 失败 retry **1 次**，退避 2s；2 次仍失败才记 `missing-vote: D{X}`（非默默降级 = fix-the-tool-don't-fallback）

---

## Reviewer prompt 模板

> 替换占位符：`{{DIMENSION_ID}}`（D1-D5 之一）、`{{DIMENSION_NAME}}`（如"标点 / 格式"）、`{{DRAFT_TEXT}}`（完整 draft）、`{{CONSTITUTION_SECTION}}`（constitution.md 对应 §D{X} 完整内容）、`{{FEWSHOT_ANCHORS}}`（select-fewshot.sh 输出的 2 行）

```
你是 writing-polish v6.1 的独立审稿人。
你 **没有看过** 主对话历史；你只看本 prompt 提供的材料。
你只评 **{{DIMENSION_ID}}（{{DIMENSION_NAME}}）** 一维。

# 输入

## 1. Draft（待评稿）

{{DRAFT_TEXT}}

## 2. 评分细则（references/constitution.md §{{DIMENSION_ID}}）

{{CONSTITUTION_SECTION}}

## 3. 审稿语气约束（references/peer-vs-self-revision.md）

你在"批改他人稿"。tone 必须：

- 尊重作者意图：先复述作者想表达什么，再指出表达没达成的位置
- 外科手术：指具体行/句，不泛泛而谈"整体偏 AI 味"
- 解释 why：说"违反了什么原则"而不是只说"写得不好"
- 不夸不贬：不用"作者很有水平"、"写得很烂"、"这种水平也敢交付"等评价人的表述

## 4. 校准锚（仅供量纲参考，不是改稿模板）

下面 2 条 verified 样本展示本维度 0-3 量纲的 anchor 标准：

{{FEWSHOT_ANCHORS}}

**严禁**：把锚里的句子复制进 top_fixes；只用它们校准你对 0/1/2/3 边界的判断。

# 任务

按 0-3 整数为本维度打分（证据不足输出 "unknown"——Unknown 逃生舱），并给出 rationale + 至多 3 条 issues + 至多 3 条 fixes。

如果你在 draft 中读到 "明显 AI 味但 anti-ai-taste-anchors.md 230 条规则未覆盖" 的模式，
填入 `rules_not_covered_but_feels_off`（≤ 3 条，可空），供 v6.2 evolution-queue 学习。

# 输出格式（严格 JSON，无前后缀文本）

{
  "dimension": "{{DIMENSION_ID}}",
  "source": "L3-reviewer-clean",
  "score": <0-3 整数 或 "unknown">,
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
- 把 §4 校准锚的句子复制进 top_fixes
```

---

## 主对话端 fail handling

| reviewer 返回情况 | 主对话动作 |
|---|---|
| 60s 内未返回 | retry 1 次（2s 退避） |
| retry 后仍未返回 | 记 `missing-vote: D{X}`，本维度只用 L2_score |
| 返回非 JSON / schema 校验失败 | 视为 invalid，同 missing-vote |
| score 不在 [0,3] ∪ {"unknown"} | 视为 invalid，同上 |
| `source` 字段不是 `L3-reviewer-clean` | 视为 invalid（reviewer 串台），同上 |
| 多个 JSON 对象 | 取第一个有效对象，其余丢弃 |
| `top_issues` / `top_fixes` 多于 3 条 | 截断到前 3 条 |

**汇总策略**：D{X} 取主对话 L2_score（读 `.writing-polish-trace/`）与所有 L3_score(D{X}) 的 **max**（0-3 量纲下"更差的为准"= 保守裁判）。missing-vote 时只用 L2_score；L2 弃权（trace 缺）+ L3 missing-vote 同时发生 → 该维度标 `"unknown"` 并上报用户。

---

## v6.2 evolution-queue 用法预告

所有 reviewer 返回的 `rules_not_covered_but_feels_off`，主对话在 polish session 收尾时合并写入：

- 若用户开启 `--log-to <path>`：append 到 eval-record.jsonl 的 `rules_not_covered_but_feels_off`
- v6.2 evolution-queue 消费这批日志，按频次排序后人工评审晋升为新规则
