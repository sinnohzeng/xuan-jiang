# Changelog

All notable changes to xuan-jiang `writing-polish` skill are documented here. Format follows [Keep a Changelog 1.1](https://keepachangelog.com/en/1.1.0/), versioning follows [Semver 2.0](https://semver.org/).

> 历史段按当时状态记录，**不代表当前文件仍存在**（如 v5.x 的 `prompts/multi-agent/`、`config/default.yaml`、v6.x 的 `prompts/reviewer.md` / 0-3 评分链均已在后续版本移除或下沉离线）。当前状态以 `README.md` / `docs/status.md` / `SKILL.md` 为准。

## [7.0.1] — 2026-06-06（修复 install-blocking manifest）

### Fixed

- **`plugin.json` 删除 `"agents": "./agents/"` 与 `"skills": "./skills/"` 字段**。v7.0.0 为注册 `writing-reviewer` 子代理而手写了 `"agents": "./agents/"`，但 Claude Code 插件 manifest 不接受 `agents` 写成目录字符串，`claude plugin validate` 报 `agents: Invalid input`，导致 `claude plugin install writing-polish@xuan-jiang` 整体失败。agents / skills / commands 一律由 `agents/`、`skills/`、`commands/` 目录**自动发现**，无需在 manifest 声明（官方 feature-dev / pr-review-toolkit 即如此）。删除后 `writing-reviewer` 子代理与 `writing-polish`、`runse` 两个 skill 均正常加载。
- 行为零变化：仅修 manifest，技能与子代理内容不动。

## [7.0.0] — 2026-05-28（两世界拆分：per-use 自然语言反馈 + 数值评分下沉离线 + 任仲然立文实质轴）

### ⚠️ Breaking

- **评分链从 per-use 热路径整体移除**。每次改稿不再打 `0-3` 逐维分、不再写 `.writing-polish-trace/*.json`、不再 `max()` 汇总、不再有 5 维 mini-bar。改为 clean-context reviewer 返回**自然语言反馈 + 粗判闸门**（够好了 / 要改 / 红线未清）。依据：全行业改稿循环（Self-Refine / Reflexion / CRITIC / Constitutional-AI / Anthropic evaluator-optimizer cookbook）都用可执行 NL 反馈；数值逐维打分（G-Eval / Prometheus / MT-Bench）是**离线打榜**工具。
- **数值世界下沉 `evals/offline-harness/`**：`llm-judge-research-report.md`、`select-fewshot.sh`、`split-calibration.sh`、`scan-hard-gate.sh`、`eval-record.schema.json` 迁入，仅离线衡量 polisher 本身用。
- **删除** `prompts/`（整目录）、`prompts/reviewer.md`、`prompts/spot-check.md`、`schemas/reviewer-output.schema.json`、`scripts/auto-fix-loop.sh`、`.writing-polish-trace` 概念。
- **L3 reviewer 升级为 Claude Code 插件子代理** `agents/writing-reviewer.md`（只读工具 `Read, Bash, Grep`，结构性强制「只评不改」）；`plugin.json` 加 `"agents": "./agents/"`；`allowed-tools` 改 `Bash, Read, Edit, Write, Task`。
- **scan-output 契约版本** `6.0 → 7.0`（`scan-ai-taste.sh` + `schemas/scan-output.schema.json` const 同步）。
- **Rollback**：如需回到 v6.1 评分链，`git checkout` v6.1.0 tag。

### Added

- `agents/writing-reviewer.md`：clean-context 审稿子代理，按 立意 / 结构与论据 / 材料·事实 / AI味·标点 四焦点返回 `<feedback>` + `<verdict>`。
- **正向实质三焦点**（`constitution.md` §0.5）：立意 / 结构与论据 / 材料·事实——回应 Anthropic「单边评测导致单边优化」，补齐任仲然真正重视而 v6 缺失的「写得好」评价轴。
- **事实敬畏三态**（reviewer + Coach）：① 已有材料可证实 / ② 用户未提供需追问 / ③ 不得替用户编造。
- `references/coach-checkpoints.md`：Coach 监督生成弧（立意→构思→提纲→材料→结构，逐段 checkpoint）。
- `references/renzhongran-coverage-matrix.md`：任仲然《怎样写作》12 讲 → SKILL 行为 → reference → eval 的逐项继承审计矩阵。
- `evals/offline-harness/README.md` + `evals/README.md` 重写为「离线 dev-eval harness」。
- `split-calibration.sh` 非空 guard：`anchor=0` 时非零退出（code 4），杜绝 v6 那次 anchor 静默为空半年无人发现。

### Changed / Fixed

- **SKILL.md** 重写为 ~150 行：§0 两世界拆分 / §2.1 Coach 监督弧 / §2.2 Polish 4 步（L1 → reviewer → 串行改稿 → 验证）/ §4 四大审查焦点（替换 D1-D5 mini-rubric）。
- **constitution.md** 从「0-3 评分细则」改为「审稿判依据（好/差长啥样）」；D1-D5 折叠进单一「AI味·标点」焦点的四个面；剥离残留数值标签（`D4=2` 等）；§5 examples 保留为 before→after 参考对（双用途：reviewer 参考 + 离线 gold）。
- **reviewer-routing.md** 从「5 维→N reviewer」改为「焦点覆盖按长度/体裁分摊」，并发上限 5→3。
- **anchor 数据修复**：标 9 条 §5 人工 gold 记录 `verified: true`，`anchor-set.jsonl` 从 0 → 9，`eval-set.jsonl` 不再是 calibration 字节副本。
- **修正**：`scan-ai-taste.sh` 实际调用 `check-cn-quotes.py`，故后者保留（非冗余）；移除对已删 `auto-fix-loop.sh` 的提示。
- **文档债清零**：README 重写为 current-first（修 `min()`→反馈、删已不存在的 `evals.json`/`test-runner.sh` 文件树）；CONTRIBUTING 对齐 2026-05 官方 frontmatter（删 `effort`/`paths` 必填说法，修「直角引号」与国标矛盾）；TROUBLESHOOTING v4.2→v7.0；新增 `docs/status.md`；v4/v5 handoff + 过期 active memory + 旧调研归档至 `docs/archive/`。

## [6.1.0] — 2026-05-28（评分链可验证化：量纲统一 + L3 默认必跑 + few-shot anchor + L2 留痕）

### ⚠️ Breaking

- **评分量纲翻转**：1-5（5=最好）→ **0-3 + `"unknown"`**（3=最差）。汇总从 `min()` 反转为 `max()`（任一审稿人认为更差就以更差为准——保守裁判语义不变）。仅影响 `schemas/*.schema.json` 与 `SKILL.md` 文档；evals/calibration-set.jsonl 本就是 0-3 + unknown，无需迁移。
- **Rollback**：如需回到 v6.0 量纲，`git checkout release/v6.0-frozen`（已打 tag 锚定）。
- **frontmatter 收敛**：删除 `effort: max` + 非标 `paths` 字段；description 从 600 字收敛到 ≤ 80 中文字 + 触发词清单。
- **prompts/reviewer.md 输出格式 break**：reviewer 返回 JSON 新增必填 `source` 字段（`L2-self` / `L3-reviewer-clean` / `L3-spot-check`）。
- **anchor/eval 物理隔离铁律**：`evals/anchor-set.jsonl` 供 reviewer few-shot 注入；`evals/eval-set.jsonl` 供 κ / regression 测试。**禁止把 eval-set 注入 prompt**（防 Grader Gaming）。

### Added

- `scripts/split-calibration.sh`：一次性把 `calibration-set.jsonl` 按 `verified` 字段拆成 anchor-set / eval-set 两视图（不动原文件内容）
- `scripts/select-fewshot.sh`：deterministic（sha256(draft) 做 seed）+ 易难分层 + 同 commit 排除，供 reviewer prompt 拼 §4 few-shot anchor
- `prompts/spot-check.md`：step 5 用的轻量 reviewer（≤ 正式 reviewer 50% 字符），只评 D5
- `references/reviewer-routing.md`：mode × 体裁 × 长度 → reviewer 列表 decision table
- `references/resource-routing.md`：从 SKILL.md §5 外迁的详细资源路由表（progressive disclosure）
- `evals/README.md`：anchor / eval 物理隔离铁律 + 禁止 eval 注入 prompt 说明
- `.gitignore`：加 `.writing-polish-trace/`（L2 自评 trace 文件目录，默认不入版本控制）

### Changed

- **SKILL.md** frontmatter：description ≤ 80 中文字、删 effort:max、删 paths、加 `allowed-tools: Bash, Read, Edit, Write, Agent`
- **SKILL.md §0** 新增"Skill 速览"段（架构 3 行说清）
- **SKILL.md §1.2** 触发歧义解析：基于 draft 字数给推荐 + 给理由
- **SKILL.md §2.2 step 2**：L2 self-judge 必须 Write trace 文件到 `.writing-polish-trace/`，**未写文件 = L2 弃权 = 强制 L3 全维度兜底**
- **SKILL.md §2.2 step 3**：L3 触发改为"Polish mode 默认强制至少 1 reviewer（D5 spot-check）"；升级到 3 reviewer 的条件不变；分摊矩阵外迁 reviewer-routing.md
- **SKILL.md §2.2 step 5**：验证从"重跑 L1 + L2 自评"改为"重跑 L1 + spawn clean-context spot-check Agent"
- **SKILL.md §5** 资源路由表瘦身到 ≤ 10 行，详细路由外迁 resource-routing.md
- **SKILL.md §6** mini-bar 从 ASCII 满格条改为状态符号 `✓ ⚠ ✗ ?`（0-3 反直觉缓解）
- **schemas/reviewer-output.schema.json**：score 改 `oneOf: [integer 0-3, const "unknown"]`；新增必填 `source` 枚举
- **schemas/eval-record.schema.json**：L2 score 改 0-3 + unknown；`version` const 改 "6.1"；`protocol` 枚举加 "v6.1"
- **prompts/reviewer.md**：新增 §4 few-shot anchor 占位符 + 反作弊提示；retry 1 次（exponential backoff 2s）；spawn 进度行约定
- **prompts/llm-judge-research-report.md**：rubric 表头 + few-shot examples 量纲对齐 0-3（本身已是 0-3，仅检查一致性）
- **scripts/check-dependencies.sh**：新增循环依赖检查段（扫 references/ 反引 SKILL.md mode 关键词）

### Quality gates

- `bash scripts/check-dependencies.sh` 报 0 循环依赖
- `grep -rE "(1-5|0-5|min\()" plugins/writing-polish/{SKILL.md,schemas/,prompts/}` 应零命中
- 6 个 fixtures `bash scripts/scan-ai-taste.sh --target` 全过（量纲翻转不影响 L1 regex 层）
- description ≤ 200 byte；yaml frontmatter lint 过

## [6.0.0] — 2026-05-28（无历史包袱重构：协议化 SKILL + LLM 监督真落地 + 任仲然继承度补齐）

### TL;DR

v6.0 大刀阔斧重构，**无 backward compatibility 承诺**：
1. **诚实表述**：SKILL 描述明示 "LLM supervision = main Claude Code session itself, zero external API"，删除 v5.x 时期 plugin.json description 中"3-5 路 Sonnet R1 + 1 路 Opus R2 路由"等实际未生效的 marketing 承诺
2. **协议化 SKILL.md**：从决策树（v5.1 主对话现场领悟）改写为剧本（v6.0 主对话照步骤执行），Polish Protocol 7 步 + Coach Protocol 3 步 + Audit Protocol 2 步 + DOCX 桥接
3. **三契约层** schemas/：scan-output / reviewer-output / eval-record JSON Schema，让 L1/L2/L3 间 I/O 形状机器可校验
4. **scan-ai-taste.sh --json 真落地**：trap EXIT + Python heredoc 解析 stdout buffer，emit 符合 schema 的 JSON；同时加 `--target` 显式 flag + `--log-to` opt-in evolution-queue 日志
5. **prompts/reviewer.md** spawn 模板：L3 clean-context Agent 触发条件 + 占位符模板 + 严格 JSON 输出 + timeout/missing-vote fail handling + 汇总 min(L2,L3) 保守裁判
6. **任仲然继承度补齐**：覆盖率 65%→79%、深度 40%→55%，新增 `writing-coaching-arc.md`（L1§2 观察+L1§3 摹仿三段弧+L1§4 大胆写+L2§3 规律再造）+ `peer-vs-self-revision.md`（L12 改自己 vs 改他人辨证法）

### Breaking Changes（无 backward compatibility，按 plan v2 §1.1 用户明确意图）

- **删除** `scripts/{llm-judge-runner.py, model_adapter.py, self-refine-loop.py}` —— v5.x dev-only path，生产从未使用；保留至 v5.1 是误导
- **删除** `scripts/scan-ai-taste.sh` 中 `--llm-judge` flag —— v4.3 至 v5.1 留 3 版 stub 已是破窗，v6 自身就是 LLM 监督，flag 多余
- **删除** `prompts/multi-agent/` 整目录（包括 v5.1 的 `orchestration-guide.md`）—— 决策指南被 SKILL.md §2.2 Polish Protocol step 3 + `prompts/reviewer.md` 取代
- **删除** `references/layer3-walkthrough.md` —— v5.1 历史叙事，protocol 已内联到 SKILL.md
- **删除** `config/` 整目录（default.yaml + examples/gemini-gateway.yaml + qwen.yaml）—— YAGNI，v7 真有 BYOC 再加，零容忍 zombie code
- **删除** `docs/rfc/{v5.0-llm-judge.md, v5.1-multi-agent-orchestrator.md}` —— RFC 已被 v6.0 实施超越
- **scan-ai-taste.sh --json 输出格式 break change** —— v4.3 / v5.x 的 --json MODE 实际未实现（与 standard 行为相同），v6.0 真正输出符合 schema 的 JSON；外部调用方若依赖旧的 --json 文本输出会断（已 sweep 主要 callsite：cicpa 4.3.0 cached 路径 hard-coded 与本仓 v6 独立；sinnoh-kb 用占位符无需改）
- **归档** v5.x evals tooling 到 `evals/legacy/v5.x/`：README.md / calibration-runner.sh / cohen-kappa.py / extract-from-cicpa-commits.py / evals.json / test-runner.sh / gold-standard/ / calibration-results-baseline-v50rc1/ / calibration-results/ —— 全部依赖已删 dev-only 脚本

### Added

- **`schemas/scan-output.schema.json`** + **`schemas/reviewer-output.schema.json`** + **`schemas/eval-record.schema.json`** —— 三层 I/O 契约，draft-07 JSON Schema，约束所有 LLM/script 间数据形状
- **`prompts/reviewer.md`** —— L3 spawn 模板（150 行）：触发条件 / spawn 时机（单条消息内 3 Agent 并行）/ 占位符模板（{{DIMENSION_ID}}/{{DRAFT_TEXT}}/{{CONSTITUTION_SECTION}}）/ 严格 JSON 输出 / timeout 60s + JSON-malformed → missing-vote / 汇总 min(L2,L3)
- **`references/writing-coaching-arc.md`** —— Coach mode 主路径（217 行）：观察 5 分钟日课 + 画道道笔记法 + 摹仿→制造→创造 三段弧 + 信心建设 + 规律再造
- **`references/peer-vs-self-revision.md`** —— 改自己 vs 改他人辨证法（160 行）：冷读 24h + 距离感 3 技巧 + 不护短 + 自批 tone 对自己狠 + 他批先复述意图再外科手术 + L3 reviewer 必读 tone 自检表
- **`scripts/scan-ai-taste.sh`** flags：`--target <path>`（显式 file，与 legacy positional arg 共存）+ `--log-to <jsonl-path>`（opt-in v6.1 evolution-queue 日志）+ `--json`（真输出符合 scan-output.schema.json）
- **`evals/v6.0-baseline/comparison.md`** + 2 个 anchor 的 scan.json baseline —— v5.1 vs v6.0 process clarity / 任仲然继承度 对比 + release gate 决策

### Changed

- **SKILL.md** 90→212 行，从决策树重写为协议剧本：Prerequisites 前置声明 / Mode 路由 + 歧义解析 / 3 mode Protocols 步骤化 / D1-D5 mini-rubric 内联 / 红线 4 铁律速查 / 五权分立 + 单线程 writer 铁律 / Contracts 引用 / --log-to opt-in 说明 / load-when 路由表 / 输出格式固定 mini-bar
- **plugin.json description** 改诚实版：明示 zero external API 范式 + 三 mode + 三层架构 + 红线清单
- **marketplace.json** 同步：version 5.1.0→6.0.0 + description 与 plugin.json 一致
- **references/anti-ai-taste-anchors.md** 顶部：automation-level=regex-auto + SSOT relationship + 删 docs/rfc 死链 + v5.0 范式预告改为 v6.0 落地说明
- **references/constitution.md** 顶部：automation-level=claude-code-session-only + 与 SKILL.md §3 mini-rubric SSOT 关系 + load-when 说明
- **references/revision-checklist.md** 顶部：load-when + 来源
- **prompts/llm-judge-research-report.md** 顶部：v5.x 由 llm-judge-runner.py 加载 → v6.0 主对话 L3 spawn 时附加到 reviewer prompt

### Quality gates

- 6 个 fixtures 全部回归通过（drama-firewall / gov-duibiao / it-firewall / jargon-duibiao / long-form-density / short-form-density，context-aware whitelist 正确工作）
- 5 项 scan-ai-taste.sh --json smoke test 全过：legacy positional / --target + --json pass / fail case 红线分类 / --log-to 写合法 JSON line / 基本 shape 校验
- 任仲然继承度 65%→79%（覆盖率）/ 40%→55%（深度，5 个新增 deep 操作化原则）
- 总分 delta 10 维度全部持平或提升（详 evals/v6.0-baseline/comparison.md §5）

---

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
