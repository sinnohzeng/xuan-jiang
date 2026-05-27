# Layer 3 多智能体审校 · Worked Example（v5.1 实战范式）

> 本文件用 1 篇典型咨询报告片段，从 L1 到 L3 完整跑通一遍，展示主对话**如何自主判断 + 派遣评审员 + 整合 finding + Edit 落地**。读者（主对话或人类）读完本文档应能复现端到端 v5.1 流程。

## §0 输入：用户请求 + 待审文稿

**用户输入**：
> 帮我深度审一下这篇咨询报告，多智能体 review，跑完整版。

**待审文稿**（虚构但典型的 G8 第三方咨询报告片段，350 字）：

```
关于推进协会人工智能能力建设的实施建议

需要特别关注的是，2025 年新修订的《网络安全法》大幅加重了法律责任，对违反等级保护制度的行为，罚款上限从十万元提高到最高一千万元。这一修订意味着，信息安全事故的法律后果不再仅仅是组织层面的经济处罚。协会领导和 IT 部门必须充分认识责任的严重性。

为此，建议平台运营方与协会按季度联合复盘智能体技能上架情况，对出现执业风险线索的智能体技能即时下架。试点阶段的目标不仅验证技术可行性，更重要的是验证实际业务价值。

随着人工智能技术的深入应用，行业参与主体从过去以会计师事务所为核心，逐步演变为事务所、技术公司、数据服务平台、被审计单位内部数据团队、高校研究机构和行业协会公共服务体系等多方协同的生态格局。
```

## §1 主对话自主判断（参 orchestration-guide.md §1 §2）

| 判断项 | 结果 |
|---|---|
| 用户显式 opt-in | ✅ "多智能体 review / 跑完整版" |
| 文档字数 | 350 字（< 3000）— 但用户已显式触发，启用 L3 |
| 文体识别 | G8 第三方咨询报告（关键词："咨询""协会""实施建议""试点"） |
| L2 失败重试次数 | 0（首次走） |
| 启用层 | L1 + L2 + L3 三层全开 |

## §2 Layer 1 / 硬 Gate 跑 scan

```bash
bash scripts/scan-hard-gate.sh /tmp/sample-report.md
```

预期输出（应 PASS，因为本稿无直引号 / em-dash / AI 元注释字面）：

```
[L1 Hard Gate] sample-report.md
  ✓ §1.4.101 em-dash: 0 hits
  ✓ §1.4.103 (即/(如: 0 hits
  ✓ §1.4.111 ASCII quotes: 0 hits
  ✓ §1.6 AI meta: 0 hits
  ✓ §1.2 黑话 50 条: 1 hit (复盘)
  ⚠️ 退出码 0 (warn-only on 复盘，进 L2 详评)
```

**主对话发现**：「复盘」命中 §1.2 D2 套话清单（v5.1 §1.8.6 新红线）。L1 已捕获，进 L2 评分。

## §3 Layer 2 / LLM Judge 主对话评分

主对话读 [`constitution.md`](constitution.md) + [`../prompts/llm-judge-research-report.md`](../prompts/llm-judge-research-report.md)，按 D1-D5 五维 pointwise 评分：

```json
{
  "segment_id": "sample-report-001",
  "D1": 0,
  "D2": 1,
  "D3": 0,
  "D4": 2,
  "D5": 2,
  "evidence": {
    "D2": ["复盘"],
    "D4": ["复盘 = 大厂内训词侵入 G8 咨询语境，§1.8.6 红线 + §6.2 文体判定：周围含「协会 / 平台运营方 / 试点」= G8"],
    "D5": ["需要特别关注的是", "大幅加重", "不再仅仅是", "充分认识", "不仅 X 更重要的是 Y 否定平行", "随着 X 的深入 ... 演变为 ..." 段首过渡套话, "深入"]
  },
  "reasoning": "D5=2: §6.1 模糊副词堆砌（大幅 / 充分 / 不再仅仅是 / 深入 ≥ 4 处）+ §1.3.81 否定平行 + 段首过渡套话；D4=2: §1.8.6 复盘 + §6.2 G8 文体判定；D2=1: 复盘 1 处。整体属 v5.0 calibration disagreement 反例同型（参 §5 Example G+H+K+L）。"
}
```

