# Layer 3 多智能体审校编排指南（主智能体自主判断版）

> v5.1 大刀阔斧重构：从 5 个带 `{{}}` 占位符的模板，砍成本指南一篇。**主对话即 orchestrator**——根据文稿特征自主判断派几个评审员、每人聚焦哪维、要不要 pre-mod、R2 何时启动、何时收敛。Anthropic Multi-Agent System 2025-06 "teach orchestrator how to delegate" 范式。

## §1 何时启用 Layer 3（主对话自主判断）

满足下列任一条件即触发 L3，主对话**不必征求用户**：

- 用户显式 opt-in："派几个 agent 审一遍 / 多智能体 review / 用 v5 完整跑一遍 / R1+R2"
- 文档 ≥ 3000 字
- 文体 ∈ {G3 调研报告 / G1 公文 / G4 述职 / G2 大会讲话 / G8 第三方咨询}
- 用户已对 Layer 2 输出连退 2 次（暗示 L2 抓不出问题）

短稿（< 1000 字）/ 文风轻润色 / 用户明确说"只改语言" → **跳过 L3**，单跑 L1+L2 即可。

## §2 派几个评审员（基于文稿特征，不固定 K）

| 文稿规模 | 评审员配置 |
|---|---|
| 1000-3000 字 | 1-2 路 R1（取文稿短板维度）+ 视情况 R2 |
| 3000-10000 字 | 3-4 路 R1（不重叠维度）+ 1 路 R2 |
| > 10000 字 / 高 stakes | 4-5 路 R1 + 1 路 Opus pre-mod + 1 路 R2 |

**不强求 5 视角全派**：主对话根据 L2 五维评分结果，针对 D 维 ≥ 2 分的视角优先派 R1，D 维 = 0 的视角跳过节省 token。

## §3 评审员视角组合（5 维 × 文体裁剪）

| 视角 ID | 关注维度 | 推荐文体 |
|---|---|---|
| **R1-A 事实视角** | 数据 / 论断 / 引用是否与 SSOT 矛盾 | G1 公文 / G3 调研 / G8 咨询 |
| **R1-B 文风视角** | AI 味红线（D2/D3/D5）、句长方差、模板感 | 全文体 |
| **R1-C 咨询身份视角** | 咨询机构对甲方边界（参 anti-ai-taste-anchors.md §1.8）：不背书厂商 / 不批评客户 / 不命令式 / 不下定义 | G8 咨询专属 |
| **R1-D 信息架构视角** | 章节结构 / 标题层级 / 主线清晰 / 比重均衡 | G3 调研 / G8 咨询 |
| **R1-E 可达性视角** | 术语首释 / 缩写展开 / 图表 alt / 跨章引用自洽 | G2 讲话 / G5 汇报 / G7 自媒体 |

**文体裁剪建议**：G1 公文 → A+B+D / G2 讲话 → B+C+E / G4 述职 → A+B+C / G7 自媒体 → B+D / G8 咨询全派 5 视角。

## §4 Agent 工具调用语法（worked example，不用 placeholder）

主对话在**同一条消息内**调多个 Agent 工具（Claude Code 内置）。Agent 工具的 `model` 参数可选 `opus` / `sonnet` / `haiku`，subagent 默认 clean-context（不继承父对话 trajectory）。

调用示例（咨询报告 G8，3 路 Sonnet R1 + 1 路 Opus R2 fresh-eye）：

```
单消息内并行 spawn 4 个 Agent 工具：

Agent(
  subagent_type="general-purpose",
  description="R1-A 事实评审",
  model="sonnet",
  prompt="你是高级咨询审稿人 5 年党政经验，clean context 独立审稿。\n
        待审文档: /abs/path/research-report.md\n
        SSOT 红线: /abs/path/references/anti-ai-taste-anchors.md + constitution.md\n
        文体: G8 第三方咨询报告\n
        本轮仅关注: 事实视角（数据 / 论断 / 引用是否与 SSOT 矛盾）\n
        约束: 援引 SSOT 锚点、不批评作者、不命令式（'必须'→'建议'）、不引用本对话外训练记忆\n
        输出格式: JSON 数组 of findings\n
          每条 {id, line_range, severity(P0-P5), ssot_anchor, violation_quote(≤50字), issue(≤30字), suggestion(≤80字)}\n
        finding 上限: 15 条\n
        严禁修改文件，仅返回 finding JSON"
)
Agent(... model="sonnet", description="R1-B 文风评审", prompt=<同上结构，视角=文风 D2/D3/D5>)
Agent(... model="sonnet", description="R1-C 咨询身份", prompt=<同上结构，视角=cicpa 5 条专属约束>)
Agent(... model="opus",   description="R2 fresh-eye 反查", prompt=<R2 章节见 §6>)
```

