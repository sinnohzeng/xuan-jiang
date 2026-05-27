# Changelog

All notable changes to xuan-jiang `writing-polish` skill are documented here. Format follows [Keep a Changelog 1.1](https://keepachangelog.com/en/1.1.0/), versioning follows [Semver 2.0](https://semver.org/).

## [5.1.0] — 2026-05-27（晚间，v5.0.0 当日大刀阔斧重构）

### TL;DR

v5.1 大刀阔斧重构 Layer 3 多智能体审校：从 5 个带 `{{}}` 占位符的模板（违背"主智能体判断决策"原则）砍成单一 `orchestration-guide.md` 判断指南（10 段，主对话自主决定派几个 reviewer + 哪几维 + 模型路由）。同时扩 D5/D4 few-shot 8 例（v5.0 calibration disagreement 反例直接落地）+ SKILL.md 344→90 行（Anthropic Progressive Disclosure）。**遵循 Anthropic Multi-Agent System 2025-06 "teach orchestrator how to delegate" + Cognition Devin 2026-04 clean-context 范式。无 release acceptance gate，灰度上线。**

### Added

- **`prompts/multi-agent/orchestration-guide.md`** —— 196 行 10 段单一判断指南，替代 v5.0 的 5 个 placeholder 模板。教主对话怎么思考：何时启 L3 / 派几个 reviewer / 视角组合 / Agent 工具具体语法 / Pre-mod 触发 / R2 fresh-eye 触发 / 收敛判停 / 模型路由 / 错误恢复 fallback / Context Budget 自检
- **模型路由实装**（v5.1 用户明确要求）：1 主 Opus 4.7 orchestrator + 1 路 Opus 4.7 R2/Pre-mod + 3-5 路 Sonnet 4.6 R1。**Anthropic Multi-Agent System 2025-06 "Opus lead + Sonnet subagents" 范式落地**。Opus 4.7 + Sonnet 4.6 均默认 1M context（2026-05-27 firecrawl 实测 Anthropic docs 锚定）
- **`references/layer3-walkthrough.md`** —— 282 行完整 worked example，350 字虚构 G8 咨询报告从 L1→L2→L3 全流程跑通：自主决策 / spawn 3 Agent / finding JSON / P0-P5 排序 / 决策三问 / Edit 串行倒序 / 收敛判停 / jsonl append / 交付报告
- **`references/constitution.md` §5 Example G-N** —— 8 个新 few-shot example 直接来自 v5.0-rc1 calibration disagreement 真实反例：G (D5 充分+大幅+不再仅仅是) / H (D5 不仅否定平行) / I (D5 段首首先过渡套话) / J (D5 经济学抽象化+充分) / K (D5 深入演变叙述) / L (D4 复盘 G8 违规) / M (D4 复盘跨文体对照) / N (D1 半角括号紧跟英文)
- **`references/constitution.md` §6.1 G3/G8 D5 模糊副词专属雷达** —— 4 类信号清单：模糊副词堆砌 / 否定平行 / 段首过渡套话 / 经济学抽象化
- **`references/constitution.md` §6.2 D4 同词跨文体条件判决表** —— 6 个大厂内训词在 G1/G2/G7/G3/G8 不同文体下判决矩阵
- **`references/constitution.md` §2.8 §1.8.6 大厂内训词侵入红线**（v5.1 新增）—— "复盘 / 拉通 / 对齐颗粒度 / 跑通 / 收口" 在 G8 咨询报告语境出现 → D4 ≥ 2
- **`references/constitution.md` §1.2 D2 套话清单加"复盘"** —— 同词跨文体条件判决（G2 大厂内训合法 / G8 咨询违规）
- **`prompts/llm-judge-research-report.md`** 同步加 §1.8.6 + D5 模糊副词雷达 + D4 同词跨文体表 + Example G/H/L/M 4 个新 few-shot
- **`evals/layer3-convergence.jsonl`** —— L3 收敛跟踪 schema 5 核心字段（ts / doc_id / genre / adoption_rate / convergence_rounds / fallback_used）+ 可选扩展字段（reviewer_views / findings_total / kappa_d2_after / kappa_d5_after / wallclock_minutes）
- **`evals/README.md`** L3 段 —— v5.1 calibration 策略走 dogfood（不调 BYOM API）+ Example G-N 来源 segment 对照表 + Layer 3 walkthrough 指引
- **SKILL.md §1 3 mode 路径** —— 协助写作 / 轻润色 / 中度修改 / 深度审稿 4 档对应 L1 only / L1+L2 / L1+L2+Self-Refine / L1+L2+L3 启用矩阵

### Changed (Breaking)

- **`prompts/multi-agent/` 5 个 placeholder 模板全部删除**（git rm）：`r1.md` `r2.md` `pre-mod.md` `orchestrator.md` `_task-spec-skeleton.md`。改为单一 `orchestration-guide.md`。**无兼容动作**——v5.0.0 用户必须按 orchestration-guide.md 重写自己的 L3 调用流程
- **SKILL.md 344 → 90 行**（Anthropic Progressive Disclosure 铁律）：外迁 DOCX 决策树 → docx-editing-guide.md / 写作 5 步法 → writing-methodology.md / 审稿 3 步法 → revision-checklist.md / L1 三小节 → anti-ai-taste-anchors.md / L2 执行步骤 → constitution.md / L3 步骤 → orchestration-guide.md / 修改哲学 → revision-checklist.md。SKILL.md 只保留路由与决策树
- **L3 模型路由从 hardcode 文本升级为引用 config/default.yaml** —— 未来换 Haiku / Gemini / DeepSeek 走 BYOM 改 config 即可，本指南不动

### Inherited from v5.0.0

- 三层 hybrid 架构（L1 硬 Gate / L2 LLM Judge / L3 多智能体）核心不变
- 模型解耦原则（主对话即 orchestrator，零外部 API 调用）不变
- 14 个 references/ 文件保留（ai-taste-examples / anti-ai-taste-anchors / failure-cases 等无重叠合并需求）
- v4 `scripts/scan-ai-taste.sh` + v5 `scripts/scan-hard-gate.sh` 共存（前者交付前完整版扫描，后者 CI 强制 30 条最小集）
- `scripts/llm-judge-runner.py` / `model_adapter.py` / `self-refine-loop.py` dev-only 标记保留
- `assets/anchor-essays/` (8 篇) + `assets/real-world-anchors/` (11 篇) 19 个真实样本全保留

### v5.1 Calibration 策略

**不跑 calibration-runner.sh 的批量 BYOM 复测**——理由：（1）违反全局铁律"永远不通过 Anthropic API 调用 Claude（太贵）"；（2）v5 生产路径已是主对话即 judge（不依赖外部 LLM API）；（3）灰度上线策略明确"不卡 κ 阈值，dogfood 期主对话实战观察"。

**实际复测路径**：v5.1 alpha 灰度期，用户写真实党政公文 / 咨询报告时，主对话按新 prompt 执行 L2 评分，遇到 v5.0-rc1 calibration disagreement 中标注过的 segment（cicpa-349bf83-before-0004 "充分认识" / cicpa-6d25ff5-before-0052 "复盘"），主对话应判出 D5=2 或 D4=2。如仍判 0 → 进 v5.1.x patch backlog。

### 架构 self-check（Anthropic 6 范式 + Context Engineering 4 技巧 + Cognition 单线程）

- ✅ Augmented LLM（L2 主对话 inline judge）
- ✅ Chaining（L1→L2→L3 三层链）
- ✅ Routing（文体 G1-G8 + 三层启用条件）
- ✅ Parallelization（L3 多 reviewer subagent 单 message 并行 spawn）
- ✅ Orchestrator-Workers（主对话 Opus + Sonnet R1 + Opus R2）
- ✅ Evaluator-Optimizer（L3 收敛判停 < 20% 采纳率）
- ✅ Compaction（200K token 自检主动 compact）
- ✅ Note-Taking（layer3-convergence.jsonl）
- ✅ Sub-Agent（L3 clean-context，仅返回 JSON）
- ✅ Just-in-Time（references/ 按需读）
- ✅ Cognition 单线程 writer（主对话单线程 Edit，subagent 不并发写）

6 范式全覆盖，4 技巧全覆盖。无过度工程化（不加 commands/ slash / MODE_REGISTRY / ARCHITECTURE.md，留 v5.2 评估）。

### v5.1 实战观察清单（dogfood 期记录到 v5.1.x patch backlog，非 release gate）

- 多智能体派遣过程主对话是否真"自主决定"（无 placeholder 填空感）
- 至少 3 路 Sonnet R1 真并行（单 message multi tool call）
- 至少 1 路 Opus R2 或 pre-mod 真派出
- finding 采纳率（观察值）
- 收敛轮数（观察值）
- 整体耗时（观察值）
- `evals/layer3-convergence.jsonl` 首条记录写入

### Verified（2026-05-27 firecrawl 实测）

- Claude Opus 4.7 context window = **1M tokens** ✅，max output 128k
- Claude Sonnet 4.6 context window = **1M tokens** ✅，max output 64k
- Claude Haiku 4.5 context window = 200k tokens
- source: https://docs.claude.com/en/docs/about-claude/models/overview

### Migration

- 升级到 v5.1.0：**无需**改任何 env vars / yaml config
- 之前依赖 placeholder 模板的 `prompts/multi-agent/{r1,r2,pre-mod,orchestrator,_task-spec-skeleton}.md` 用户 → 改读 `prompts/multi-agent/orchestration-guide.md`，按其 10 段指南自主组装 Agent 工具调用
- 旧 placeholder 模板已 `git rm`，git 历史可追溯

---

## [5.0.0] — 2026-05-27

### TL;DR

模型解耦三层 hybrid 上线：L1 硬 Gate（脚本零模型）+ L2 LLM Judge（主对话执行，零外部 API）+ L3 多智能体审校（clean-context subagent）。对标 Anthropic 官方 `doc-coauthoring` SKILL 范式（纯 markdown instructions，0 行 API 调用代码）。

### Added

- **Layer 2 / LLM Judge 主对话执行范式**（SKILL.md §4.4）：Claude Code 当前主对话模型即 judge 模型，自动跟随 IDE 模型升级。不调 API、不读 `~/.config/xuan-jiang/config.yaml`、不需要 BYOM env vars
- **Layer 3 / 多智能体审校 5 个 prompt 模板**（`prompts/multi-agent/`）：
  - `_task-spec-skeleton.md` — 评审任务书六要素骨架（角色 / 路径 / 维度 / 约束 / 输出格式 / 输出上限）
  - `r1.md` — 3-5 视角并行评议（事实 / 文风 / 咨询身份 / IA / a11y），clean context 反推 spec
  - `r2.md` — fresh-eye 反查，不传 R1 trajectory（Cognition 2026-04 + Devin 实证范式）
  - `pre-mod.md` — 动笔前方案审议（绿黄红灯结论 + 替代路径）
  - `orchestrator.md` — 主对话整合 finding 的 P0-P5 优先级 + 决策三问 + 收敛判停（21% 采纳率 / severe=0 / 5 轮硬上限）
- **SKILL.md §4.5 Layer 3 触发条件**：opt-in / ≥ 3000 字 / 高 stakes 文体 / Layer 2 连退 2 次
- **SKILL.md §4.5 决策三问机械化 checklist**：违反 SSOT 吗 / 颗粒度增益吗 / 重复加严吗
- **§4.2 三层架构总览表**：明确各 Layer 角色 / 谁执行 / 何时跑 / 模型依赖

### Changed (Breaking)

- **生产路径不再调外部 API**：v4.3 / v5.0-rc1 的 `scripts/llm-judge-runner.py` + `model_adapter.py` + `self-refine-loop.py` 标记为 **DEV-ONLY**，仅用于 `evals/calibration-runner.sh` 跨模型一致度回归。下游若 import 这些脚本作 library 使用会断（cicpa 项目已验证无依赖）
- **plugin.json description** 重写突出模型解耦三层 hybrid
- **keywords** 新增 `llm-as-judge`、`multi-agent-review`、`model-decoupled`、`hybrid`

### Inherited from v5.0-rc1（2026-05-20 Sprint 1 已 ship 但未发版）

- `references/constitution.md`（377 行，5 维 rubric 成文宪法，按 8 文体切片）
- `prompts/llm-judge-research-report.md`（咨询报告 5 维 rubric judge prompt）
- `evals/calibration-set.jsonl`（173 段 cicpa auto-baseline）
- `evals/cohen-kappa.py` + `evals/calibration-runner.sh`
- baseline κ = 0.368（详 `evals/calibration-results-baseline-v50rc1/`）：D2/D3 真校准胜利 κ=1.0、D5 模板感 74.5% 是 v5.1+ 改进目标

### Sprint 2 决策（接受 baseline ship）

Sprint 2 (2026-05-21) 加 8 段党政公文对标范例的 v5.1 prompt 尝试 FAIL（D5 几乎无变化 74.5%→74.1%、overall κ 退步 0.368→0.307、唯一亮点 D4 κ 从 0 跃至 0.655）。结合猪猪老公 2026-05-27 决策"模型解耦 + 尽快上线 + 不纠结小细节"，v5.0.0 stable 接受 v5.0-rc1 baseline。κ 数值改进留给 v5.1+，本版聚焦把范式跑通到 Claude Code 用户手里。

### Verified

- SKILL.md 重写后 270 → 344 行（HumanLayer ≤ 400 行可接受）
- 5 个 multi-agent prompt 文件落盘，每个 < 250 行
- 3 个 deprecated 脚本头部加注释，evals 期仍可调
- plugin.json / marketplace.json 版本 + description + keywords 三处同步
- cicpa 项目无 import 旧 runner 依赖（`grep -rln "llm-judge-runner\|model_adapter\|self-refine-loop" ~/Workspace/cicpa` 无命中）

### Migration

- 升级到 v5.0.0 后**无需**改任何 env vars / yaml config
- 之前依赖 `XUAN_JIANG_JUDGE_BASE_URL` 等 BYOM env 的用户：env 仍兼容（dev-only calibration 脚本继续支持），但生产路径不再读
- cicpa 等下游项目直接拉新版即可，不需要改集成代码

---

## [4.3.0] — 2026-05-08

### Added

- **Context-aware whitelists**：scan-ai-taste.sh 新增 `count_with_context_whitelist` 通用函数，命中行 ±2 行扩窗匹配白名单关键词
  - §1.5.1「防火墙」在 IT 实物语境（机房 / 等保 / GB/T 22239 / WAF / NGFW / 入侵检测 / 部署 N 台 等）自动豁免
  - §1.5.2「对标」在党政咨询语境（政府工作报告 / 党中央 / 二十大 / 同级 / 国际先进 / 启示 / 经验 / 案例 等）自动豁免
- **Dynamic density thresholds**（§4 软阈值动态化）：按句子数计算阈值，不再固定 ≤ 3
  - 短文 < 200 句 → 阈值 ≤ 3（保持原阈值）
  - 中文 200-500 句 → 阈值 ≤ 6
  - 长文 500-1000 句 → 阈值 ≤ 9
  - 超长 ≥ 1000 句 → 阈值 ≤ 15
- **§1.8 咨询报告专属约束**（5 条）：第三方咨询机构对甲方交付物专用，含身份边界 / 结论先行 / 不背书厂商 / 「其一/其二」分级 / 多方利益静默
- **§1.4.111 合规括号 7 类白名单**（docs-only）：法条文号 / 施行日期 / 缩写首释 / 表格备注 / 图表内嵌 / 计算说明 / 章节自引
- **6 篇新增锚本**（assets/real-world-anchors/）：
  - `06-cicpa-consulting-template.md` — 第三方咨询机构对甲方交付范本（cicpa 053 治理后）
  - `07-sic-digital-economy-report.md` — 国家数据局《数字中国发展报告（2024）》
  - `08-cyberspace-info-development.md` — 网信办《国家信息化发展报告（2024）》
  - `09-cicpa-info-plan-2021-2025.md` — 中注协五年信息化规划（甲方反向对照）
  - `10-ndrc-high-quality-development.md` — 发改委高质量发展新闻发布会发言
  - `11-gov-work-report-duibiao.md` — 北京 2024 政府工作报告「对标」用法
- **evals 双轨化**（evals/evals.json + test-runner.sh）：
  - 保留 LLM 行为测试（`tests` 数组）
  - 新增 `regression_fixtures` 数组：scan 脚本回归测试，6 条 fixture 入库 evals/fixtures/
  - test-runner.sh 加 regression 跑批分支，自动比对 exit code
- **--llm-judge flag stub**（v5.0 范式播种，本版仅打印 RFC 提示）
- **docs/rfc/v5.0-llm-judge.md** RFC：LLM-as-judge 混合架构设计（rubric 5 dimension + Haiku 4.5 prompt + cicpa calibration set + cost 估算）
- **CHANGELOG.md**（本文件）：补回 v4.0 至 v4.3 演进史
- `.gitignore` for evals/regression-log.md（避免追踪每次运行产物）

### Changed

- references/anti-ai-taste-anchors.md 同步 v4.3 改动（§1.4.111 加白名单说明 / §1.5.1 加防火墙白名单说明 / §1.5.2 加对标白名单说明 / §1.8 新增 / §4 阈值文档同步 / §6 锚本资产清单更新到 11 篇 / 顶部加 v5.0 范式预告）
- suggest_for 文案分语境：drama / jargon 各加 IT / 党政语境提示行
- plugin.json + marketplace.json bump 4.2.0 → 4.3.0，description 加 v4.3 关键词

### Verified

- cicpa 053 实战回归：
  - WS3 完整版（1418 句，9 处 IT 防火墙）→ §1.5.1 0 命中 PASS
  - WS1 完整版（908 句，对标用法）→ §1.5.2 0 命中 PASS
  - 长文密度阈值合理放宽（≤ 15）不再勉强
- 6 条 regression_fixtures 全 PASS（含 2 条反向哨兵防漏检）

---

## [4.2.0] — 2026-04-30

### Added

- 230+ anti-AI-taste rules（156 红线 + 60 橙线 + 17 结构反模式）
- §1.6 元注释 / 客服话术红线（5 类，含元注释开头 / 自我介绍 / 免责声明 / 服务话术段尾 / 拟人化集体代词）
- §1.7 Wikipedia 长尾盲区（Reference markup bugs / Placeholder dates / Inline-header / Thematic breaks）
- §1.4 标点新增 4 条（v4.2）：每段加粗冒号开头 / 数字 list 滥用 / 标题化偏好 / 英文标点穿插
- evals/evals.json + test-runner.sh + regression-log.md 体系
- 8 篇 anchor-essays + 5 篇 real-world-anchors

### Changed

- 句长方差检测 + 分组密度报表（按 §1.1-§1.7 章节累计）
- check-cn-quotes.py 外置中文标点 / 中英混排检测
- scan-ai-taste.sh 新增 --suggest-fix / --json 模式

---

## [4.1.0] — 2026-04-25

### Added

- §1.5 戏剧化 / 互联网大厂黑话 / 网络口语 / 程序员产品经理腔（4 子节）
- GB/T 15834 弯引号强制 + 直角引号禁用
- 14 条标点 / 数学符号 / 半中半英新红线

---

## [4.0.0] — 2026-04-20

### Added

- 大刀阔斧重构：110 条 AI 味硬约束 + 8 范文锚点 + 三层防御机制
- references/anti-ai-taste-anchors.md 主文件
- scripts/scan-ai-taste.sh AI 味自检脚本
- 7 大文体专属审稿标准（公文 / 述职 / 演讲 / 调研报告 / 自媒体 / 散文 / 学术）
