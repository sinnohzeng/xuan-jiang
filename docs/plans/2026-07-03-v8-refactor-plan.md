# writing-polish v8.0 重构计划 v4（零历史包袱 · 已过 R1/R2/R3 三轮 clean-context 评审 · 已收敛）

> 依据：`docs/research/2026-07-03-best-practices-alignment.md`
> 决策（用户 2026-07-03 拍板）：① 破折号一律禁（含中文成对，硬红线 =0，无配额）；② 全量 v8 一次做完；③ 声音匹配做 tier-1+tier-2（tier-3 缓）。
> **收敛轨迹**：R1 逼出架构级大改（v1→v2）；R2 三镜头逮 6 major + 6 minor（v2→v3）；R3 三镜头全判 converged、零新 major，仅 6 条 minor 尾注（v3→v4 本版折入）。全部事实断言经 grep 亲验为真（argument-hint=0 / $ARGUMENTS 仅 runse / scan-hard-gate v5.0 / eval-record 双版本 enum / constitution §0 G1-G8 名串）。
> R2/R3 实测结论（写死，勿再推翻）：`claude plugin validate` **根本不 lint SKILL.md frontmatter**（argument-hint/假工具/非法 Bash 全 clean-pass）；skill 卫生只能靠约定 + grep 自检 + 人审，validate 只保 manifest 层。曾犯三类 v2 硬伤已修：(1) 非法权限语法 `Bash(bash *scripts/*)` → 裸清单；(2) canonical genre 锚错文件 → 锚 constitution §0；(3) G 码门控与语义标签双判据 → 纯 G 码单判据。
> 护城河铁律：深度中文特化 / 事实敬畏 / per-use 不打数值分，绝不为借鉴稀释；不堆铁律墙；确定性归脚本、判断归 reviewer。

## 0. 关键认知修正（评审逼出，v1 曾错）

1. **scan 现状被误读**：`scan-ai-taste.sh` 已 744 行，已实现 `不是…而是`(L361)、`让我们共同`(L590)、`综上所述/值得一提`(L387)、`--suggest-fix`、破折号 `——|—`(L299)、**密度软阈值** `threshold_for_length`(L254)、上下文白名单(L219)。WS-1 不是“新增三轴”，而是“对现状逐条 diff 后补真缺口 + 修误报 + 结构化改造 + 统一版本”。
2. **误报是头号风险**：把 `不是…而是`/`让我们` 当零容忍红线会在最该服务的讲话稿/随笔锚本上误报爆炸（实测 02-grain-speech‘让我们共同努力’命中）。这些是密度/语境判断题，归 L2/L3，L1 只用现成密度阈值。
3. **两套 scan 已漂移**：`scan-ai-taste.sh`（生产，含白名单）与 `evals/offline-harness/scan-hard-gate.sh`（v5.0，30 条 codepoint，无语境豁免，JSON 形状不同），须先决策合并/分界。
4. **genre 分类三处不一致，真源是 constitution §0**（R2 zh-moat 修正 v2 锚错）：genre-guide 7 类、eval-record enum 9 类、constitution §0 的 G1-G8 表三处名串不一致（eval-record‘规范公文/讲话稿/汇报发言稿/咨询报告’vs constitution‘规范性公文/领导讲话稿/汇报稿和发言稿/第三方咨询报告’，且 eval-record 无 G 码）。**canonical G-code 锚在 constitution §0**（G1-G8 已成型且被 reviewer/agent/llm-judge 全线引用），其余三处（eval-record/genre-guide/scan）反向对齐 constitution 精确名串。
5. **官方对齐工作量其实很小**（WS-5/6/7），真正高回归风险在 WS-1/2/3（产品扩张）。全量做，但产品扩张部分逐 WS 多轮对抗审阅 + 每步机器闸。

## 1. 变更总览（8 工作流，全做）

