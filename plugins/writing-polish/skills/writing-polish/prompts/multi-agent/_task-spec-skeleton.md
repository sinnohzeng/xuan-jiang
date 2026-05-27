# 评审任务书骨架（六要素）

> 派多智能体审稿 / 评议 / 反查时的统一任务书模板。源自中注协（cicpa）项目多智能体审校 SOP，已升格为 writing-polish v5 通用范式。所有 `prompts/multi-agent/*.md` 模板内嵌此骨架。

## 六要素清单

任何派给 clean-context subagent 的任务必须显式包含全部 6 个字段，缺一不发：

| 字段 | 必填内容 | 反例（不要写） |
|---|---|---|
| **1. 角色** | "你是 X 领域的 senior 评审员，背景 Y" | "你是助手" / 空 |
| **2. 路径** | 待审文档**绝对路径** + 关联 SSOT 路径 | "看一下这个文件" / 相对路径 |
| **3. 维度** | 本 agent 负责的**单一**评审视角（不重叠） | "全面审一遍" / 多视角混合 |
| **4. 约束** | 红线 / SSOT 引用 / 例外清单（项目豁免） | "按你的标准" / 空 |
| **5. 输出格式** | JSON / markdown table / finding list 三选一 + 字段 schema | "随便写写" / 自由文本 |
| **6. 输出上限** | finding 条数 ≤ N + 每条字数 ≤ M | 无上限 → subagent 会写小论文 |

## 模板（套用 placeholder）

```markdown
# 任务：{{TASK_NAME}}

## 1. 角色

你是 **{{ROLE_TITLE}}**，{{ROLE_BACKGROUND_ONE_LINE}}。

## 2. 路径

- **待审文档**：`{{ABSOLUTE_FILE_PATH}}`
- **SSOT 红线**：`{{RED_LINE_REFERENCE_PATH}}`（必读）
- **项目豁免**（如有）：`{{PROJECT_EXEMPTIONS_PATH}}`
- **文体范例**（如有）：`{{ANCHOR_ESSAYS_DIR}}`

## 3. 维度

本轮你**仅且必须**关注：**{{SINGLE_DIMENSION}}**

下列维度**不归你管**（其他 subagent 在审），不要顺手挑：
{{OTHER_DIMENSIONS_LIST}}

## 4. 约束

- 所有 finding 必须援引 SSOT 行号 / anchors 编号，无 SSOT 锚点的"个人审美"不接受
- 项目豁免清单中的情况**禁止报警**
- 不下结论 / 不批评作者 / 不命令式（"应该 / 必须" → "建议 / 可以考虑"）
- 不引用本对话外的训练记忆，只引用 §2 路径中的 SSOT

## 5. 输出格式

严格 JSON：

```json
{
  "agent_role": "{{ROLE_TITLE}}",
  "dimension": "{{SINGLE_DIMENSION}}",
  "findings": [
    {
      "id": "F1",
      "line_range": "L42-L45",
      "severity": "P0|P1|P2|P3|P4|P5",
      "ssot_anchor": "anti-ai-taste-anchors.md §1.5.1",
      "violation_quote": "原文片段（≤ 50 字）",
      "issue": "一句话说清违反了什么（≤ 30 字）",
      "suggestion": "改写建议（≤ 80 字）"
    }
  ],
  "summary": "本轮整体判断（≤ 100 字）"
}
```

## 6. 输出上限

- finding 条数 **≤ {{MAX_FINDINGS}}**（超出按 severity 取头部 N 条）
- 每条字段长度严格 ≤ 5. 中标注上限
- summary ≤ 100 字
- 若维度内无 finding，输出 `findings: []` + `summary: "本维度无问题"`，**不**编造

## 7. Clean Context 铁律（Cognition 2026-04 范式）

你**没有**主对话的上下文，**不知道**:
- 用户是谁 / 项目背景 / 之前改了什么
- R1 其他 subagent 怎么评的（你看不到他们）
- 主对话已采纳哪些 finding

你的工作就是**从 §2 路径冷启动反推 spec**，按 §3 维度评一遍。这是 feature 不是 bug：
> Devin 实证此范式每 PR 多抓 2 个 bug，58% severe（见全局 clean-context-code-review skill）

不要试图"猜上下文"或"配合主对话"，独立判断即可。