**clean-context 是 feature 不是 bug**——subagent 看不到 R1 互相的输出 + 看不到主对话之前的讨论，独立从 SSOT 反推 spec。Cognition 2026-04 Devin 实证每 PR 多抓 2 bugs，58% severe。

## §5 Pre-modification 触发（动笔前方案审议）

主对话准备改动 ≥ 30% 段落 / 用户说"重写第三章 / 大幅调整 / 结构重建" / 文体识别有歧义 / 改动涉及"客户敏感 / 厂商背书 / 政策引用"时，先 spawn 1 路 Opus pre-mod subagent 审议改稿方案：

```
Agent(
  subagent_type="general-purpose",
  description="Pre-mod 方案审议",
  model="opus",
  prompt="你是资深咨询项目总监，10+ 年党政咨询经验，clean context。\n
        原稿: <abs path>\n
        改稿草案: <abs path 主对话已写好>\n
        SSOT 红线: anti-ai-taste-anchors.md + revision-checklist.md\n
        甲方背景（如有）: <abs path>\n
        审议三维度: 方向（对得上用户诉求 / 文体规约 / 甲方关注点吗）/ 代价（改 N% 段落是否值得 / 误伤已合规段风险 / track-changes 客户能否看懂）/ 替代路径（有没有更小代价方案）\n
        约束: 不动笔改稿、不给具体改写建议、不批评作者、必须给 GREEN/YELLOW/RED verdict\n
        输出: {verdict, verdict_one_liner(≤30字), direction_assessment, cost_assessment, alternatives[≤3], recommendation(≤100字)}\n
        整体 ≤600 字"
)
```

verdict 处理：**GREEN** → 按草案动手，跑完 L1+L2 即可；**YELLOW** → 按 alternatives 调整后再动手 + 触发 R1；**RED** → 停手回到与用户对齐阶段（方向有结构性问题）。

## §6 R2 fresh-eye 反查（独立审稿）

R1 反馈采纳后 + 总改动行数 > 30% 时，spawn **1 路 Opus** R2 subagent 反查"R1 之后还能发现什么"。**铁律：不传 R1 trajectory**——R2 prompt 里只含 SSOT 路径 + 待审文档，**不**包含 R1 任一 finding。

```
Agent(
  subagent_type="general-purpose",
  description="R2 fresh-eye 反查",
  model="opus",
  prompt="你是总编辑级独立审稿人，10+ 年经验，clean context。\n
        你没有前置审稿信息，第一次看本文档。\n
        待审文档: <abs path>\n
        SSOT 红线: anti-ai-taste-anchors.md §1 全部 / constitution.md / revision-checklist.md / logic-and-structure.md\n
        全维度通审，价值在抓 R1 单视角可能漏掉的跨维度症候:\n
          - 立意主题（一句话能否概括？跑题？'全而又全'？）\n
          - 主线清晰度（结构断裂 / 反复）\n
          - 跨章一致性（前后矛盾 / 术语漂移）\n
          - D2+D5 组合症候（既套话又模板感，单维 judge 可能各扣 1 分组合起来才暴露）\n
          - 客户敏感二阶问题（R1-C 只看显性批评，你看含蓄越界 / 暗讽）\n
        不重复 R1 已抓的字面红线（直引号 / em-dash / 抓手，L1 早已 0 命中）\n
        允许 dimension='cross-D2-D5' 组合标签\n
        finding ≤ 12 条，summary ≤ 150 字可写整体判断"
)
```

## §7 收敛判停（P0-P5 + 决策三问 + Edit 落地铁律）

R1 + R2 + （可选 pre-mod）全部返回 JSON 后，主对话执行 synthesis：

**P0-P5 严重度序列**（cicpa SOP 内化）：
| P | 含义 | 行动 |
|---|---|---|
| P0 | 重大事实错误（数据 / 名称 / 法条引用错） | 必改，立即 |
| P1 | 客户敏感（暴露内部信息 / 越界批评 / 厂商背书） | 必改，立即 |
| P2 | 严重 AI 腔（红线词 / em-dash / 元注释） | 必改，本轮内 |
| P3 | 中度 AI 腔（套话密集 / 模板感 / 戏剧化） | 改，本轮内 |
| P4 | 文风可优化（同义改写 / 句长方差 / 过渡词单调） | 视余力改 |
| P5 | 美学偏好（subagent 私人偏好无 SSOT 锚点） | **不采纳** |