| WS | 主题 | 风险 | 优先 |
|---|---|---|---|
| WS-5 | 引用拍平 + 补 TOC（评审核实正确，先落） | 低 | P0 |
| WS-7 | 打包 / manifest 卫生 | 低 | P0 |
| WS-1 | scan 逐条 diff + 补缺口 + 修误报 + 结构化 + 版本统一 | 高 | P0 |
| WS-2 | constitution / reviewer 实质轴锐化 | 中高 | P0 |
| WS-3 | Polish 协议重排为回归守卫式迭代 | 中 | P1 |
| WS-4 | 声音匹配 tier-1+tier-2（G6/G7 门控） | 中 | P1 |
| WS-6 | 离线 eval 补触发/路由轴 | 低 | P2 |
| WS-8 | 文档债 + 版本统一 + 全局更新 | 低 | P3 |

## 2. 各工作流细化（v4）

### WS-5 · 引用拍平 + 补 TOC（P0，评审核实正确照做）

- 把每次 Polish 必用的 `revision-checklist.md`、`logic-and-structure.md` 从 resource-routing.md 二跳提到 SKILL.md §5 一跳直链；长尾留 hub，hub 顶加信号‘命中后整读该文件、勿 head 预览’。**只加一跳直链、不内联正文**（不撑破 SKILL.md）。
- 3 篇缺 TOC 文件补顶部 `## 目录`：`failure-cases.md`、`peer-vs-self-revision.md`、`writing-coaching-arc.md`。
- 脚本复核所有 SKILL.md→reference 为一跳（不信 agent 声称，grep 核）。

### WS-7 · 打包 / manifest 卫生（P0）

- **allowed-tools 维持 `Bash, Read, Edit, Write, Task` 裸清单，不做 gated 收窄**（R2 NF1 MAJOR 逆转 v2）：v2 想收窄成 `Bash(bash *scripts/*), Bash(python3 *)…` 是**非法权限语法**：Claude Code 权限只认精确串或 `Bash(cmd:*)` 前缀，中段 `* ` 通配不匹配；validate 零信号放行，但运行期每次跑 scan 要么弹授权、要么直接把 Bash 踢出致 scan 静默不跑。真正的隔离靠 clean-context reviewer（无写权），不靠主技能 Bash 收窄。Task 仍是 spawn writing-reviewer 唯一入口，务必保留。DoD 加‘重装后跑真 Polish 确认 reviewer 被 spawn 且 scan/cp 无授权弹窗’。
- **argument-hint / $ARGUMENTS 处理收窄，勿删空气**（R2 NF2 MAJOR + NF3 MINOR）：全仓 grep=0 个 argument-hint（v2 要‘删 argument-hint’是删不存在物）；唯一 `$ARGUMENTS` 在 runse SKILL.md（`disable-model-invocation` 的合法透传，WS-6 明确保留）。故：(a) writing-polish 主技能本就无此二者，只做一次防御性 grep 确认（no-op）；(b) **runse 的 `$ARGUMENTS` 豁免、不动**。v2‘删 $ARGUMENTS’与 WS-6‘runse 保留 $ARGUMENTS’自相矛盾，此处消解。删除‘会触发 validate 告警’的理由：validate 不 lint skill frontmatter（R2 实证），该前提本身错。
- **manifest description 去 changelog 化**：plugin.json + marketplace 两处换简洁用户向文案，去版本戳，两处一致；丰富 what+when 只留 SKILL.md。
- **description 补 CN 热词触发器**：`去 AI 味`/`AI 感`/`这段读着像 AI 写的`/`帮我去味`。
- writing-reviewer：核实运行时不调 Bash 后 `tools: Read, Grep`；加显式 `model:`（pin 强模型使审稿质量与写作会话解耦）。
- version + keywords 唯一真源 plugin.json，marketplace 删冗余（version 功能冗余、keywords 已漂移）。
- pandoc 措辞：定位可选预装，执行期绝不自动 brew，桥接前 `check-dependencies.sh` 探测缺则优雅跳过。
- constitution 加运行时护栏：别把 shipped Polish 循环套 `/loop` `/schedule` `Cron`（质量随评审变不随时钟变，self-acquittal 是可疑收敛判据）。

### WS-1 · scan 逐条 diff + 补缺口 + 修误报 + 结构化 + 版本统一（P0，高风险）

