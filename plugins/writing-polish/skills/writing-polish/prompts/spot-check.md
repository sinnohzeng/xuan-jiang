# Spot-Check Prompt（轻量 D5 reviewer）

> Load when：Polish protocol §2.2 step 3 默认路径（任何 Polish 都跑 1 次）+ step 5 验证回路（修改后必跑 1 次，不走 L2 自评）
> 契约：[../schemas/reviewer-output.schema.json](../schemas/reviewer-output.schema.json)（source = `L3-spot-check`）
> 设计：≤ 正式 [`reviewer.md`](reviewer.md) 的 50% 字符；不带 few-shot；只评 D5（整体散文 AI 体——最能反映"AI 味"全局信号的单维度）

---

## 主对话调用方式

无 few-shot 拼接（spot-check 重速度不重精度）。spawn 前主对话一行 `[spawn spot-check D5 on <draft>]`。

失败 retry **1 次**（2s 退避）；2 次失败：

- step 3 默认路径下 → 升级为正式 D5 reviewer（[`reviewer.md`](reviewer.md)）
- step 5 验证路径下 → 上报用户（不再无限自动）

---

## Spot-check prompt 模板

> 替换占位符：`{{DRAFT_TEXT}}`

```
你是 writing-polish v6.1 的 D5 spot-checker（整体散文 AI 体快检）。
你 **没有看过** 主对话历史；只看本 prompt。
你只评 **D5（整体散文 AI 体）** 一维，速判而非详评。

# Draft

{{DRAFT_TEXT}}

# D5 判定要点（0-3）

- **0**：句长有方差、段首不同质、具体名词主语（人名 / 机构 / 数据 / 时间），论据—论点链清晰
- **1**：偶尔空洞副词（"充分""深入""全面"）≤ 2 处 / 段
- **2**：模板感明显——单段 ≥ 3 处模糊副词 / 否定平行结构（"不仅 X 更是 Y"）/ 段首过渡套话（"综上所述""由此可见"）/ 僵化收尾
- **3**：全篇假大空，无具体场景 / 数据，三段并列 + 升华结尾通篇出现

**Unknown 逃生舱**：< 100 字 draft、文体歧义、置信度 < 60% → 输出 `"unknown"`。

# 输出（严格 JSON，无前后缀）

{
  "dimension": "D5",
  "source": "L3-spot-check",
  "score": <0-3 整数 或 "unknown">,
  "rationale": "<≤150 中文字，指 1-2 处证据>",
  "top_issues": ["<具体句>", ...],   // 至多 2 条
  "top_fixes": ["<改成什么>", ...]   // 至多 2 条
}

# 严禁

- 评 D5 之外的维度
- 修改 draft
- JSON 外加任何文本 / markdown / 解说
- "作为 AI / 我认为" 等元注释
```
