# Reviewer Routing：焦点覆盖按长度/体裁分摊 SSOT

> Load when：SKILL.md §2.2 step 2 主对话决定 spawn 几个 writing-reviewer、各自分哪些焦点时。
> automation-level: `claude-code-session-only`（决策表，无脚本消费）。
> v7.0 起：reviewer 返回自然语言反馈 + verdict（不打数值分）；路由按“焦点覆盖”而非“5 维打分”分摊。

## §1 决策表（mode × 体裁 × 长度 → reviewer 数与焦点）

四个审查焦点：`立意` / `结构与论据` / `材料·事实` / `AI味·标点`（定义见 [`constitution.md`](constitution.md) §0 + §0.5）。

| Polish 场景 | reviewer 数 | 焦点分摊 |
|---|---|---|
| **短稿 < 500 字** | 0 | 走 Audit 即可，spawn reviewer 不划算 |
| **标准 500-3000 字，非重体裁** | 1 | 单 reviewer 全焦点（立意+结构+材料+AI味标点），速度优先 |
| **长稿 > 3000 字** 或 体裁 ∈ {规范公文 G1 / 调研报告 G3 / 述职报告 G4 / 咨询报告 G8} | 2-3 并行 | A=立意+结构与论据；B=材料·事实；C=AI味+标点（公文/咨询 C 优先级最高） |
| **L1 红线未清（scan fail）** | +1 | 专跑 AI味+标点 焦点，确认语境豁免（防火墙/对标等 ±2 行白名单） |

**多条件叠加**：取所有命中场景的焦点并集，去重；同焦点多次命中只 spawn 1 个 reviewer。

**并发上限 3**（旧版 v6 是 5：彼时一维一 reviewer；v7 焦点比维度宽，3 个即可全覆盖四焦点）。

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

## §3 进度可见性

主对话确定 reviewer 列表后，spawn 前必输出一行：

```
[reviewer routing] genre=G8咨询 / len=3500字 → 3 reviewers: 立意结构 / 材料事实 / AI味标点
```

让用户在 reviewer 跑前看到分摊结果，便于早期 Ctrl+C 调整。

## §4 spawn 与 fail handling

- 用 Task 工具 spawn [`../../agents/writing-reviewer.md`](../../agents/writing-reviewer.md)，任务 prompt 注入：draft 全文 + 该 reviewer 的 focus 列表 + `constitution.md` 对应体裁切片 + 当前日期 + 项目豁免清单（§3/§4 cicpa 例外）。
- 每 spawn 一行可见 `[spawn writing-reviewer focus=立意+结构]`；返回时 `[verdict=要改 ✓]`。
- 失败 retry **1 次**（2s 退避）；2 次仍失败记 `missing-review: focus=<X>`（不静默降级 = fix-the-tool-don't-fallback）。
- reviewer 返回 `<feedback>`（按焦点分组）+ `<verdict>够好了|要改|红线未清</verdict>`；主对话据 verdict 决定是否再走一轮 step 3（红线未清 / 实质类“要改”才再修）。