**前置（强制）**：对 744 行 scan 逐条 diff，每规则标‘已存在(line X)/需扩/新增’，禁把已有规则当新增写进 SSOT 编号。

1. **补真缺口词**（先核实确缺再加）：候选 `接下来`/`首先其次再者`当纲要/`并非…而是`（`不是…而是` 已有）。加进对应现有分组，不新建轴。
2. **修误报（核心）**：把 `不是…而是`/`让我们`/路标词从零容忍红线降为**软 WARN（exit 2）不 FAIL**；讲话稿对 `让我们/共同勉励`、随笔对低频 `不是…而是` 显式豁免。红线只保留跨体裁无歧义字面残留（`作为一个AI`/oaicite）。
   - **L1 不做任何‘同结构’语义硬判**（R2 scan MAJOR 逆转 v2）：v2‘整段三连排比≥3 次同结构才硬判’有三重错：(a) `threshold_for_length` L254 是**全文千句密度**非段内计数，段内计数是新代码不是复用；(b)‘≥3 同结构’要判结构同一性=语义题，与 item4‘同结构难纯正则→下沉 reviewer’自相矛盾；(c) base/audit 无 genre 时，一篇讲话稿段内 `让我们`×3 会被硬 FAIL（正当反例）。**改判据**：L1 只做‘同一自然段块内、**字面**否定平行正则（`不是.{1,15}而是`/`不仅.{1,15}更是`/`与其说.{1,10}不如说` 这类字面式，非语义同构）≥N 次’的可数代理，命中也**只 WARN 不 FAIL**；结构同一性判断全下沉 L3 reviewer。DoD 加回归 fixture：‘讲话稿段内 `让我们`×3 在 base profile 不 FAIL’。
     - **N 定死 = 3**（R3 scan minor：留空悬=magic number 会自打耳光）：段内字面否定平行 ≥3 次才 WARN。因是 **WARN 非硬闸**，此启发式豁免‘无语料校准即反模式’的严苛度（反模式针对的是硬判阈值），但仍 DoD 专测（见 DoD#2 第三 fixture 直接压这个新原语）。
     - **per-block 切段原语（新代码，非复用 threshold_for_length）健壮性**（R3 scan minor）：切段**在 scan-skip 已剥离代码围栏后的正文上做**（复用 item5 的 1:1 行映射），避免围栏内空行切碎；对无空行分隔的列表块，**每个列表项各自成 block**（防跨项统计否定平行虚高），标题行不并入相邻段。因 WARN-only，兜底即可、不求精细。
   - **G8 单次否定平行改走 L3 reviewer**（R2 NF D MINOR）：constitution §5 Example H 现写 G8 咨询报告单次 `不仅 X 更是 Y` 即‘必扣’，与 L1 密度化后不 FAIL 直接打架。落地：G8 否定平行由 L1 硬判改 L3 reviewer 语义捕获，并同步把 Example H 措辞‘必扣’软化为‘L3 在 G8 语境应判为要改’，令 scan 与 gold-standard 不再互相矛盾。**诚实标注**（R3 zh-moat minor，inference-vs-verification）：此处是‘覆盖**迁移至 L3 判断轴**’而非‘覆盖不降’：L3 是非确定性 LLM 判断，无确定性闸背书。故在 WS-6(B) reviewer 判词稳定性校准里登记一条抽检用例‘G8 单次 `不仅…更是` 应被 L3 判为要改’，DoD 明注该项属 reviewer 判断、非机器可断。