**每条 finding 落地前决策三问**：
1. 这条违反了 SSOT 吗？援引 anchors §X / constitution §Y？否 → P5 直接弃
2. 改完后表达更具体 / 更准 / 更朴实？还是只是同义改写（"打通业务闭环" → "打通业务回路"）？无增益 → 弃
3. R1 多个 finding 重复加严同一处吗？取 severity 最严的，丢弃其他

**Edit 落地铁律**：串行（不并行写文件）+ 行号倒序（避免行号偏移）+ 每 Edit 后自查改动是否引入新违反 + 全部改完跑 L1 scan + L2 spot-check。

**收敛判停**：
- 连续 2 轮采纳率 < 20% → 退出
- max severity ≤ P3 且采纳率 < 30% → severe 已清空，退出
- 累计 5 轮 → 硬上限退出（防 churn）

cicpa 实战经验：3-4 轮收敛，最终采纳率 21%。**不是越高越好**——L1+L2 已抓 70% AI 味，L3 真正价值在抓 R1/R2 多视角共识下的硬骨头（P0-P2），那些占总 finding 也就 20-25%。

## §8 模型路由（Opus + Sonnet 配置）

| 角色 | 模型 | 理由 |
|---|---|---|
| 主对话 orchestrator | Opus 4.7 1M（当前 Claude Code 主模型） | 长上下文 + 综合判断 |
| Pre-mod 重型评审 | Opus（`model="opus"`） | 方案审议质量优先 |
| R2 fresh-eye 重型评审 | Opus（`model="opus"`） | 跨维度组合症候抓取 |
| R1 多视角并行评审 | Sonnet 4.6（`model="sonnet"`） | 单维度任务 + 成本 1/5 |

真值源：[`../../config/default.yaml`](../../config/default.yaml) 行 9-25。未来想换 Haiku / Gemini / DeepSeek 走 BYOM，改 config 即可，本指南不动。

**1M context 可用性**（2026-05-27 firecrawl 实测 Anthropic 官方 docs 锚定）：
- Opus 4.7 context window = **1M tokens** ✅，max output 128k
- Sonnet 4.6 context window = **1M tokens** ✅，max output 64k
- Haiku 4.5 context window = 200k tokens（轻量审 ≤ 200K 文稿）

所有评审 subagent（Opus R2 / Sonnet R1）默认 1M 可用。长稿 > 1M tokens（极端情况）走 §9 分段 fallback；正常党政公文 / 咨询报告（最长 100K 字 ≈ 200K tokens）一次性派出即可。

source: https://docs.claude.com/en/docs/about-claude/models/overview （2026-05-27 抓取）

## §9 错误恢复 fallback

| 异常 | 主对话动作 |
|---|---|
| subagent 返回 malformed JSON / 空返回 | 主对话当 reviewer 自跑该视角一遍 + 在 `evals/layer3-convergence.jsonl` 记录 `fallback_used: true` |
| subagent timeout / refuse | 跳过该视角，不阻塞其他 reviewer 继续合并 |
| 长稿 > 200K tokens 且 Sonnet 1M 不可用 | 分段派多 Sonnet（每段 < 200K）+ 主对话汇总分段 finding，去重按 line_range 全局编号 |
| R1 全部返回空 finding | 跳 R2，写 jsonl 记录"无 L3 价值" |
| Edit 落地后 L1 scan 引入新违反 | 立刻回滚该 Edit + 在 finding 标 `regression_introduced: true` 进 v5.1.x patch backlog |

## §10 Context Budget 自检

| token 累积 | 主对话动作 |
|---|---|
| < 200K（< 20% 1M） | 正常推进 |
| 200K-500K（20%-50%） | 继续，但优先 Edit 落地不再无脑派 R1 |
| 500K-700K（50%-70%） | L3 评审完成立即 `/compact` 或写 handoff 后再 dogfood 下一篇 |
| > 700K | 当前 L3 run 收尾，禁止启 R2 / 下一轮 R1，主动 handoff |

防止 context bloat 影响后续判断质量。Anthropic Context Engineering 2026 共识：1M 不是"无限"——压缩窗口的合理使用比硬塞更重要。

## §11 jsonl 记录（每次 L3 run 结束 append）

主对话在 L3 run 收尾时往 [`../../evals/layer3-convergence.jsonl`](../../evals/layer3-convergence.jsonl) append 一行 JSON：

```json
{"ts":"2026-05-27T22:00+08:00","doc_id":"<short slug>","genre":"G8","adoption_rate":0.32,"convergence_rounds":2,"fallback_used":false}
```

可选字段（有数据就 append）：`reviewer_views` / `findings_total` / `kappa_d2_after` / `kappa_d5_after` / `wallclock_minutes`。

累积 10 次 L3 run 后用户/Claude 跑分析（L3 真实价值 vs L1+L2 单跑）。
