---
title: 人工金标准 calibration set 标注规约（v5.1 Sprint 2 SSOT）
version: v5.1.0-spec
status: draft
created: 2026-05-20
owner: 曾子轩（Sinnoh）
schema_ref: ../../references/constitution.md §0（D1-D5 rubric SSOT，禁双源）
gate_target: 跨模型 κ ≥ 0.8（≥ 2 个 BYOM 模型同金标准一致）
---

# 人工金标准 calibration set 标注规约

> 本文件是 v5.1 Sprint 2 的 SSOT。所有 200 段金标的抽样、标注、仲裁、κ 计算与 v5.0.0 stable 发版决策按本规约执行，**禁止**在执行过程中私自调整门槛或重排样本。

## §0 设计原则（违反 = grade-gaming，直接作废本批次）

1. **Anti-leakage**：金标 segments 来源**禁止与 judge prompt 内嵌 few-shot 重叠**。constitution §5 Example A-F 六段已在 prompt 里出现，本批 200 段必须**逐一 hash 比对**确认零字面重合（命中即丢弃）。
2. **Anti-grade-gaming**：annotator A（猪猪老公）和 annotator B（Claude Code 子智能体）**禁止**在打分前看 judge 模型输出、calibration-set.jsonl auto-evidence、disagreement.md 历史分歧。spec.md 是唯一允许阅读的标注指引。
3. **Annotator B clean-context 强约束**：子智能体启动时**只允许**加载本文件 + constitution.md §0/§1/§5（rubric + 红线 + 6 例 few-shot），**禁止**加载 prompts/llm-judge-research-report.md（judge prompt 本体）。Cognition clean-context-code-review 2026-04 同款。
4. **Marginal 平衡**：抽样时**主动 oversample“有问题段”**。Sprint 1 D1/D4 κ=0 是 Cohen κ 边界塌缩（多数 0 分），Sprint 2 必须保证每维至少 30 段 score ≥ 1，否则 κ 公式不稳定。
5. **Verified flag 单向**：本批 200 段全部 `verified: true`，写入后**只读**（与 Karpathy L1 sources/ immutability 同源）；后续 judge 漂移需要新 batch 而非修改本批。

## §1 标注维度（引用，不重述）

5 维 0-3 rubric + unknown 逃生舱见 `../../references/constitution.md` 第 28-36 行（§0 文体与维度矩阵）。

**唯一允许的本地化补充**（不与 constitution 冲突）：

- **D1 评估窗口**：每段独立评估，不跨段累计标点违规计数。
- **D5 模糊词雷达**：constitution §6 列出“充分 / 深入 / 持续 / 系统 / 全面 / 有效”等模糊词，**单段连续 ≥ 3 个**强制 D5 ≥ 2。
- **Unknown 触发场景**：(a) 段长 < 30 字证据不足；(b) 文体歧义（如调研报告里夹一段诗）；(c) 语境不明（脱离上下文无法判 D3/D4 IT/党政白名单豁免）。

## §2 文体权重（200 段总分布）

| 文体 | 段数 | 占比 | 主源 | 兜底源 |
|---|---|---|---|---|
| G3 调研报告 | 60 | 30% | cicpa V2/V3/V4 diff | 招商局集团 / 国资委 / 智库公开调研报告 |
| G8 咨询报告 | 50 | 25% | cicpa V2/V3/V4 diff | 信永中和 / 天职国际 / 安永官网公开案例 |
| G6 随笔 + G7 自媒体 | 50 | 25% | 公众号 + 微博碎片 | 知乎专栏 / 少数派 / 36 氪深度文 |
| G1 公文 | 20 | 10% | gov.cn 国务院通知 | 中央部委官网公开发文 |
| G2 讲话稿 | 20 | 10% | 党媒公开领导讲话 | 学习强国 / 求是网公开稿 |

**抽样策略**：