3. **破折号维持硬红线 =0（用户硬点，中文成对破折号也禁）**：不做配额。现 `——|—`(L299) 保留为红线。**同步 dogfood 与全局 CLAUDE.md 标点段一致**。放弃 v1 的破折号配额想法。冒号/二人称 quota 亦砍掉（无语料校准=magic number，评审点名反模式），至多保留‘同段密度突增’相对信号，不落绝对阈值。
4. **结构性 slop（可 grep 部分）**：核实 `元论述导读`（`本文将从…个方面`/`下面从…展开`）是否已扫，缺则补；`大纲骨架/金句叠句/承重隐喻` 难纯正则，scan 只标疑似、下沉 reviewer（WS-2）。
5. **evidence span = 结构化输出改造（非加字段）**：命中直接产结构化记录（`rule/line/matched`），弃 stdout-reparse 反解析架构；**只做行级 span，列级(char-col)推迟**（CJK 字节≠字符列，高成本低收益）；实现下沉 python3 helper（python3 由 WS-7 裸 `Bash` 覆盖，NF1 逆转后 allowed-tools 无独立 `Bash(python3 *)` gated 项，勿再提‘已含 python3’口径），bash 只做粗粒度 grep 命中；span 坐标复用 scan-skip 预处理的 1:1 行映射。
6. **genre 入参 + canonical enum（锚 constitution §0）**：scan 加 `--genre <G|auto>`，**缺省 = generic base profile**。base profile 的确切语义（R2 scan MINOR 澄清，防误读）：**只关闭 genre-keyed 体裁豁免，但保留 context-keyed 语境白名单**（`防火墙` 机房/等保 ±2 行 L479、`对标` 党政语境 L497 等靠上下文窗口判定的白名单不动：它们是词义消歧非体裁豁免，base 也要留，否则 IT 文档‘防火墙’全误报）。canonical G-code enum **以 constitution §0 的 G1-G8 为准**（R2 NF B 逆转 v2 的‘以 eval-record 为准’），eval-record/genre-guide/scan 三处反向对齐 constitution 精确名串（eval-record 咨询报告→G8、其余无字母项=第 9 类‘其他’）；归一站点四处（constitution §0 为首要真源 + genre-guide + scan + eval-record）。Coach/Polish 由体裁推断显式传入，Audit/dogfood/hook 走 base 缺省（禁 audit 内做体裁推断）。**per-genre 阈值 profile 全矩阵推迟**（过度工程），base 阈值 + genre 白名单先覆盖；只对破折号(已禁)与确有语料证据处落分档。
7. **两套 scan 决策（与 item6 base profile 同一轴，现在定死不留‘落地时决定’）**：scan-hard-gate.sh（v5.0，30 codepoint，无语境豁免）的角色 ≈ item6 的 base profile（无 genre 豁免）。**决策**：把 scan-hard-gate.sh 的按行 violation 输出机制上收进 scan-ai-taste `--genre base` 模式（evidence span 复用其 `grep -nE` 行捕获），删掉独立的 scan-hard-gate.sh，CI 硬闸改调 `scan-ai-taste.sh --genre base --json`。这样只有一套引擎、两个 profile（base=CI 硬闸/audit，genre=Coach/Polish）。DoD 断言：仓内不再有第二个 scan 脚本（grep 脚本数=1），base 与 genre 走同一 codepoint 表。
   - **退出码契约（R3 scan minor：软 WARN 与 CI 硬闸的载重不变量）**：`exit 0`=clean、`exit 1`=FAIL（红线：破折号/`作为一个AI`/oaicite 等跨体裁字面残留）、`exit 2`=WARN（软信号：否定平行/让我们/路标词密度）。**CI 硬闸仅在 `exit 1` 判失败**；`exit 2` 放行并回显警告（兑现‘软信号只 WARN 不 FAIL’承诺，防 CI 把非零一律当红）。scan-output.schema 的 `exit_code` enum 已是 `[0,1,2,3]`，语义在此定死。
   - **删文件连带清引用（R3 platform minor）**：删 scan-hard-gate.sh 时同批 `grep -rn 'scan-hard-gate'` 全仓，更新**活引用** `evals/offline-harness/README.md:13`（现登记为在用工具）指向 `scan-ai-taste.sh --genre base`；`evals/legacy/v5.x/gold-standard/spec.md` 属归档区、保留不动。归入 WS-8 文档债同批。