**主对话决策**：D4 + D5 同时达 2 分，触发 Self-Refine 闭环 → 但用户显式 opt-in L3 → 跳过 Self-Refine 直接进 L3 多视角审校（节省一轮 token）。

## §4 Layer 3 主对话自主决策派评审员（参 orchestration-guide.md §2 §3 §8）

| 决策项 | 主对话推理 | 结果 |
|---|---|---|
| 派几路 R1 | 350 字短稿 + L2 已抓 D2/D4/D5 ≥ 1 → 2 路足够 | 2 路 |
| R1 视角 | L2 高分维度优先 → B 文风 (D2/D3/D5) + C 咨询身份 (D4 G8 边界) | R1-B + R1-C |
| Pre-mod 是否启 | 短稿 + 改动估计 < 30% → 跳过 | 跳过 |
| R2 fresh-eye 是否启 | 高 stakes 文体 + 用户要求完整版 → 启 | 1 路 |
| 模型路由 | R1 用 Sonnet 4.6（1M 已 verify），R2 用 Opus 4.7（深度跨维度症候） | 见下方 |

## §5 单消息内 spawn 3 个 Agent（v5.1 实装范式）

主对话在**同一条消息内**调 3 个 Agent 工具，并行执行：

```
Agent(
  subagent_type="general-purpose",
  description="R1-B 文风评审",
  model="sonnet",
  prompt="你是高级咨询审稿人 5+ 年党政咨询经验，clean context 独立审稿。
        待审文档: /tmp/sample-report.md
        SSOT 红线:
          - /Users/hubby/Workspace/xuan-jiang/plugins/writing-polish/skills/writing-polish/references/anti-ai-taste-anchors.md（230+ 条字面 anchor）
          - .../references/constitution.md（5 维 rubric + §5 Example A-N + §6.1 D5 模糊副词雷达）
        文体: G8 第三方咨询报告
        本轮仅关注: 文风视角（D2 套话 / D3 戏剧化 / D5 整体 AI 体）
        不归你管: D1 标点 / D4 党政 vs 大厂语境（R1-C 在审）
        约束:
          - 援引 SSOT 锚点（如 anti-ai-taste-anchors.md §1.5.2 / constitution.md §5 Example G）
          - 不批评作者、不命令式（'必须'→'建议'）
          - 不引用本对话外训练记忆
        输出格式 JSON 数组 of findings:
          每条 {id, line_range, severity(P0-P5), ssot_anchor, violation_quote(≤50字), issue(≤30字), suggestion(≤80字)}
        finding 上限: 10 条
        summary ≤ 100 字
        严禁修改文件，仅返回 finding JSON"
)
Agent(
  subagent_type="general-purpose",
  description="R1-C 咨询身份评审",
  model="sonnet",
  prompt="<同上结构，视角=咨询身份 G8 五条约束 §1.8.1-§1.8.5 + §1.8.6 大厂内训词侵入>"
)
Agent(
  subagent_type="general-purpose",
  description="R2 fresh-eye 反查",
  model="opus",
  prompt="你是总编辑级独立审稿人，10+ 年经验，clean context。
        你没有前置审稿信息，第一次看本文档。
        待审文档: /tmp/sample-report.md
        SSOT 红线: anti-ai-taste-anchors.md §1 全部 / constitution.md / revision-checklist.md / logic-and-structure.md
        全维度通审 + 重点抓 R1 可能漏掉的跨维度症候:
          - D2+D5 组合症候（既套话又模板感）
          - 客户敏感二阶问题（含蓄越界 / 暗讽）
          - 立意主题 / 主线清晰度
        不重复 R1 已抓的字面红线（L1 早已 0 命中）
        允许 dimension='cross-D2-D5' 组合标签
        finding ≤ 12 条，summary ≤ 150 字"
)
```