1. **before / after 配比**：cicpa diff 自然产 before/after 对，G3/G8 必须保留配对结构（before 30 段 + after 30 段 / before 25 + after 25），便于 D5 contextual judgment 验证。
2. **新源 oversample 有问题段**：G6/G7 公众号网文优先抓 `赋能` / `综上所述` / `让我们一起` anchor 命中 ≥ 2 处的段（D2 ≥ 2 候选）；G1/G2 优先抓套话密集段（D5 ≥ 1 候选）。
3. **每段长度**：100-300 字之间（过短证据不足，过长 judge token 成本高）。
4. **Hash 去重**：所有抽样段对 constitution §5 Example A-F + Sprint 1 calibration-set.jsonl 跑 char-trigram Jaccard 相似度，> 0.3 丢弃。

## §3 数据源与抓取流程

### §3.1 cicpa diff（G3 60 + G8 50）

- 入口：`~/Workspace/cicpa/04-最终交付/` V2 / V3 / V4 三个版本目录。
- 抽取脚本：复用 `evals/extract-from-cicpa-commits.py`，新增 `--gold-standard --strip-auto-scores` flag，输出**只含 text / genre / source**字段的 raw-segments.jsonl（不携带 auto_evidence / scores 等可能污染 annotator 判断的字段）。
- 配对：每个 commit hash 优先保留 before/after 配对段。

### §3.2 公众号 + 微博碎片（G6 50）

- firecrawl search 关键词组合 `赋能 综上所述` / `让我们一起 OR 共同探讨` / `底层逻辑 第一性原理` 等 anchor 串，限制 site:mp.weixin.qq.com / weibo.com。
- 合规：只抓**公开发布**的图文（无登录墙），保留原文 URL + 发布时间到 source 字段；不抓个人朋友圈 / 私密群聊截图。
- firecrawl 优先级：search → scrape，**禁止** crawl 整站（按 [[firecrawl-paid-utilization]] 节流）。

### §3.3 gov.cn 公文 + 党媒讲话稿（G1 20 + G2 20）

- gov.cn：`/zhengce/zhengceku/` 国务院政策库公开通知。
- 讲话稿：`12371.cn` 党建网 / `qstheory.cn` 求是网领导署名文章公开段。
- 合规：只引用**已正式发布**的公文段（避免内部稿 / 草案）；保留发文字号 + 发布日期到 source 字段。

### §3.4 抓取产物 schema

`raw-segments.jsonl` 每行：

```json
{
  "segment_id": "g3-cicpa-V3-WS3-0042",
  "genre": "research-report",
  "source": {"type": "cicpa-diff", "commit": "349bf83", "file": "04-最终交付/V3.../WS3.md", "kind": "before"},
  "text": "...",
  "char_len": 187,
  "hash_trigram": "...",
  "leakage_check": {"vs_few_shot_jaccard": 0.04, "vs_v50_calib_jaccard": 0.0, "passed": true}
}
```

**禁止**字段：`scores` / `auto_evidence` / `annotator` / `verified`。这些字段只在标注后才出现，污染 raw 阶段即 grade-gaming。

## §4 标注流程（2 人独立 + 仲裁）

### §4.1 Annotator A（猪猪老公）

- 工具：纯文本编辑器或 Obsidian，**不联网**、**不查 judge 输出**、**不读 constitution §5 以外的 prompt 内容**。
- 节奏：每段限时 1-2 分钟，标完 200 段约 3-5 小时（可分 4-5 个 session）。
- 产物：`annotator-a.jsonl`，每行 `{segment_id, scores: {D1-D5: 0-3|unknown}, time_sec, note?}`。

### §4.2 Annotator B（Claude Code 子智能体 clean-context）

- 启动方式：主对话 spawn 一个 general-purpose subagent，**只传**：
  - 本 spec.md 全文
  - constitution.md §0 + §1 + §5（rubric + 红线 + 6 例 few-shot）
  - raw-segments.jsonl 文件路径
- **禁传**：判定历史、judge prompt 本体、Sprint 1 disagreement.md、calibration-set.jsonl 的 scores 字段。
- 子智能体 prompt 末尾必须明示：“你是独立 annotator B，从 0 反推 5 维 rubric 应用，不要回头查 judge 模型输出，不要假设 annotator A 怎么打”。
- 产物：`annotator-b.jsonl`，schema 同 A。