8. **fix-map 修理工**：首版只覆盖高频约 20 词逐词替换（`赋能→帮/让`），拆 CN_HARD 单条 alternation 为可索引；长尾回退 per-类别建议。156 词全量推迟。
9. **版本统一（grep 驱动全扫，不用固定清单）**（R2 NF4 MINOR）：v2 的‘七处清单’漏了 eval-record protocol enum `[v5.1,v6.0,v6.1]`、scan-hard-gate v5.0 banner（item7 已决定删该文件）、SKILL.md 标题 `# writing-polish v7.0`。改用确定性全扫：`grep -rnE 'v?[0-9]+\.[0-9]+' plugins/ evals/` 逐条 triage 是不是版本戳，全部对齐 8.0（含 scan banner、JSON version、log version/protocol、eval-record.schema 的 protocol enum、scan-output.schema、SKILL.md 标题、plugin.json、marketplace）。**删除 v2‘eval-record [6.0,6.1] 已被 7.0 日志违反’的断言**：无据（仓内无 eval-record `.jsonl` 数据，protocol enum 只是 schema 允许值列表，未被任何真实 record 违反）；只需把 enum 追加 8.0 即可。**additionalProperties 决策定死**：eval-record 与 scan-output schema 均设 `additionalProperties: false` 并把 evidence span 的 `rule/line/matched` 字段显式加进 schema（不靠放开 additionalProperties 兜底，保持 schema 是真契约）。

### WS-2 · constitution / reviewer 实质轴锐化（P0，中高风险）

1. **空话可证伪测试**（换主体仍成立=空话）写进 constitution 立意/材料焦点 + reviewer 判据，质量闸不打分。**豁免定义为体裁无关的‘必备政治表态/指导思想 boilerplate 段’，不逐 G 码打补丁**（R2 NF E MINOR 修正 v2 只写 G1/G2 的漏项）：必备表态非 G1/G2 独有：G3 调研报告含‘政治站位要高’、G4 述职含‘政治立场不说软话’同样是 survive 换主体测试却非缺陷的必备成分。**判据重定义**：该测试‘只对承载具体主张的实质句生效，不对表态 boilerplate 生效’（与体裁解耦），避免逐 G 码补丁式漏项。
2. **事实敬畏第四态**：三态加‘推断/预测就地标前提’；把‘润色不得新增事实’升级为对 diff 的可执行守卫：reviewer 对比原稿与改稿，新增的数字/专名/绝对化断言未在原文出现即红旗。
3. **双侧校准拆两态并分别门控**：`无菌`（丢具体/数字/专名）= 材料·事实焦点失败，**genre-agnostic** 保留；`无声`（丢个人声音）= **仅 G6/G7** 判失败，与 WS-4 门控对齐。明确写：G1-G5/G8 去个性不是失败态，reviewer 不得以‘无声’回推公文去个性。把‘别为骗过 AI 检测器而改’写成非目标。
4. **评审独立性协议**（reviewer 硬隔离 + Polish 操作律）：① 范文/公文锚本绝不进 reviewer 线程（锚越强越危险）；② ‘上轮改了什么’叙事不喂 reviewer（实证：能把真实 3/10 吹成假 8/10）；③ 评审反馈逐字留痕，主对话 writer 不得转述稀释。
5. **So-What 收口（收窄+降级）+ 每体裁‘常见跑偏’清单**（R2 NF C MAJOR）：genre-guide 每体裁尾挂结构性跑偏。So-What 收口**收窄到 问题类/研究类调研 + 汇报稿 + 议论性评论**三类，**显式豁免 情况类调研 与 抒情随笔**：(1) genre-guide §三 情况类调研是‘写实写准、宁可少写一个情况也不写不准’的描述型文体，强制加 So-What 结论 = 逼出数据不支持的判断，直接顶撞事实敬畏（护城河核心）；(2) G6 抒情随笔本就允许开放式收束，强制 So-What 抹平个性。且**把‘强制’降级为 reviewer 提示**（‘此处是否需要 So-What 收口？’）而非硬闸，避免为凑收口而编造结论。
6. **理性化陷阱段落 constitution/reviewer（不落 SKILL.md，省 token）**：仅对最易被绕过的铁律（改稿只主对话串行、事实敬畏、锚本不喂评审）补‘你可能会想…但不行，因为…’，不铺满（避免铁律墙，arxiv 2507.11538）。

### WS-3 · Polish 协议重排为回归守卫式迭代（P1，中风险）

