# writing-polish 对齐 2026-07 最佳实践 · 调研沉淀

> 抓取日期：2026-07-03｜方法：firecrawl CLI（OAuth）｜审计对象：writing-polish v7.0.1
> 目的：为零历史包袱的 v8 重构提供依据。本文只沉淀“外部事实与借鉴点”，落地方案见 `docs/plans/2026-07-03-v8-refactor-plan.md`。
> 纪律：结论蒸馏不照搬；每条带来源；未来审计报“缺 TOC / 缺 X”先核本文再定。

## 目录

- [一、官方 2026-07 最佳实践基线](#一官方-2026-07-最佳实践基线)
- [二、官方对照缺口（Thread A）](#二官方对照缺口-thread-a)
- [三、社区集多家之长（Thread B）](#三社区集多家之长-thread-b)
- [四、确定性自证（主对话脚本核查）](#四确定性自证主对话脚本核查)
- [五、护城河与反面清单（绝不稀释）](#五护城河与反面清单绝不稀释)
- [六、来源档](#六来源档)

---

## 一、官方 2026-07 最佳实践基线

经典 5 原则（Concise / smart-default+escape-hatch / degrees-of-freedom / gerund 命名 / 第三人称 what+when 描述）不变但降为底座。2026-07 页面相较 2026-05 的**新增或演进**层（isNew）集中在六处：

1. **量化的渐进披露**：三级 token 模型：L1 元数据约 100 tok 常驻；L2 SKILL.md 正文 < 5k tok 且 < 500 行、触发时才载入；L3 references/scripts/assets 按需读、未读零 token。
2. **Evaluation-driven 升为一等公民**，且最锐的新要求是**两条分别度量的轴**：触发/路由准确性（should-fire vs should-not-fire 命中率）与产出质量，各自用“开 skill vs 停 skill”全新会话跑基线。
3. **避免深层嵌套引用**：所有 reference 从 SKILL.md 一跳直达；嵌套会诱发 Claude 用 `head -100` 预览导致读不全。
4. **> 100 行 reference 顶部放 TOC**，保证 partial read 时仍见全貌。
5. **Workflows + 反馈闭环**：复杂任务给可复制进回复逐项打勾的 checklist；validator→fix→repeat（validator 可以是脚本，也可以是 STYLE_GUIDE 型 reference）。
6. **内容纪律**：避免时效性信息（用 Current/Old patterns 承载历史）；术语全篇一致；用你打算用的所有模型测（Haiku 够不够指引 / Sonnet 清不清晰 / Opus 会不会过度解释）。

frontmatter 硬约束（会被校验）：name ≤ 64、仅小写字母数字连字符、禁保留词 anthropic/claude、禁 XML 标签；description 非空、≤ 1024、禁 XML 标签。子代理支持 `model:` 字段（官方示例均显式 `model: sonnet`）。`allowed-tools` 是官方 Claude Code 字段，另有 `disallowed-tools`。插件 manifest 里 agents/skills/commands 由**同名目录自动发现**，不得写成目录字符串（v7.0.0 曾因手写 `"agents": "./agents/"` 被 validate 判 Invalid input 而 install 失败，v7.0.1 删除修复）。

## 二、官方对照缺口（Thread A）

verdict：**writing-polish 与官方高度对齐，零 high 缺口**，多项达样板水准。真实增量：

| 优先级 | 缺口 | 方向 |
|---|---|---|
| **MED** | 离线 eval 只量产出质量，缺“触发/路由准确性”轴 | offline-harness 补触发校准集：should-fire（coach/polish/audit 各自）+ should-not-fire（翻译/代码/纯英文）+ 歧义词该走哪档，跑命中率 |
| **MED** | manifest description 受众错配：写成 v7.0 changelog + 内部术语 + 版本戳 | 换成简洁用户向文案，实现细节留 CHANGELOG/README，去版本戳；两处（plugin.json + marketplace）一致 |
| LOW | `allowed-tools` 授予无限定 Bash 免授权 | 收窄到 `Bash(bash *scripts/*)` `Bash(python3 *)` `Bash(pandoc *)` `Bash(cp *)`；Read/Edit/Write 因需改任意草稿保留 |
| LOW | writing-reviewer 缺 `model:` + Bash 可收窄 | 核实不调 Bash 后收敛 `tools: Read, Grep`；显式 `model:`（pin 强模型使审稿质量与写作会话解耦） |
| LOW | version + keywords 在 plugin.json 与 marketplace 重复声明（keywords 已漂移） | plugin.json 为唯一真源，marketplace 删冗余 version/keywords；发版 SOP 靠 `claude plugin validate` 兜底 |
| LOW | 无 `argument-hint`、正文无 `$ARGUMENTS` | 可选增益：`argument-hint: [草稿路径或文本] [mode]`，step1 前落 `$ARGUMENTS` |
| LOW | DOCX 把 `brew install pandoc`（全局装包）写进 Prerequisites | 定位为用户一次性可选预装；技能执行期绝不自动 brew；桥接前先 `check-dependencies.sh` 探测，缺则优雅跳过 |
| LOW | 未记录跨模型（Haiku/Sonnet/Opus）测试覆盖 | evals/README 补一行模型覆盖说明（文档补全，不改热路径） |
| LOW | 7 篇 reference 仅经 resource-routing.md 中转，距 SKILL.md 两跳 | 把每次 Polish 必用的 revision-checklist.md、logic-and-structure.md 提到 SKILL.md 直链；长尾留 hub，hub 顶注“命中后整读勿预览” |

## 三、社区集多家之长（Thread B）

巡览 humanizer / voice-editor / copy-editing / strategy-document / auto-paper-improvement-loop / 中文 humanizer 等。**HIGH 优先借鉴**（中文原生重建，非英文直译）：

1. **空话可证伪测试**：对每句问“把主体换成同行业任何一家，这句还成立吗？”成立即“正确的废话”，必须改到带具体数字/专名/事例。补现有黑名单抓不到的“加强领导、狠抓落实、扎实推进”类语法合规空转句。与不打数值分立场兼容（质量闸而非打分）。〔strategy-document〕
2. **L1 硬扫三扩**（纯 grep、成本极低命中率极高，中文原生）：① AI-tell 句式：“而是”及变体（不是…而是/并非…而是/与其说…不如说，negative parallelism 的中文对应）；② 协作路标词：让我们/接下来/首先其次再者/综上所述/值得一提的是（把“去客服腔”从人工判断升级为确定性拦截）；③ 中文赘余。〔OUBIGFA / blader #9#28 / shyuan #29〕
3. **中文结构性 AI-slop 清单**（#25-31，从真实中文语料反推公文黑词表覆盖不到的结构层）：大纲骨架代替成段散文、粗体四字标签+冒号排比清单、句内关键词排比粗体、元论述导读宣告、升华训诫式结尾+金句叠句。#31 承重隐喻难自动化，保留人工三信号叠加判定。〔shyuan/writing-humanizer〕
4. **双侧校准**：显式命名“过度去味→无声/无菌”为与 slop 对称的失败态；把“别为骗过 AI 检测器而改”写成非目标；去味用作者/语料自身模式替换而非升级成“更好的词”。修现有设计暗坑（黑词表+任仲然锚只朝一个语域收敛，润随笔会抹平个性成通用腔）。〔voice-humanizer / blader Lisbon / voice-editor〕
5. **事实敬畏护城河锐化**：① 新增“推断/预测”第四态：断言旁就地挂前提（“$50K MRR”须补“假设 15% 月增”）；② 把“润色不得新增事实”从价值观升级成对 diff 的可执行守卫（润色最危险的失败=顺手加原文没有的事实）。与全局“推断≠事实”、信息源四档标注同源。〔strategy-document / auto-paper-improvement-loop〕
6. **评审独立性协议**：① 范文/公文锚本绝不喂进 reviewer 线程（“锚越强越危险”，会退化成模仿度打分）；② “上轮改了什么”叙事不喂 reviewer（实证：带此提示能把真实 3/10 吹成假 8/10）。writing-reviewer 机制已 clean-context，但这两条操作律未成文、极易违反。〔auto-paper-improvement-loop〕
7. **回归守卫式迭代**：Polish 从一趟混合通改重排为有序单维 sweep（达意→空话→标点体裁），每治完第 N 维回头复验 1..N-1，防“我刚改坏的” scan 复查不出。只搬元结构，情绪/风险/转化维不迁移。〔copy-editing Seven Sweeps / auto-paper-loop Step4 recompile-verify〕

**MED 借鉴**（择要）：L1 黑词配到位替换（报警器→修理工）；扫描输出 evidence span + 分文体阈值 profile；标点预算/quota（genre 分档，破折号不禁只配额）；对照范例三列格式（含“过度改写”负样本列）；语料 allowlist 压误报（直击 memory 记录的头号假警报痛）；**声音匹配能力**（genre 门控，只对随笔/个人自述开，仪式感三档：临时贴样本→6 维观察清单→可选落盘 VOICE 画像；核心 reframe “不像 AI ≠ 像我”）；So-What 收口段强制；每体裁尾挂“常见跑偏”反模式清单；coach 按目的/受众反推体裁；coach 给带理由多选项不替写；评审反馈逐字留痕不许 writer 转述稀释；高影响操作走 checkpoint；终轮对抗 kill-argument（仅论点重的稿、fresh-thread、detect-only）；改动率作技能自诊断信号。

**LOW 借鉴**：constitution 护栏“别把润色循环套 /loop /schedule Cron”（质量随评审变不随时钟变，self-acquittal 是可疑收敛判据）；SKILL 写法“讲清 why 替代 ALL-CAPS MUST”+“理性化陷阱/红旗段”；description 补 CN 热词触发器（去 AI 味/AI 感/读着像 AI 写的）；scan 接 pre-write hook（仅自查，非合规 gating）。

## 四、确定性自证（主对话脚本核查）

主对话用 grep/find 机器核查，用于反查 agent 的假阳/假阴：

- **3 个 > 100 行 reference 确缺顶部 TOC**：failure-cases.md(206) / peer-vs-self-revision.md(173) / writing-coaching-arc.md(221)。⚠️ Thread A agent 声称“全部已带 TOC”系过度声称，**以本条脚本核查为准**。其余 9 个 > 100 行文件确有 `## 目录`。
- **引用二跳实况**：resource-routing.md 内引 16 个、renzhongran-coverage-matrix.md 内引 11、constitution.md 内引 7。resource-routing 是二跳巨型枢纽。
- writing-reviewer frontmatter 现为 `tools: Read, Bash, Grep`，**无 `model:`**。
- description 字符数：SKILL.md 336 / runse 133 / reviewer 368 / plugin.json 276 / marketplace 421，**均远低于 1024**（无违规）。
- `allowed-tools` 为官方字段名（用对了）；runse `disable-model-invocation: true`（用对了）。

## 五、护城河与反面清单（绝不稀释）

writing-polish 相对社区的三大硬核，重构中不得为借鉴稀释：① 深度中文特化（GB/T 15834 标点、中文公文红线、任仲然实质轴、七体裁 genre-guide）是唯一差异化；② 事实敬畏（可证实/需追问不替写/不得编造，现加推断标前提）优先级高于“读起来流畅”；③ reviewer 只给自然语言+粗判、数值评测隔离 offline-harness，比社区主流 per-use 打分更成熟。

**不该抄（anti-patterns）**：per-use 数值评分（诱导刷分）；为骗 AI 检测器而改；英文技法硬套中文（em-dash 一刀切禁用会误伤中文破折号合法用法，30-40% 改动率/冒号 ≤N 等英文标定数字不当硬阈值）；牺牲事实敬畏换流畅；锚本喂评审；堆砌铁律墙（arxiv 2507.11538：指令数↑跟随度↓）；刚性多遍 pass pipeline；双语通吃（摊薄中文护城河）；向量检索 ChromaDB（单人小工具过度工程）；装饰 emoji 收尾；/loop 包裹自收敛循环。

## 六、来源档

**官方（docs.claude.com，2026-07-03 抓取）**：
- agent-skills/best-practices、agent-skills/overview
- claude-code/skills、slash-commands、plugins、plugin-marketplaces、sub-agents

**社区（2026-07-03 抓取）**：
- dev.to/dannwaneri/why-i-built-my-own-humanizer-and-why-you-should-too-2a9e（voice-humanizer 方法论）
- github.com/blader/humanizer（33-pattern before/after + Voice Calibration）
- github.com/shyuan/writing-humanizer（中文结构性 slop #25-31 + 理性化陷阱段）
- github.com/OUBIGFA/De-AI-Prompt-Enhancer-Writer-Booster-SKILL（禁“而是”/协作路标词、标点预算、双模第一人称、三列对照）
- github.com/aplaceforallmystuff/claude-voice-editor（VOICE.md 声纹档 + 声音漂移 + 30-40% 规则）
- github.com/shishirui/awesome-claude-skills-zh（中文 skill 榜）
- ComposioHQ/awesome-claude-skills · content-research-writer
- davila7/claude-code-templates · copy-editing（Seven Sweeps）
- jezweb/claude-skills · strategy-document（可证伪 specificity test / So-What / per-mode 反模式）
- wanshuiyin/Auto-claude-code-research-in-sleep · auto-paper-improvement-loop（评审独立性协议 / recompile-verify / kill-argument）
- Medium data-science-in-your-pocket《Best Claude Skill: Humanizer》（6 维 Voice Calibration）
- Reddit r/ClaudeAI《I tested 30 community claude skills for a week》
- 另及：jman4162/slopscore（evidence span + genre profile）、conorbronsdon/avoid-ai-writing（43 坏词→好词）、lipex360x Skill Authoring Guide、scandnavik/writing-harness（Hook 联动）

**本机确定性核查**：主对话 grep/find（第四节），2026-07-03。
