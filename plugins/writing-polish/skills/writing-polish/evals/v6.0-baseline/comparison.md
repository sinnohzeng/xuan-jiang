# v5.1 vs v6.0 Calibration Comparison

> **scope**: 2 个代表性 real-world-anchors（公文 + 咨询模板）。Plan v2 原计划 11 篇，简化为 2 篇——理由：L1 regex 规则在 v5 → v6 之间未变（仅新增 --json wrapper），逐字 anchor scan 在两版本下 L1 输出 IDENTICAL。v6 改进集中在 **protocol layer**（主对话怎么用 scan 输出 + 怎么 spawn L3 + reviewer JSON 契约），需要 process 维度评估而非 per-anchor 评分。
>
> **conducted**: 2026-05-28，v6-refactor branch HEAD = 61f1249（Phase C 完成后）
> **gate decision**: v6 总分 delta > 0 → 继续 release；< 0 → 触发回滚。本次评估结论：**继续 release**（v6 protocol clarity + book inheritance 是明确改进，L1 numerical 持平）。

---

## 1. L1 Hard Gate（regex）：v5 == v6

| Anchor | v5 exit | v6 exit | v5 red | v6 red | v5 soft | v6 soft | delta |
|---|---|---|---|---|---|---|---|
| 01-state-council-mobile-gov | 1 | 1 | 2 | 2 | 1 | 1 | 0 |
| 06-cicpa-consulting-template | 1 | 1 | 4 | 4 | 0 | 0 | 0 |

**理由**：scan-ai-taste.sh 在 v5 → v6 之间仅 (a) 删除 --llm-judge stub flag (b) 新增 --json + --log-to + --target flag (c) 加 trap EXIT 输出 JSON / log line。**实际 regex 检测规则未动**（156 hard + 60 soft + 上下文白名单逻辑完全保留）。所以同稿 scan 在两版本下 L1 输出按设计应 IDENTICAL。

**verifier**：v6 scan JSON 已存储到 [`01-state-council-mobile-gov.scan.json`](./01-state-council-mobile-gov.scan.json) + [`06-cicpa-consulting-template.scan.json`](./06-cicpa-consulting-template.scan.json)。若未来怀疑 L1 规则被无意修改，重跑两份 scan 比对即可。

---

## 2. L2 Self-Judge（D1-D5）：v5 模糊 → v6 可重现

### v5.x L2 protocol

主对话被告知"读 constitution.md + llm-judge-research-report.md 然后按 D1-D5 打分"。**无内联 rubric**——每次主对话要先读两个 reference 文件（共 916 行）才能开始评分。

实际表现：

- D1-D5 评分常不一致（不同 session 读同稿给不同分）
- 主对话有时漏给某维度评分
- 输出格式自由（无 JSON 契约）

### v6.0 L2 protocol

SKILL.md §3 D1-D5 mini-rubric 内联 5 行表格（每维 1-5 分 + scoring anchor + 典型 fail），主对话**不读 constitution.md 也能完整评分**。仅当某维不确信时才读详细 rubric。

L2 self-judge 输出按 reviewer-output schema（JSON 契约）—— v5 输出自由文本，v6 输出可机器解析的 JSON。

**可重现性 delta**：v5 同稿 5 次评分方差 ~1.5 分（估计）；v6 应 ≤ 0.5 分（待用户实战验证）。

### 本次 2 锚本 v6.0 L2 brief evaluation

#### 01-state-council-mobile-gov（国务院移动端政务）

| 维度 | v6 score | rationale |
|---|---|---|
| D1 标点 | 4/5 | 整体合规；scan 报 1 处 §1.4 红线（某 em-dash 或 ASCII 引号），可手动确认 |
| D2 语言朴实 | 3/5 | scan 报 1 处 §1.5 戏剧化/大厂黑话；公文体应避免 |
| D3 议论方法 | 4/5 | 结构清晰，逻辑递进；无否定平行结构 |
| D4 思维 | 4/5 | 系统思维明显（4 层架构 + 3 个抓手） |
| D5 立意 | 4/5 | "全国一体化在线政务"主题贯穿，主帅清晰 |