- **有序单维 sweep**：达意/立意 → 空话与口水 → 结构与论据 → 标点与体裁 AI 味。
- **回归复验一律走 scan 重跑（廉价确定性），reviewer 只在 sweep 起点 spawn 一次覆盖全焦点，不每维重 spawn**（否则 O(N²)）。
- **sweep 深度按 §1.2 字数档门控**：短稿只跑达意+标点两维，长稿才全 4 维；把刚性多遍 pipeline 改成随稿自适应。
- **高影响操作**（整段重写导语/删整节）走 checkpoint 征询，不设数字改动帽。
- **终轮对抗 kill-argument 并进最后一轮 reviewer 的 steelman 焦点**（不单开 fresh-thread），仅论点重的长稿触发，detect-only。
- 同步更新 SKILL.md §1.1 的 Polish 时长/资源列，让 SLA 与新协议自洽。
- 保留 single-linear-writer 铁律、cp 备份、最多 2 轮否则上报。

### WS-4 · 声音匹配 tier-1+tier-2（P1，G6/G7 硬门控）

**门控纯用 G 码，单一判据**（R2 NF A MAJOR 消解 v2 双判据自相矛盾）：仅 G6 随笔杂文 / G7 自媒体开启，G1-G5/G8 关闭。**删除 v2‘政论/时评不进’的语义子例外**：constitution §0 已把 G6 交付场景定义含‘个人观点/思辨/评论’，即时评本归 G6，若再用 prose 排除就成了‘G 码判开、语义判关’的双判据，门控丧失确定性（正是 R1② 要求去掉的模糊）。消歧：真正党政政论属 G1/G2（已被 G 码关闭），G6 下以个人声音写的时评正当适合 voice-matching；实质轴/去个性顾虑由 WS-2（对全体裁含 G6 生效的实质轴锐化 + 无声仅 G6/G7 判失败）正交守护，不靠 WS-4 排除。

- **tier-1**：用户贴 2-3 段旧作，按 6 维观察（句长节奏/用词层级/段首/标点癖/口头禅/过渡）即时对齐，单次生效不落盘。去味用‘作者自身模式替换’而非‘升级成更好的词’。
- **tier-2**：可选落盘 VOICE 画像，**落使用者项目仓**（如 `<cwd>/.writing-voice/` 或 docs/，随用户仓 git，不进插件仓，插件不携带任何声纹样本）；genre-scoped 命名（文章声音≠邮件声音）；插件侧只提供读取约定。
- **tier-3 推迟**（语料 allowlist + 声纹漂移 + 长稿声音审计）。若未来做，语料 allowlist 只作用纯风格轴（句长/标点癖/用词/口头禅），**显式排除模糊归因(§1.3)/推断词雷达(§6)/材料·事实焦点，事实敬畏永不被语料豁免**。
- 核心 reframe‘不像 AI ≠ 像我’。不引入向量检索。
- **热路径顺序与 WS-3 合并成唯一 step 图**：声纹漂移(tier-3 缓)/声音对齐(tier-1) 作为 voice-gated 体裁下 sweep‘达意’维之前的前置扫描；公文体裁跳过声音步。两 WS 共用同一顺序定义。

### WS-6 · 离线 eval 补触发/路由轴（P2）

**拆成两条轴两套方法**：

