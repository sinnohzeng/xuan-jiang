# Changelog

All notable changes to xuan-jiang `writing-polish` skill are documented here. Format follows [Keep a Changelog 1.1](https://keepachangelog.com/en/1.1.0/), versioning follows [Semver 2.0](https://semver.org/).

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