**关键**：3 个 Agent 在同一条消息内 spawn，并行执行 ≈ 1 个 reviewer 的耗时。clean-context 是 feature——subagent 看不到主对话讨论，独立反推 spec（Cognition Devin 实证每 PR 多抓 2 bugs，58% severe）。

## §6 收 R1+R2 finding JSON

R1-B 返回（示例）：

```json
{
  "agent_role": "R1-B 文风评审 Sonnet 4.6",
  "dimension": "style",
  "findings": [
    {"id": "F1", "line_range": "L3-L5", "severity": "P3", "ssot_anchor": "constitution.md §6.1 + §5 Example G",
     "violation_quote": "大幅加重 / 不再仅仅是 / 充分认识 + 需要特别关注的是",
     "issue": "D5 模糊副词堆砌 + 模板化导语",
     "suggestion": "改为：'2025 年修订《网络安全法》将等级保护违规罚款上限从 10 万元上调至 1000 万元或营业额 5%，并新增个人罚则（最高 10 万元 / 期限禁任）。协会应明确合规责任主体清单。'"},
    {"id": "F2", "line_range": "L7-L8", "severity": "P3", "ssot_anchor": "anti-ai-taste-anchors.md §1.3.81 + constitution.md §5 Example H",
     "violation_quote": "试点阶段的目标不仅验证技术可行性，更重要的是验证实际业务价值",
     "issue": "否定平行结构 + 无量化指标",
     "suggestion": "改为：'试点阶段验证两件事：技术可行性（接口稳定 / 调用延迟 / 数据安全）+ 业务价值（接入后审计工时是否下降 ≥ 15%）。'"},
    {"id": "F3", "line_range": "L10-L13", "severity": "P3", "ssot_anchor": "constitution.md §6.1 + §5 Example K",
     "violation_quote": "随着人工智能技术的深入应用 ... 逐步演变为 ...",
     "issue": "段首过渡套话 + '深入' 模糊副词 + 演变叙述模板",
     "suggestion": "改为：'2024-2025 年行业参与主体扩展至六方：事务所（核心 / 审计执行）、技术公司（文档解析 / 流水核查）、数据平台（工商 / 司法 / 信用源）、被审计单位 IT 团队（系统接口）、高校（人才 / 方法论）、协会（公共服务）。'"}
  ],
  "summary": "段落含具体数字（罚款金额 / 时间）但被 4+ 处模糊副词稀释；3 处明显 AI 散文体结构问题"
}
```

R1-C 返回（示例）：

```json
{
  "agent_role": "R1-C 咨询身份评审 Sonnet 4.6",
  "dimension": "consulting-identity",
  "findings": [
    {"id": "F4", "line_range": "L7", "severity": "P2", "ssot_anchor": "anti-ai-taste-anchors.md §1.8.6 + constitution.md §6.2 + §5 Example L",
     "violation_quote": "建议平台运营方与协会按季度联合复盘",
     "issue": "G8 咨询报告语境下「复盘」属大厂内训词侵入，§1.8.6 红线",
     "suggestion": "改为：'建议平台运营方与协会按季度联合总结智能体技能上架情况'（复盘→总结）"}
  ],
  "summary": "G8 边界 1 处显式违规；其他咨询身份维度未发现问题（无厂商背书 / 无政治承接句开篇 / 无请示稿专属符号）"
}
```

R2 返回（示例）：