- **(A) 技能调用轴**：writing-polish 整体 should-fire（润色/审稿/帮我写/去 AI 味…）vs should-not-fire（翻译/代码/纯英文，复用 description 排除项），用官方‘开 vs 停 skill’全新会话法。runse 因 `disable-model-invocation` 不进本轴（仅 /runse 显式调、透传 $ARGUMENTS，文档注一句）。
- **(B) mode 路由轴 + reviewer 判词稳定性抽检**：技能已触发前提下，固定输入→期望 mode 断言（歧义词‘帮我看看/改一改’走字数分档），测 SKILL body 逻辑，不用开/停技能。**并登记一条 reviewer 判词抽检用例**（承接 WS-1 G8 下沉）：‘咨询报告(G8) 单次 `不仅…更是` 应被 L3 reviewer 判为要改’，兜住 L1 下沉后‘覆盖迁移至 L3’的非确定性缺口（此项属判断轴、非机器闸，只作稳定性跟踪不作硬门）。
- **执行模型（明确写死）**：人在环手动校准：改 description/§1 触发表后，fresh 会话逐条贴用例记录是否触发，产出带日期+被测 description 版本号的 `trigger-calibration-results.md`；README §1 注明‘本校准靠人跑、非 CI 自动’，杜绝空转 bit-rot。
- **grader-gaming 隔离**：校准用例取真实用户话术/held-out 改写，**禁逐字复制 §1.1 触发表**（否则路由版‘把 eval 注入 prompt’，永远 100%）；继承 eval-set 禁注入规则，不作 few-shot 喂‘改 description’prompt；新文件 README §1 登记属哪条轴、不走 split 机制。
- **跨模型（诚实）**：scan 标注‘模型无关，跨模型 N/A’；只对 writing-reviewer 判词稳定性 + llm-judge 一致性有意义，要落就真在 ≥2 模型跑并写 eval-record（schema 已有 model 字段）+ 引用具体 record 文件+日期；**未跑则诚实写‘未做跨模型校准（待办）’，禁暗示已覆盖措辞**（inference-vs-verification）。
- **改动率信号降级**：只做 v7→v8 一次性 before/after 编辑距离回归对照（用 calibration-set 同 source_commit before/after 配对），报分布不报点阈值、只当诊断旗、绝不进 per-use 路径或作技能可见优化目标（否则贴 self-acquittal 红线）。做不到就降为‘可选未来注记’。

### WS-8 · 文档债 + 版本统一 + 全局更新（P3）

- CHANGELOG 加 v8.0 条目；所有版本串一次统一到 8.0（见 WS-1 第 9）；status.md 更新（现停 v7.0.0）。
- 全局收口（本机）：`~/.claude/memory/reference_personal_skills_toolkit.md`（v4.3→v8.0）；`~/.claude/CLAUDE.md` 标点段‘writing-polish v4.3 对齐’更新；两仓 copy-principles 若引用同步。
- `claude plugin marketplace update xuan-jiang` + `claude plugin update writing-polish@xuan-jiang` 刷新全局安装。

## 3. 执行模型（多智能体多角度多轮迭代 + LOOP）

- **作用域隔离**：本节 loop-until-dry **仅指搭建 v8 时对交付物的多轮 clean-context 审阅（开发期元流程）**；shipped Polish 协议永不自套 /loop（见 WS-7 运行时护栏）。两作用域显式隔开，勿混。
- **审阅并行、落地串行**（全局铁律）：每 WS 主对话起草 → 派多个 clean-context 子代理多角度审（writing-polish 四焦点 + skill-authoring + scan 工程 + eval 视角）→ 主对话串行落地。**禁子代理并行写**。
- **多轮至收敛**：每 WS 审阅 loop-until-dry，连续 2 轮无新实质发现即收敛；scan/validate 机器闸每轮必重跑；**凡 agent 报‘已符合’，机器可核项一律脚本复核**（TOC/一跳/版本串已有假声称前科）。
- **dogfood 分两半（关键）**：标点核查（`check-cn-quotes.py`：弯引号/无直角引号/无破折号）对所有 md 安全全量跑；**黑词/AI-tell scan 不得对插件自身 references/anchors/schemas/evals 元文档设门**（它们逐字含被禁 token 作反面教材，实测 constitution 命中 19 处），或要求元文档用 `<!-- scan-skip -->` 围栏；只对真正散文交付稿跑黑词扫描。

## 4. 验收标准（DoD）

