# Pre-modification 动笔前方案审议

> Layer 3 第三种触发（与 R1 / R2 并列，非串行）：**重大改稿前**，主对话先写改稿草案 + 改动 rationale，spawn 1 个 subagent 审议方案合理性，再决定是否动手。预防"改了一大堆但方向错了"。

## 何时触发 Pre-modification

| 应触发 | 不必触发 |
|---|---|
| 用户说"重写第三章 / 大幅调整 / 结构重建" | 单段轻度润色 |
| 主对话准备改 ≥ 30% 段落 | 改 < 10% 段落 |
| 文体识别有歧义（"既像述职又像汇报"） | 文体清晰 |
| 修改方向涉及"客户敏感 / 厂商背书 / 政策引用" | 纯文风改写 |
| 用户已对 Layer 2 输出连退 2 次 | 用户接受 L2 输出 |

## 主对话调用范式

```
Agent(
  subagent_type="general-purpose",
  description="Pre-mod 方案审议",
  prompt=<本模板填好 placeholder + 改稿草案 + rationale>
)
```

**单个** subagent，独立审议。subagent 不动笔改稿，只评议方案。

## Pre-mod 任务 prompt 模板

```markdown
# 任务：动笔前方案审议

## 1. 角色

你是 **资深咨询项目总监**（背景：{{ROLE_BG}}），擅长在团队动笔前
对改稿方案做"成本-收益-风险"快速评估。clean context。

## 2. 路径

- **原稿**：`{{ORIGINAL_FILE_PATH}}`
- **改稿草案**：`{{DRAFT_FILE_PATH}}`（主对话已写好）
- **SSOT 红线**：`references/anti-ai-taste-anchors.md` + `references/revision-checklist.md`
- **甲方背景**（如有）：`{{CLIENT_CONTEXT_PATH}}`

## 3. 维度

**仅审议方案合理性，不审稿**。具体评估三个维度：

- **方向**：改稿草案的总体方向（重组结构 / 全文重写 / 调标题…）是否对得上
  - 用户诉求
  - 文体规约
  - 甲方关注点
- **代价**：改动 N% 段落的工程量与风险是否值得
  - 误伤"已经合规的好段"风险
  - 修订模式 track-changes 给客户看时的可读性
  - 是否触发新一轮 R1 / R2
- **替代路径**：有没有更小代价的方案能达到同样效果
  - 例：原本想"全文重写"，发现只改前两章 + 末段就够了
  - 例：原本想"调标题"，发现保留标题加副标题更尊重原作

## 4. 约束

- 你**不**动笔改稿，只产出审议报告
- 报告里**不**给具体改写建议（那是 R1 / R2 的事）
- 不批评主对话的草案，只指出"方向 / 代价 / 替代路径"中的疏漏
- 必须给明确结论：**绿灯 / 黄灯 / 红灯**

## 5. 输出格式

```json
{
  "verdict": "GREEN|YELLOW|RED",
  "verdict_one_liner": "≤ 30 字",
  "direction_assessment": {
    "aligned_with_user_intent": true,
    "aligned_with_genre": true,
    "aligned_with_client_concern": true,
    "notes": "≤ 80 字"
  },
  "cost_assessment": {
    "estimated_segments_changed_pct": 35,
    "risk_of_collateral_damage": "LOW|MEDIUM|HIGH",
    "client_readability_in_track_changes": "OK|HARD",
    "notes": "≤ 80 字"
  },
  "alternatives": [
    {
      "id": "ALT1",
      "scope_reduction": "只改前两章 + 末段",
      "rationale": "≤ 50 字"
    }
  ],
  "recommendation": "≤ 100 字"
}
```

## 6. 输出上限

- alternatives ≤ 3
- recommendation ≤ 100 字
- 整体 JSON ≤ 600 字

## 7. Clean Context 铁律

你没有主对话上下文，对 §2 路径下的文档之外的事情一无所知。
"用户诉求"由本 prompt §3 描述告诉你，不要猜。
```

## 派 Pre-mod 后主对话的下一步

按 verdict：
- **GREEN** → 按草案动手，跑完 L1 + L2 即可，无需 R1 / R2
- **YELLOW** → 按 `alternatives` 调整草案后再动手，可触发 R1
- **RED** → 停手，回到与用户对齐阶段（改稿方向有结构性问题）

绿灯 + 改动 ≥ 30% 仍建议补 R1 + R2 兜底。