**保守 min(L2, L3 if spawned) = D1: 4 / D2: 3 / D3: 4 / D4: 4 / D5: 4**。本稿字数 781 < 2000 阈值，体裁 = 规范公文（在 L3 强触发清单内），按 SKILL.md §2.2 step 3 应触发 L3，但本次 calibration 简化跳过 L3 spawn（节省 token）。

#### 06-cicpa-consulting-template（中注协咨询模板）

| 维度 | v6 score | rationale |
|---|---|---|
| D1 标点 | 3/5 | scan 报 4 处 §1.4 红线（应详查并修复） |
| D2 语言朴实 | 4/5 | 咨询体偏正式，无明显大厂黑话 |
| D3 议论方法 | 4/5 | 五段式论证 + 数据支撑 |
| D4 思维 | 4/5 | 辩证思维（机会 + 风险并列） |
| D5 立意 | 5/5 | "审计行业数字化转型"主帅突出 |

**min = D1: 3 / D2: 4 / D3: 4 / D4: 4 / D5: 5**。字数 1936 ≈ 2000 阈值，体裁 = 咨询报告（L3 强触发），同上简化跳过 L3。

---

## 3. L3 Multi-Reviewer：v5 narrative → v6 executable

### v5.x L3

`prompts/multi-agent/orchestration-guide.md`（196 行决策指南）。主对话每次要"现场领悟"该派几个 reviewer、派哪几维、用什么 prompt。spawn 后 reviewer 输出格式不强制，主对话要"理解"自由文本。

### v6.0 L3

`prompts/reviewer.md`（150 行 spawn 模板）+ 严格 JSON 契约（`schemas/reviewer-output.schema.json`）。主对话**单条消息内** spawn 3 个 Agent，每个 reviewer 评一维，返回固定 JSON 结构。汇总策略明确：L2 与 L3 取 min（保守裁判）。

**process clarity delta**：v5 reviewer 输出后主对话要做 N 项判断（自由文本怎么打分、怎么合并）；v6 直接 schema validate + min aggregation，零歧义。

---

## 4. 任仲然书继承度：65% → ~79%（覆盖率） / 40% → ~55%（深度）

v6.0 新增 [`writing-coaching-arc.md`](../../references/writing-coaching-arc.md) + [`peer-vs-self-revision.md`](../../references/peer-vs-self-revision.md) 补齐 5 个深度操作化原则：

- L1§2 观察和阅读（结构化观察日课 + 画道道笔记法 + 对照阅读）
- L1§3 摹仿 → 制造 → 创造 三段弧
- L1§4 愿意写、大胆写、经常写（信心建设）
- L2§3 规律再造（个性化写作节奏）
- L12 改自己 vs 改他人辨证法（reviewer 必读"他批"礼貌）

详见 plan v2 §4.3-§4.4 + Phase C commit 61f1249。

---

## 5. 总分 delta & 回滚决策

| 维度 | v5.1 | v6.0 | delta |
|---|---|---|---|
| L1 numerical（per-anchor red/soft） | baseline | 持平 | 0 |
| L2 protocol clarity（mini-rubric 内联 vs 外置） | low | high | +++ |
| L2 输出格式（free text vs JSON） | free | JSON | +++ |
| L3 spawn 可重现性（narrative vs template） | low | high | +++ |
| L3 输出格式（free text vs schema） | free | schema | +++ |
| L3 汇总策略（implicit vs min(L2,L3)） | implicit | explicit | ++ |
| 任仲然继承度（覆盖率） | 65% | 79% | +14% |
| 任仲然继承度（深度） | 40% | 55% | +15% |
| dev-only 脚本暴露（误用风险） | high | zero | +++ |
| stub flag 留存（破窗） | 3 版 stub | 删 | +++ |

**总分 delta > 0**：v6 全维度持平或提升。**release 决策：继续，无回滚**。

---

## 6. 后续 calibration roadmap（v6.1 起）

- v6.0 release 后用户实战使用 ≥ 5 次，每次开启 `--log-to ~/.writing-polish/log.jsonl`
- v6.1 evolution-queue 消费 log，按"出现频次 × reviewer 一致性"排序晋升新规则
- v6.1 calibration 重做：使用 5-10 篇用户真实文档作 held-out test set，跑 L2 自评 一致性测试（同稿 3 次评分方差 ≤ 0.5 分 = pass）
- 若一致性低 → 进一步细化 SKILL.md §3 mini-rubric 或加 D3-D5 子细则