1. `claude plugin validate` 源码 + 单插件 pass 零 warning（manifest 层）。**注**：validate 不 lint SKILL.md frontmatter（R2 实证），skill 字段卫生（无 argument-hint 遗留、name/description 合规）改由本仓 grep 自检脚本 + 人审保证，不指望 validate 报。
2. scan 对新 fixtures（补缺口词/结构 slop/误报回归/破折号红线）分类正确；**anchor/教学 reference 的预期 fail/pass 显式列出并按新规则重新 baseline**（不是笼统‘不变’）。**必含三条回归 fixture**：(a) 讲话稿段内 `让我们`×3 在 `--genre base` 下只 WARN 不 FAIL；(b) 咨询报告(G8) 单次 `不仅…更是` 在 L1 不 FAIL（改由 L3 reviewer 语义捕获，属判断轴无机器闸）；(c) **直测新 per-block 原语**：同段内 ≥3 次字面否定平行（如 `不是A而是B…并非C而是D…不仅E更是F`）在 base 只 WARN（exit 2）不 FAIL，且 <3 次不触发。
3. 触发/路由校准：should-fire ≥8 / should-not-fire ≥8 / 歧义 ≥6 用例，分别报 precision 与 recall；门 = ‘固定小负例集 should-not-fire 精确=100% 且每个失败 triage 归因’，should-fire 作跟踪指标；阈值配 rationale（仿 llm-judge‘>30% unknown=歧义’）。
4. 所有 SKILL.md→reference 一跳（脚本复核）；>100 行 reference 全有 TOC（脚本复核，不信 agent）。
5. 全站中文 .md 标点全绿（弯引号/无直角引号/无破折号）；SKILL.md 正文 <500 行 <5k tok（给可执行 token 测量命令；理性化陷阱段落 constitution 非 SKILL.md；kill-argument/checklist 细则下沉 revision-checklist.md）。
6. 重装后 `claude plugin details` 显示 2 skill + reviewer 注册 + 真跑一次 Polish 确认 reviewer spawn 且无授权弹窗；任意仓 `/writing-polish` 可调。
7. 版本串 **grep 全扫**（`grep -rnE 'v?[0-9]+\.[0-9]+' plugins/ evals/` 逐条 triage）全对齐 8.0，含 SKILL.md 标题/scan banner/JSON version/log protocol/eval-record protocol enum/scan-output schema/plugin.json/marketplace；不用固定七处清单（v2 曾漏三处）。CHANGELOG/status/全局 memory 同步零文档债。
8. **单 scan 引擎 + 退出码契约 + 无悬空引用**：仓内 scan 脚本数 = 1（scan-hard-gate.sh 已并入 `scan-ai-taste.sh --genre base`），CI 硬闸改调 base profile；grep 确认无第二个 scan 脚本。退出码契约验证：`exit 0/1/2` = clean/FAIL/WARN，CI 仅 `exit 1` 判失败、`exit 2` 放行回显。`grep -rn 'scan-hard-gate'` 全仓无活引用残留（README.md:13 已改指 `scan-ai-taste.sh --genre base`，legacy/ 归档区不计）。
9. **base profile 保留 context-keyed 白名单**：fixture 验证 `防火墙`(机房语境 ±2 行)、`对标`(党政语境) 在 `--genre base` 下不误报（base 只关体裁豁免、不关语境消歧）。

## 5. 已采纳的过度工程削减（评审建议）

- per-genre × per-标点 全矩阵配额 → 砍，base 阈值 + genre 白名单；仅数据可校准处落分档。
- evidence span 列级(char-col) → 砍，只做行级。
- fix-map 156 词全量 → 首版 top-20，长尾回退 per-类别。
- 声音匹配 tier-3（corpus allowlist/声纹漂移/声音审计）→ 本轮缓（用户定 tier-1+2）。
- 改动率遥测 harness → 降为 v7→v8 一次性回归对照或未来注记。
- kill-argument 单开 fresh-thread → 并进末轮 reviewer steelman 焦点。

## 6. 风险闸

- 护城河：所有借鉴中文原生重建，不双语、不搬英文数字阈值、不引 per-use 打分、事实敬畏永不被语料豁免。
- 误报回归：WS-1 每改一条规则必对 8 篇 anchor-essays + 11 篇 real-world-anchors 重跑 scan，must-pass 锚本零新增误报才算过。
- 分批闸：虽全量做，产品扩张（WS-1/2/3/4）每 WS 落地即多轮对抗审阅 + 机器闸 + anchor 回归，官方卫生（WS-5/7/6）先落拿确定收益。
