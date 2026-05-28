# Reviewer Routing — 5 维 × N reviewer 分摊 SSOT

> Load when：SKILL.md §2.2 step 3 主对话决定 spawn 哪几个 reviewer 时。
> automation-level: `claude-code-session-only`（决策表，无脚本消费）。

## §1 决策表（mode × 体裁 × 长度 × L2 状态 → reviewer 列表）

| Polish 触发场景 | spawn reviewer 列表 | prompt 文件 |
|---|---|---|
| **默认（短稿 + 非 4 体裁 + L2 全过）** | D5 spot-check × 1 | `prompts/spot-check.md` |
| draft > 2000 字 | D2 + D3 + D5 | `prompts/reviewer.md` × 3 并行 |
| 体裁 = 规范公文 / 咨询报告 | D1 + D2 + D5 | `prompts/reviewer.md` × 3 并行（D1 标点最优先） |
| 体裁 = 调研报告 / 述职报告 | D2 + D3 + D5 | `prompts/reviewer.md` × 3 并行 |
| L2 任一 score ≥ 2 | 该单维度强制全 reviewer 兜底 | `prompts/reviewer.md` × 1 |
| L2 弃权（trace 文件缺失） | D1 + D2 + D3 + D4 + D5 全维度兜底 | `prompts/reviewer.md` × 5 并行 |

**多触发条件叠加**：取**所有命中条件的 reviewer 列表并集**。例：3500 字咨询报告 → D1+D2+D5（公文规则）∪ D2+D3+D5（长稿） = D1+D2+D3+D5。

## §2 体裁判定锚点（用 ±2 行扩窗）

| 体裁 | 锚点关键词 |
|---|---|
| 规范公文 (G1) | 通知 / 通报 / 决定 / 命令 / 国发 / 函〔20xx〕 / 部署 / 下发 |
| 讲话稿 (G2) | 讲话 / 致辞 / 发言 / 同志们 / 党组 / 干部大会 |
| 调研报告 (G3) | 调研 / 课题 / 现状梳理 / 数据采集 / 问卷 |
| 述职报告 (G4) | 述职 / 任期 / 个人工作总结 / 政绩 |
| 汇报发言稿 (G5) | 汇报 / 向上级 / 第三方 / 通报情况 |
| 随笔杂文 (G6) | 个人观点 / 思辨 / 评论 / 短论 |
| 自媒体 (G7) | 公众号 / 知乎 / 小红书 / 推文 / 流量 |
| 咨询报告 (G8) | 咨询 / 实施方案 / 对照启示 / 甲方 / 第三方机构 / 协会 |

无法判定 → fallback 到 G6 随笔（轻规则集），并在用户可见区追加一行 `[体裁判定失败，按 G6 处理]`。

## §3 reviewer 并行上限

单次 Polish session 同时最多 **5 个 reviewer**（D1-D5 各 1）。即使多触发条件叠加导致并集超 5，也按维度去重；同维度多触发只 spawn 1 个。

## §4 进度可见性

主对话每次确定 reviewer 列表后，spawn 前必输出一行：

```
[L3 routing] genre=G8咨询 / len=3500字 / L2=D3(2) → spawn: D1 + D2 + D3 + D5 (4 reviewers)
```

让用户在 reviewer 跑前就看到分摊结果，便于早期 Ctrl+C 调整。