```json
{
  "agent_role": "R2 fresh-eye Opus 4.7",
  "dimension": "cross-cutting",
  "findings": [
    {"id": "F5", "line_range": "L3-L13", "severity": "P3", "ssot_anchor": "constitution.md §6.1 + revision-checklist.md 立意一句话",
     "violation_quote": "整体三段无连贯主线",
     "issue": "立意散：段 1 讲合规法律责任，段 2 讲试点目标，段 3 讲生态演变，三段之间没有清晰逻辑承接",
     "suggestion": "增加首段判断句（如'本节回应法律责任 + 试点设计 + 生态定位三个关键问题'）+ 段间过渡句"}
  ],
  "summary": "R1 已抓 4 处字面违规，本轮抓 1 处立意主线断裂（cross-cutting 维度）。整体最大风险：模糊副词被 v5.0 judge 放过，v5.1 §6.1 雷达正确捕获。"
}
```

## §7 Orchestrator Synthesis（主对话整合）

**P0-P5 排序**：
- F4 (P2 严重 AI 腔 / 客户敏感边界) — **必改本轮**
- F1 / F2 / F3 / F5 (P3 中度 AI 腔 / 模板感) — **改本轮**

**决策三问** 逐条跑：

| Finding | Q1 违反 SSOT? | Q2 颗粒度有增益? | Q3 重复加严? | 结论 |
|---|---|---|---|---|
| F4 复盘 | ✅ §1.8.6 | ✅ 复盘→总结改完 G8 合规 | 无重复 | **采纳** |
| F1 充分认识 | ✅ §6.1 + Example G | ✅ 加入"明确合规责任主体清单"具体动作 | 无重复 | **采纳** |
| F2 不仅...更是 | ✅ §1.3.81 + Example H | ✅ 加入量化指标（工时 ≥15%） | 无重复 | **采纳** |
| F3 深入演变 | ✅ §6.1 + Example K | ✅ 时间锚点 + 六方对应职能具体化 | 无重复 | **采纳** |
| F5 立意散 | ✅ revision-checklist 一句话立意 | ✅ 增加首段判断句明显改善 | F1-F4 单维 finding 不覆盖此跨维度 | **采纳** |

**Edit 落地铁律**：行号倒序串行（先改 L10-L13 段，再 L7-L8，再 L3-L5）。

```
Edit(file=/tmp/sample-report.md, old_string="随着人工智能技术的深入应用，行业参与主体从过去以会计师事务所为核心，逐步演变为事务所、技术公司、数据服务平台、被审计单位内部数据团队、高校研究机构和行业协会公共服务体系等多方协同的生态格局。", new_string="2024-2025 年行业参与主体扩展至六方：事务所（核心 / 审计执行）、技术公司（文档解析 / 流水核查）、数据平台（工商 / 司法 / 信用源）、被审计单位 IT 团队（系统接口）、高校（人才 / 方法论）、协会（公共服务）。")

Edit(file=/tmp/sample-report.md, old_string="试点阶段的目标不仅验证技术可行性，更重要的是验证实际业务价值。", new_string="试点阶段验证两件事：技术可行性（接口稳定 / 调用延迟 / 数据安全）+ 业务价值（接入后审计工时是否下降 ≥ 15%）。")

Edit(file=/tmp/sample-report.md, old_string="建议平台运营方与协会按季度联合复盘智能体技能上架情况", new_string="建议平台运营方与协会按季度联合总结智能体技能上架情况")

Edit(file=/tmp/sample-report.md, old_string="需要特别关注的是，2025 年新修订的《网络安全法》大幅加重了法律责任，对违反等级保护制度的行为，罚款上限从十万元提高到最高一千万元。这一修订意味着，信息安全事故的法律后果不再仅仅是组织层面的经济处罚。协会领导和 IT 部门必须充分认识责任的严重性。", new_string="本节回应法律责任、试点设计、生态定位三个关键问题。\n\n2025 年修订《网络安全法》将等级保护违规罚款上限从 10 万元上调至 1000 万元或营业额 5%，并新增个人罚则（最高 10 万元 + 期限禁任）。协会应明确合规责任主体清单。")
```

## §8 收敛判停