### §4.3 Inter-annotator κ 计算（gold 可信度 gate）

- 全 5 维各算一次 Cohen's κ（含 unknown 段排除版与 unknown 折算 0 版双口径）。
- **gate**：**每维** inter-annotator κ ≥ 0.7 才算 gold 可信。任一维 < 0.7 必须扩大仲裁范围（不只仲裁 > 2 分差段，加抓 0.7-1.0 分差段重审）。

### §4.4 仲裁规则

| 分差 | 处理 |
|---|---|
| 0（A == B） | 直接 lock，进 gold.jsonl |
| 1 | 取 round(mean(A,B))，进 gold.jsonl，标 `arbitration: "averaged"` |
| ≥ 2 | 仲裁 reviewer 介入：猪猪老公 + 1 个新 reviewer（可以是另一个 clean-context 子智能体 C，或人类同行），3 人多数票决，必要时回头改 spec |
| 任一方 unknown，另一方非 unknown | 若非 unknown 方分差 ≤ 1 with 0，按 1 处理；> 1 进仲裁 |
| 两方 unknown | 标 `arbitration: "both-unknown"`，不计入 κ 但保留段 |

### §4.5 Gold 产物 schema

`gold.jsonl` 每行：

```json
{
  "segment_id": "g3-cicpa-V3-WS3-0042",
  "genre": "research-report",
  "text": "...",
  "gold_scores": {"D1": 0, "D2": 2, "D3": 0, "D4": 1, "D5": 2},
  "annotator_a": {...},
  "annotator_b": {...},
  "arbitration": "averaged" | "majority-vote" | "lock" | "both-unknown",
  "verified": true,
  "verified_at": "2026-05-2X",
  "source": {...}
}
```

## §5 跨模型 κ 回归（gold vs judge models）

3 个 BYOM 模型同 gold.jsonl 跑：

| 模型 | 全跑 / 抽样 | 预计 runtime | 目的 |
|---|---|---|---|
| qwen3.6-plus | 全 200 段 × rounds=1 | ~2.5 h | 基线，DashScope 资源包内主跑 |
| qwen3.6-max-preview | 抽样 100 段 × rounds=1 | ~5-8 h | 验证旗舰一致性，趁 1500 RMB 资源包窗口 |
| DeepSeek v3.5 | 全 200 段 × rounds=1 | ~1-2 h | 跨厂商兜底，确认非 Qwen 偏置 |

**禁止**用 Anthropic API 直调 Sonnet（[[feedback_anthropic_api_policy]]）。若必须比 Sonnet，走 Claude Code Max 套餐内的子智能体 spawn，不计入 BYOM cost。

每模型产物：`calibration-results/v51-cross-model/{model}/cohen_kappa.json + per_segment.csv + disagreement.md`。

## §6 v5.0.0 stable 发版门槛

**全部满足**才升 v5.0.0 stable：

1. Inter-annotator κ ≥ 0.7（每维），即 gold 本身可信
2. ≥ 2 个 BYOM 模型 5 维加权 κ ≥ 0.8
3. **D5 单维度** κ ≥ 0.8 at ≥ 2 模型（D5 是 Sprint 2 真校准目标，不可降标）
4. Unknown 率 ≤ 15%（judge 不能靠 unknown 逃生舱刷高 κ）
5. SKILL.md 主入口 `--llm-judge` flag 连通，plugin manifest 注册

**任一不满足**：继续 Sprint 2 迭代（few-shot 池扩 / prompt 调），不发版。**禁止**降低门槛凑 PASS（grade-gaming）。

## §7 Anti-grade-gaming 检查表（每个里程碑跑）