- 第 1 轮采纳率 = 5/5 = 100%（全采纳）
- 改完跑 L1 scan → 全 PASS（"复盘"已删，无其他红线）
- L2 复评 D4=0 / D5=0（v5.1 §5 Example G+H+K+L 锚定的违规已全部消除）
- 主对话判断：本稿改动满足收敛条件（采纳率 > 20% + 无新违规 + L2 全 0），无需第 2 轮 → 收敛

## §9 jsonl 记录（v5.1 P1-2 标配）

主对话往 [`../evals/layer3-convergence.jsonl`](../evals/layer3-convergence.jsonl) append 一行：

```json
{"ts":"2026-05-27T22:30+08:00","doc_id":"sample-report-walkthrough","genre":"G8","adoption_rate":1.0,"convergence_rounds":1,"fallback_used":false,"reviewer_views":["R1-B","R1-C","R2"],"findings_total":5,"findings_adopted":5,"wallclock_minutes":3.2}
```

## §10 交付给用户

```markdown
# 改稿交付报告（v5.1 三层 hybrid 全流程跑完）

## L1 / 硬 Gate
- scan-hard-gate.sh 退出码：0
- 红线指标：复盘 1 处（已删）

## L2 / LLM Judge
- 改前评分：D1=0 D2=1 D3=0 D4=2 D5=2
- 改后评分：D1=0 D2=0 D3=0 D4=0 D5=0

## L3 / Multi-Agent Review
- 视角：R1-B 文风 + R1-C 咨询身份 + R2 fresh-eye
- 模型：Sonnet × 2 + Opus × 1
- finding 总数：5
- 采纳率：100%
- 收敛轮数：1
- 终止原因：L2 全 0 + 采纳率 100%

## 已采纳 finding（按 P0-P5 排序）

| ID | severity | 位置 | 问题 | 改后引文 |
|---|---|---|---|---|
| F4 | P2 | L7 | 复盘 = G8 红线 §1.8.6 | "按季度联合总结" |
| F1 | P3 | L3-L5 | 模糊副词堆砌 + 模板化导语 | "明确合规责任主体清单" |
| F2 | P3 | L7-L8 | 不仅 X 更重要 + 无量化 | "审计工时下降 ≥ 15%" |
| F3 | P3 | L10-L13 | 段首过渡套话 + 演变叙述模板 | "2024-2025 行业参与主体六方" |
| F5 | P3 | L3-L13 | 立意散三段无主线 | 首段判断句承接三议题 |

## 反方观点与盲区

本次审校未涉及：（1）法律责任段的合规性专业准确度（建议由协会法务复核罚款上限 / 营业额 5% 条款适用范围）；（2）六方生态主体的"高校研究机构"角色是否过度泛化（实际可能仅有清华 / 厦大 / 上财等少数高校具备实质参与能力）。
```

## §11 关键学习点（写进 v5.1 ADR / handoff）

1. **主对话自主判断的体现**：短稿 350 字本不必派 5 路 R1，主对话根据 L2 高分维度精准派 B+C 两路（避免过度工程）
2. **clean-context subagent 的价值**：R2 抓到 R1 没看出来的"立意主线断裂"（cross-cutting 维度），印证 Cognition Devin +2 bugs/PR 58% severe 实证
3. **模型路由实战**：Sonnet × 2（单维度任务）+ Opus × 1（重型跨维度）= 单 Opus 同等成本下覆盖更广视角
4. **v5.1 §6.1 D5 雷达落地**：v5.0 calibration κ=0 的"模糊副词被放过"问题在本案例直接捕获 4 处（"大幅 / 充分 / 不再仅仅是 / 深入"）
5. **§1.8.6 复盘红线落地**：v5.1 新增 G8 大厂内训词侵入红线在 R1-C 一次性抓到，无遗漏
6. **收敛轻量**：单轮采纳率 100% + L2 复评全 0 即收敛，不强求多轮（避免 churn）