- [ ] raw-segments.jsonl 不含 scores / auto_evidence 字段（grep 验证）
- [ ] annotator A 标注全程未查 judge 输出（猪猪老公自承诺 + session 时间戳记录）
- [ ] annotator B 启动 prompt 不含 judge prompt 本体（spawn 命令 log 留痕）
- [ ] gold.jsonl `verified: true` 后无 commit 修改（git log --follow 验证 immutable）
- [ ] 跨模型 κ 计算脚本 hash 与 Sprint 1 同（cohen-kappa.py 未被偷改）
- [ ] 发版门槛 4 条全 PASS，缺一不补

## §8 进度看板

| 步 | 子任务 | 状态 | 产物 | 验证 |
|---|---|---|---|---|
| 1 | 本 spec.md SSOT | 🟡 in_progress | `gold-standard/spec.md` | 5 视角 review PASS |
| 2 | 抽 200 段 raw | ⏳ pending | `raw-segments.jsonl` | leakage check 全 PASS |
| 3 | Annotator A 标注 | ⏳ pending | `annotator-a.jsonl` | 200 段全标完，每段有 time_sec |
| 3 | Annotator B 标注 | ⏳ pending | `annotator-b.jsonl` | clean-context spawn log 留痕 |
| 4 | 仲裁 + gold | ⏳ pending | `gold.jsonl` | inter-annotator κ ≥ 0.7 per 维 |
| 5 | 跨模型 κ 回归 | ⏳ pending | `calibration-results/v51-cross-model/` | 3 模型全跑完 |
| 6 | few-shot 扩充 | ⏳ pending | judge prompt v5.1 | κ 提升幅度 ≥ 0.05 |
| 7 | v5.0.0 stable 决策 | ⏳ pending | git tag v5.0.0 + SKILL.md update | §6 门槛全 PASS |

## §9 反方观点与盲区

- **200 段够吗？** 不一定。D5 contextual judgment 维度 60 段 G3 + 50 段 G8 + 50 段 G6/G7 = 160 段散文样本，若 marginal 仍不均，需要 Sprint 2.5 加抓 100 段。本 spec 留扩样接口（`raw-segments-batch-2.jsonl` 命名约定）。
- **公众号 / 微博合规边界**：firecrawl 抓公开图文段做 calibration 学术评估属 fair use 范围，但若 v5.0.0 stable 发版后把这些段公开发布，需重新走原文 license 检查。本 spec 仅保证内部 calibration 阶段可用。
- **Inter-annotator κ ≥ 0.7 阈值偏低**：传统 NLP gold standard 常用 0.8。本规约取 0.7 是因为 D3/D4 上 IT/党政白名单豁免本身就是 judgment call，两人有 10-15% 边界分歧是合理的。若任一维 inter-annotator κ ≥ 0.85，可考虑把跨模型 κ gate 从 0.8 提到 0.85。
- **Annotator B 子智能体的 clean-context 是否真 clean**：Claude Code 子智能体启动时不传父对话 trajectory，但模型权重本身见过大量 anti-AI-taste 语料，理论上不算完全独立。本 spec 通过禁传 judge prompt 本体加禁传 disagreement 历史这两条逼近独立性，但无法完全消除模型先验偏置。这是已知 limitation，未来 Sprint 3 可考虑加 1 名人类 annotator C 做三角验证。
- **scan-hard-gate.sh 不适用于本 spec**：scanner 设计目标是 polish 候选文档（咨询报告 / 调研报告等），不是 SOP 元文件。本 spec.md 含 JSON schema + anchor 词字面定义 + 英文统计术语（Cohen's κ），必然触发 29 处 false positive（H1.1 ASCII 直引号在 JSON 与 inline code 内合法；H3.2/H3.3/H4.1 anchor 词在 backtick 内是 token mention 而非 narrative use）。基线对照：constitution.md 同类型文件 FAIL 112 处、judge prompt 116 处。v5.2 backlog：scanner 加 `# scan-exempt` 注释 fence 支持 SOP 例外。

---

**SSOT 锚点**：本 spec.md 一旦合入 main，**禁止**单边修改门槛 / 抽样比例 / 维度定义。任何修改需新开 v5.1.x-spec.md 并 commit message 注明上游变更原因，旧版保留只读。
