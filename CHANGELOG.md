# Changelog

All notable changes to xuan-jiang `writing-polish` skill are documented here. Format follows [Keep a Changelog 1.1](https://keepachangelog.com/en/1.1.0/). 版本策略（自 v10.0.0 起）：项目自定义，不遵循 Semver：**主版本号锁定 10，此后只升后两位（10.x.y），除非巨大变动不升 11**。

> 历史段按当时状态记录，**不代表当前文件仍存在**（如 v5.x 的 `prompts/multi-agent/`、`config/default.yaml`、v6.x 的 `prompts/reviewer.md` / 0-3 评分链均已在后续版本移除或下沉离线）。当前状态以 `README.md` / `docs/status.md` / `SKILL.md` 为准。

## [10.1.0]（2026-08-04）收缩机械化：硬红线只留无歧义集，语境判断交 reviewer；吸收 human-writing（MIT）理念层

> 触发：用户直觉“技能部分机械、没用好大模型理解力”，三路调研证实：scan-ai-taste.sh 864 行承载约 341 正则模式，v9.2 独立评估精确率约 18%；硬红线混入公文合法词与国标合法标点；同一黑词清单四处手写已漂移（交集仅 5 词）。同轮吸收外部技能 KKKKhazix/human-writing（GitHub，MIT）的理念层，调研落盘 `docs/research/2026-08-04-human-writing-absorption.md`，spec 落盘 `docs/plans/2026-08-04-v10.1-framework-contraction.md`。接口零改动（路径/参数/退出码/schema 契约不变）。

### Added

- **一致性哨兵 `scripts/check-rule-consistency.sh`**：机械比对 anchors §1.1 词表与 scan 脚本 CN_HARD 正则逐字一致，漂移 exit 1（bash 3.2 兼容，零新依赖）；契约吸收 human-writing（MIT）references/revision.md“硬禁词必须与判据文件完全一致，增删同轮双向修改”。offline-harness 无统一回归入口，已在 evals/README.md §6 登记为回归项。
- **降级词软信号节**：CN_DEMOTED 8 词命中输出「供 reviewer 语境判断：本义准确保留，抬价堆砌改写」。
- **reviewer 承接判据三条**（agents/writing-reviewer.md）：①降级词表语境判断；②破折号文体取舍（按体裁 G 码）；③密度提示仅报不令改。
- **判据层吸收（均注明出处）**：`revision-checklist.md` 新增“七遍改稿补强”（逐段标作用 + 删 1/3 压缩试验、假具体识别、结尾检查、冷读四问；与何其芳 12 条分工：12 条管改什么、七遍管按什么顺序改）；`coach-checkpoints.md` §4 材料门槛量化（长稿 ≥1200 字动笔前 ≥5 件带来源材料，软 checkpoint 不作硬闸）。
- **哨兵集 v10.1 重标**：redline-sentinel-set.jsonl 73 条全部加标 `expect_v10_1`（24 FAIL / 3 WARN / 46 PASS），脚本手术后实跑对拍 73/73 自洽；7 个 fixture 同步更新预期注释。

### Changed

- **CN_HARD 15→7 词**：保留赋能/闭环/抓手/链路/拉通/话语建构/跨界融合；**降级为软 WARN**：切实推动/提质增效/深度融合/打造/助力/多维度/体系化/重塑 8 个公文合法词（政府工作报告标准用词，无语境豁免即命中是误伤源）。
- **破折号红线 → 软 WARN**：GB/T 15834 中破折号是合法标点，文体取舍交 reviewer；保留法律语境特殊提示并入 WARN 措辞。
- **首先/其次/最后三段式 → 软 WARN**：教学/讲稿语境合法。
- **密度阈值保留计数但降为提示**：WARN 措辞标注「密度提示，不作改稿目标」（防 Goodhart：机械计数曾诱导反向改坏文风）。
- **词表唯一 SSOT**：anchors §1.1 按新软硬分界重写（硬红线无歧义集 + 降级项逐条注明理由与日期），新增一致性契约；SKILL.md §3 与 reviewer 内嵌词表改一行指针；anchors §6 阈值双写表删除（脚本是唯一执行者）。
- **保留不动**：元注释/客服话术 4 组、工具残留 markup bugs/占位日期、GB/T 引号检查、±2 行白名单机制、KOUYU/ZIZHENG 软词表；开篇模板/超长段落/句长方差 WARN 措辞统一标注「供 reviewer 参考」。
- **版本号全局统一 10.1.0**：plugin.json、脚本头注释与内嵌 JSON、docs/status.md、MEMORY.md、TROUBLESHOOTING.md、根 README 定位句。
- **schema 遗留债同批清零**（QA 独立验证发现，均为 v10.0.0 遗留而非本轮回归）：`assets/scan-output.schema.json` version 字段去掉陈旧 const "9.0"（自 v9 起漂移），改描述明确其为插件版本戳非 schema 版本；`evals/offline-harness/eval-record.schema.json` 三处过期 enum 对齐脚本实际输出（version 增 10.1.0、protocol 增 v10.1、final_action 增 soft_warning/failed/error）。

### Removed

- **fix_word 逐词替换建议表**：references/failure-cases.md 案例 1 已证伪机械近义词替换。
- **GENRE=auto 占位分支**：自注“暂等同 base”无实现计划。
- **anchors §6 阈值双写表**、**SKILL.md / reviewer 内嵌黑词清单**（改指针）。
- **evals/legacy/**（1.1MB v5.x 死重，git 历史可查；未入库的 .firecrawl 物理残留同批本地清空）。

### Rationale

收缩机械化：脚本只执行无歧义硬禁，语境判断交 reviewer——正则精确率 18% 的机械层不值得继续堆模式，大模型的理解力才是本技能该押注的地方。四源漂移教训：词表只能有一个权威源，其余放指针，用脚本机械校验代替人肉同步。**不吸收清单**：形状检测族脚本（比喻聚类/段首重复检测/短句排队检测等）一律不加——形状判断同样是语境判断，加脚本只会重蹈精确率 18% 的覆辙，交 reviewer；外部黑词清单不进本技能词表（词表须体裁门控）；硬禁令不加（须过白熊效应审查）。

## [10.0.0]（2026-08-03）站位四问升格全模式第一环节、读者谱系扩非工作场景、听众反应预演

> 触发：用户长时间使用写作技能后沉淀出的体系性认知：任何写作或润色，必须先极其明确读者是谁、在什么媒介上读到或听到，这是最重要的政治站位检查；同一轮完成 2026 年中业界最佳实践调研（见 `docs/research/2026-08-03-best-practices.md`），audience-aware prompting 已成行业共识，佐证站位前置设计。另从一篇央企党课实战（citic-energy-dangke 仓，已脱敏）蒸馏出听众反应预演判据。用户明确要求：不做任何兼容保留，大刀阔斧改；主版本号锁定 10。

### Added

- **站位四问**（`stance-and-register.md` §1，替换原两问）：①读者是谁（不可模糊）②我是谁 ③媒介与文体（会场口播听到 / 纸面印发读到 / 屏幕扫读 / 微信即时通讯 / 机器解析；听稿规则：句子宜短、忌生僻词、重复是特性不是缺陷）④第二受众（讲话稿的印发读者、抄送范围）。③④出处：任仲然《怎样写作》第七讲受众三问（“一要明白谁要讲话，二要明白在什么场合对什么人讲话，三要明白印发下去的讲话给谁看”）。
- **四阶段流水线**：P0 定站位、P1 预处理、P2 润色、P3 评审，全模式适用；Audit / Express 用一行式站位确认。
- **读者谱系扩非工作场景**（§2 站位矩阵加 5 行）：部门内熟人（防过度客气正式商务腔）/ 跨部门（不评价对方内部事务、术语首次解释）/ 家人朋友、恋人配偶（去公文腔去绩效腔）/ 自媒体读者（指向 genre-guide G7）/ 面向软件系统的说明提示语（直陈、无寒暄、可枚举、术语保真）。
- **听众反应预演**（§2.1，门控 G2）：逐句问“台下的人听了会怎么想、会不会多想”；四组判据（站位 / 语气 / 分寸 / 语境）蒸馏自央企党课实战；含稿件血统溯源闸门（命中领导审定文字的意见一律不采）。
- **`references/scenarios/` 场景包目录**（progressive disclosure）：`party-lecture.md`（党课 / 领导讲话四组铁律、高风险清单、自检清单、假阳清单）、`familiar.md`（熟人 / 私人场景防商务化客气化，正向锚引第十一讲“随心、随性、随情”）、`README.md`（新增场景即新增一个文件并在矩阵加一行）。
- **假阳清单同批建立**（沿用 v9.3.1 教训）：§2.0 补“听众预演不适用 G6 / G7 私人写作”“熟人场景报‘过于正式’只提示不阻断”。
- **调研沉淀**：`docs/research/2026-08-03-best-practices.md`（8 条结论带来源 URL 与抓取日期）；`anti-ai-taste-anchors.md` 新增 backlog 节（与 no-ai-slop 缺口对照）；offline-harness 记 LLM-as-judge backlog 一条。

### Changed

- **SKILL.md**：标题 v10.0；§0.2 三阶段表扩四阶段；Coach step 0 两问扩四问；Polish step 2.2 reviewer prompt 注入清单并入媒介 / 第二受众；Audit / Express 各加轻量站位确认行；压缩 §0.1 / §0.2 的旧版本戳叙述；全文 ≤ 300 行。
- **`writing-reviewer.md`**：输入契约由两问扩为四问，缺失即报“口吻焦点无法判定”；输出增“听众反应预演核对”（仅 G2）。
- **`constitution.md`**：§0.4 增“媒介错位”失败形态（微信写印发体、口播写长从句等）；§2.2 G2 切片补党课 / 领导讲话四条守则指针与时长基准；§1.1 记 GB/T 15834 修订暂缓观察点。
- **`genre-guide.md` G2**：补任仲然时长基准（即席 15 分钟 / 一般会议 25 分钟 / 年度主报告 1.5–2 小时）与避生僻词。
- **`renzhongran-coverage-matrix.md`**：补第七讲受众三问到站位四问、第七讲时长基准到 G2、第十二讲政治关到听众预演的映射；已覆盖项补行号级引用注。
- **README.md**：新增“动笔之前：先问清谁在读、怎么读到”节；修积压漂移（约 80 条红线、四种模式、五大焦点）。
- **版本号全局统一 10.0.0**：plugin.json、marketplace.json（三模式改四模式）、脚本头注释、docs/status.md 重写、MEMORY.md 索引追加。
- **版本策略**：主版本号锁定 10，此后只升后两位。

### Rationale

v9.3 起口吻与站位已是第一顺位审查焦点，但它仍被放在“审查”环节：口吻判断错了，后面所有焦点都在错误的基准上优化。本轮把它前移到动笔之前的第一环节，并补齐两问覆盖不到的两件事：媒介（同一读者经不同媒介接收，句法要求完全不同，听稿的长从句在纸面合法、在会场失败）与第二受众（讲话稿不只讲给台下，还印发给不在场的人，按两头更严格的一头定口吻）。2026 年中调研显示 audience-aware prompting 已成行业共识（见调研文档），且词面禁令改不掉深层结构，结构层仍交 reviewer，与本技能两世界拆分路线一致。听众反应预演只门控 G2，配套假阳清单同批建立，避免 v9.3.1 式误伤。

## [9.7.0]（2026-07-29）对外问题清单：只问产品消化不了的

> 触发：duanju 售前第三轮材料清单。owner 逐条砍掉确认题并定调：“有些内容我们开发的时候直接给可选项就行，没必要去问人家。我们要问真正值得问的东西。”同轮还要求开头寒暄压到一句、去译制腔。

### Added

- **`stance-and-register.md` §2 新增“对外问题清单/资料清单：只问产品消化不了的”**，三条规则各带真实正反例：①产品能用默认值/开关消化的确认题一律不问（判据：拿不到答案产品是不是就做不了）；②寒暄一句话、不写元说明（“本轮把……一并列出”属于文档描述自己）；③条目动词直给，“烦请/如已……则……”类文书套件堆三个以上判译制腔，条件句改“……的话”。

## [9.6.0]（2026-07-29）补记：改稿忠实性铁律 + 客户拍定结论假阳 + 取证自述与反向自伤

> 本条为补记（发版当时漏记 CHANGELOG，条目按 commit a84e588 与文件 v9.6 标注段落回溯）。

### Added

- `revision-fidelity.md`（新文件）：改稿忠实性自查铁律，对照原稿核三条。
- `stance-and-register.md` §2.0.1：最贵的一类假阳——把客户拍定的结论改软（2026-07-28 实战失误复盘）；§4.4 取证过程自述；§4.5 反向自伤。
- SKILL.md step 2.2“既定策略，不要提改进建议”清单升为必填。

## [9.5.0]（2026-07-29）铁律：不得为一组具体名称发明上位类别名

> 触发：v9.4 上线当天，同一份稿子被用户抓出更严重的一类。稿中写“党群部门立项不经此环节”，用户直接问：“什么叫‘党群部门’？不要自造新词。”回原始配置核对，真实条件是“执行部门包含 博士后工作站、党委办公室、党委组织部（人力资本部） 任一”——作者把三个具体部门概括成一个上位类别名，而该单位组织架构里根本没有这个类别；且概括本身也不成立，博士后工作站与党建无关。随后对四份文档做全量术语审计（每个指称性术语逐词回配置核对），同批查出“三家研究院”（该单位实有六家带研究院后缀的机构）、“业务部门”（实指商务服务部与人力资本部，而这两个恰恰是职能部门）等同型问题。

### Added

- **`stance-and-register.md` §5.6 铁律：不得为一组具体名称发明上位类别名**。含三处段落级正反例（附源材料真实口径与错因）、三条判据（源材料能否逐字找到／外延读者能否自算／替换成具体清单后句子是否还成立）、三条边界（通用类别词首次出现须点明外延／编号标签须就近定义／源材料真有的类别名照抄）、以及审计方法（把全文指称性术语逐个抽出来对源材料核对）。
- **§6 reviewer 必要性表**新增“自造上位类别名”一行：四个常用汉字组成、读着像正式称谓，只有回源材料逐词核对才发现它不存在。

### Changed

- **§5.5 的段落级正例**改写：原正例里“对应业务部门”“职能部门会签”正好触犯新增的 §5.6，改为逐个点名部门，技能内部不再自相矛盾。

### Rationale

§5.5 管的是用错词，§5.6 管的是**造事实**——它虽然写在语体一节，实质归“材料·事实”焦点，适用事实敬畏三态的第三态（不得替用户编造）。自造类别名一旦进了交付件，会被下游当成事实引用，纠正成本远高于当初多写十个字。

这是 AI 写稿区别于人写稿的高发失误：**人对自己单位的组织名称有实感，不敢乱起名；AI 只见到一串并列字符串，起名毫无心理阻力**。且这类错误藏在语法完全正确、读来毫不违和的句子里，脚本抓不到、语感也抓不到，只有把指称性术语逐个抽出来对源材料做一次逐词核对才能发现——所以 §5.6 把“审计方法”写成了规则的一部分，而不只给判据。

## [9.4.0]（2026-07-29）术语渗入：读者是非技术岗时的语体规则

> 触发：企业飞书审批流程梳理实战。两份汇报件的素材是从后台配置和接口返回里读出来的，初稿把系统的词原样搬进了公文——节点、表单字段、触发条件、并行会签、路由、A 线 B 线、兜底自动拒绝，还留了一节“待确认事项”。用户指认：“整体语言风格稍微向党政公文语言风格靠拢，且面向的是非技术背景的人阅读”“去掉自动拒绝的逻辑展示，这个没必要汇报，只是审批配置的兜底”“不留待处理待确认的东西”；对某个字段映射原因的解释，另指认“这个没必要讲这么清楚”。

### Added

- **`stance-and-register.md` §5.5 读者是非技术岗时，系统术语必须翻译成办事语言**：与 §5.3“口语渗入”互为镜像——§5.3 管语体往下掉，§5.5 管语体往旁边偏。含 10 组词级正反例（节点→环节、表单字段→填报内容、触发条件→经办情形、并行会签→同时发起互不等待等）、1 组段落级正反例，以及三条边界：①业务行话（会签／或签／抄送／退回／加签）不算术语，首次出现时解释一句即可，不要翻译过头；②系统兜底逻辑（默认分支、自动拒绝节点、去重开关）不进汇报件；③读配置得来的观察留底稿备查，**交付件不留待确认事项**。
- **§6 reviewer 必要性表**新增“术语渗入”一行，标注**本节不得写成脚本规则**——节点、字段、路由在技术文档里全部合法，字面拦截必然大面积误伤，只能结合 §1 问题一（读者是谁）判断。

### Rationale

技能此前的语体规则默认“作者与读者处在同一专业语境”，只防口语化。但 AI 写稿有一类特有的语体污染：**素材来自机器可读的源（配置、接口、日志、代码），作者读懂了就顺手把源的词汇搬进了成品**。读者不是不懂那件事，是不懂用来描述那件事的词。这类问题 §1“读者是谁”本可拦住，但缺一张可对照的翻译表，reviewer 只能凭语感；主对话则完全无感——它刚从原始数据里出来，对那套词已经脱敏。这与 v9.3 的失误同源：**主对话对自己的语体盲区最大。**

## [9.3.1]（2026-07-28）帽子范式入库 + 口吻焦点已知假阳清单

> 触发：v9.3 上线当天即被自己的新焦点误伤。审稿人把公文开篇帽子里的目的排比（“为明确 A，稳妥推进某某单位 B”）判成“作者以客户本位立言、站位越位”，主对话据此拆掉排比改写成“为说明 A，受某某委托”，用户当场驳回：“你党政公文的帽子部分别反复啊……这个帽子没必要变呀，党政公文的帽子部分，用好写作技能。如果写作技能里规定或要求不完善，就迭代写作技能。”

### Added

- **`gongwen-format.md` 十、开篇帽子范式**：标准几何“为〔目的状语排比〕＋〔根据 X〕＋〔结合 Y〕＋制定／提出本 Z”+ 两份锚本；第三方咨询机构的截断重接改造（保留前半排比、只换后半落点，禁落款式收口）；帽子三条禁令（禁拆排比／禁在排比中间插委托关系／禁落款式收口）；§10.4 口吻审查在帽子上的已知假阳。
- **`stance-and-register.md` §2.0 已知假阳：不要拿口吻去改体裁定式**：口吻审查的边界是“作者在说什么话”，不是“体裁要求写什么成分”。列出五类假阳（帽子目的排比／帽子依据段／结合本单位实际／政治表态 boilerplate／一是二是三是列举法），明确 reviewer 报到这几类主对话应判假阳并驳回。
- **`writing-reviewer.md`**：口吻焦点检查项末尾加“体裁定式不算站位问题（已知假阳，不要报）”，从源头减少误报。

### Rationale

新增一个高优先级审查焦点，必然带来一批假阳。**焦点越靠前、误伤代价越大**——口吻焦点排第一顺位，它的误报会直接改掉体裁骨架。因此凡新增焦点，同批必须建立假阳清单，否则技能会把“更严”变成“更错”。

## [9.3.0]（2026-07-28）口吻与站位升为第一顺位焦点 + reviewer 不可省铁律

> 触发：中注协工作秘密上云附件实战。三道脚本闸门全绿、主对话宣布通过，用户一眼看出两处 run-in 小标题写成了论证旁白（“名单本身写着政务云。”“政府采购文件里也这么叫。”），并追问“是机制和流程出了问题？还是写作技能的规则不够完善？”。**答案是两者都有，主因在流程**：自检全靠 grep，而口吻站位与语体错位这两类没有固定词形，regex 结构上抓不到；技能自己的 §2.6 早已写明这类“reviewer 判定，非 regex”，但当轮根本没派 reviewer。事后补派两名 clean-context 审稿人，在脚本全绿的同一份稿子上抓出约六十处问题，其中三处是论证链断口。

### Added

- **`references/stance-and-register.md`（新，第一顺位焦点判依据 SSOT）**：§1 两个前置问题（读者是谁 / 我是谁，答不上来先问用户不替假设）；§2 站位矩阵（外部机构→客户 / 下级→上级 / 领导→下属 / 平级 / 对公众）+ 外部机构对客户三类越界（命令式、批评既往、替客户判断）及逐条改法；§3 口吻六检（祈使/既往/代客决策/多想/谦抑/温度）；§4 自证清白与自我宣告（含“删掉这句论证是否照样成立”判据）；§5 语体一致性（run-in 小标题须为事项名 + 章节标题措辞 + 正文口语渗入 + 不为过软阈值而降语体）；§6 为什么必须派 reviewer（逐类列出 grep 抓不抓得到）。
- **`constitution.md` §0.4 口吻与站位**：焦点表升为五焦点、本焦点置首；含站位速查表、三条改法口诀（要求归还给制度 / 缺口写成下一步 / 依据摆出结论留给客户）、reviewer 强制性条款。
- **`gongwen-format.md` 九、标题语体规范**：与既有第三节明确分工——三节管排版，九节管措辞。含一级标题 12 条（名词短语 2-6 字、同级对仗、禁冒号疑问悬垂“的”尾、禁“……的理解”自曝辩解、禁文号进标题、禁行业白话、禁泄露我方工作过程、标题要承载判断）+ 同级动词同构 + 同级分类维度唯一 + 目录自检法；run-in 小标题三条判据 + 正反例表 + 粗体范围；9.3 章序同类相邻。
- **`logic-and-structure.md` 四、分类维度的选择**：按受众用来做决定的维度切（不按材料自然属性）+ 读者原话即最佳分类依据 + 举重以明轻（下限证明必须紧跟差异说明）+ 分类三铁律（互斥/同层/穷尽）。
- **`anti-ai-taste-anchors.md` §2.5.1 / §2.7 / §2.8**：党政公文口语渗入对照表（G2/G6/G7 豁免）；自证清白与自我宣告九型；语体错位五型。
- **`scan-ai-taste.sh` §2.5.1/§2.7 软 WARN 段**：兜住有确定字面的那一小部分（口语词 + 白纸黑字/需要指出的是/综上所述等），**脚本注释与终端输出双处显式声明“未命中绝不等于通过、主判在 reviewer”**。
- **`reviewer-routing.md` 读者视角补充审**：另派 general-purpose 子代理扮演目标读者本人，只问五件事（读不懂/不舒服/不敢汇报/像机器写/标题风格）。实测能抓出 writing-reviewer 抓不到的论证链断口。

### Changed

- **审查焦点四 → 五，“口吻与站位”置首**（SKILL §4、constitution §0、writing-reviewer、reviewer-routing 四处同步）。理由写进判据：其余焦点出问题是“不够好”，站位出问题是“不能用”。
- **Polish step 3 sweep 顺序**：① 口吻与站位 → ② 立意 → ③ 空话 → ④ 结构论据 → ⑤ 标点 AI 味 → ⑥ 翻译腔。① 任何长度都跑。
- **Coach step 0 定站位不可跳**：“读者是谁 / 我是谁”并入三个吃透并置于判体裁之前，两问答不上来不动笔。
- **reviewer prompt 契约**：必须注入两个前置问题的答案；缺失时 reviewer 应明说“口吻焦点无法判定”而非凭猜测判。
- **writing-reviewer verdict 细则**：口吻与站位越界（命令式指挥客户/批评既往/替客户下合规涉密选型判断/替第三方部委代述判断/让下属多想）任一命中即 `红线未清`，不降格为“要改”。
- **reviewer-routing 决策表**：重体裁扩至 {G1, G2, G3, G4, G5, G8}；口吻与站位焦点**独立派人不与他焦点合并**（合并会让 reviewer 把注意力花在更容易检的 AI 味上）。
- **scan 终端 PASS 文案**：`✅ PASS — 全部红线和软阈值通过，可以交付` → `✅ L1 PASS` + 显式警示 `L1 PASS ≠ 可以交付`，并说明哪三类抓不到、下一步该派谁。原文案正是本轮误判的直接诱因。

### Fixed（流程缺陷，非文本缺陷）

- **`SKILL.md` step 2.0.1 reviewer 不可省铁律**：≥ 500 字的稿子，脚本全绿不等于通过；**本轮未 spawn 过 reviewer 而输出 verdict = 协议违规**。主对话写了这稿、对自己的措辞已脱敏，自审不能替代 clean context。
- **不得为过软阈值而降语体**（SKILL step 3.2 + stance-and-register §5.4 + anti-ai-taste §2.5.1）：把“这一部分”改成“大头”以压低 scan 计数，是用工具指标换文风质量。降密度靠删空话，不靠降语体。reviewer 见此直接判要改。

## [8.0.0]（2026-07-03）零历史包袱重构：单引擎 scan + 声音匹配 + 事实第四态 + 全站标点 dogfood

> 调研（官方 best-practices + 社区技能）→ 计划 v1（R1/R2/R3 三轮 clean-context 评审收敛到 v4）→ 八工作流实现（WS-1 至 WS-8）→ WS-1 与 prose WS 各一轮对抗评审 → 迭代。全程 clean-context 反推、机器可核项一律脚本复核。

### ⚠️ Breaking

- **scan 单引擎**：CI 硬闸从独立的 `scan-hard-gate.sh` 改为 `scan-ai-taste.sh --genre base --json`（base profile = 无体裁豁免、保留 context 语境白名单）。`scan-hard-gate.sh` 删除，其唯一独有检查（H2.1 错误文号占位 `〔YYYY〕`/`（待补文号）`）端口进 scan。
- **scan-output 契约版本** `7.0 → 8.0`（`scan-ai-taste.sh` + `schemas/scan-output.schema.json` const 同步）；`--json` 新增可选 `violations` 数组（`rule`/`severity`/`line`/`matched` 结构化命中，弃 stdout 反解析）。
- **误报降级**：`不是…而是`/`让我们`/路标词从零容忍红线降为**软 WARN（exit 2）不 FAIL**；讲话稿（G2）对 `让我们`、随笔（G6）对低频 `不是…而是` 显式豁免。红线只保留跨体裁无歧义字面残留。
- **否定平行结构同一性判断下沉 L3 reviewer**：L1 只做同段块内**字面**否定平行 ≥3 次的可数代理（`不是.{1,15}?而是` 惰性量词，命中只 WARN 不 FAIL），语义同构判断交 reviewer。G8 单次 `不仅…更是` 由 L1 硬判改 L3 语义捕获，Example H 措辞由“必扣”软化为“L3 应判为要改”。
- **Rollback**：`git checkout` v7.0.1 tag。

### Added

- **声音匹配**（`references/voice-matching.md` + SKILL §2.5）：门控仅 G6 随笔 / G7 自媒体（公文报告的“声音”是体裁规范、非个人声纹）。tier-1 即时六维观察不落盘；tier-2 可选画像落**用户自己项目仓** `.writing-voice/<genre>.md`（插件不携带声纹、不向量化）。核心认知“不像 AI ≠ 像我”，声音层不覆盖任何红线。
- **触发 / 路由校准 harness**（`evals/trigger-calibration.md`）：技能调用轴（should-fire / should-not-fire）+ mode 路由轴 + G8 reviewer 判词稳定性抽检，**人在环手动跑**（技能唤起是非确定性决策，自动测只会 bit-rot）。
- **constitution 实质轴锐化**：空话可证伪测试（换主语仍成立 = 空话，豁免政治表态 boilerplate）；事实敬畏**第四态**（推断 / 预测就地标前提）；**无声**（抹平作者声音，仅 G6/G7 失败）与**无菌**（去 AI 味丢具体数字专名变空泛，全体裁失败）双态；So-What 收口（收窄到问题 / 研究类调研 + 汇报 + 议论评论，豁免情况类调研 + 抒情随笔，G6 内按子类型判）；非目标（别优化 AI 检测器）；§7 运行时护栏（勿把 Polish 套 `/loop`）；§7.1 评审独立性（锚本不进 reviewer、上轮不喂）；§7.2 理性化陷阱。
- **回归 fixture** `evals/fixtures/neg-parallel-dense.md`：锁 DoD#2(c)（同段紧挨 3 连否定平行在 base 触发 WARN、exit 2）。

### Changed

- **Polish Protocol（SKILL §2.2）回归守卫式迭代**：step 3 有序单维 sweep（达意 → 空话 → 结构 → 标点，深度按稿长分档、独立于 mode 路由表）；reviewer 同一轮内只 spawn 一次覆盖全焦点，跨轮回到 step 2 重 spawn 携改后稿产出新 verdict（最多 2 轮）；step 2.0 字数闸（< 500 字明示润色可省 reviewer）；step 2.5 missing-review 终态（不进自动改稿、上报用户）。
- **description 补 CN 热词触发器**：`去 AI 味`/`AI 感`/`这段读着像 AI 写的`/`帮我去味`/`DOCX 修订`。
- **manifest description 去 changelog 化**：`plugin.json` + `marketplace.json` 两处换简洁用户向文案、去版本戳、两处一致；version SSOT 收敛到 `plugin.json`，marketplace 删冗余 version / keywords 字段。
- **writing-reviewer 子代理**：`tools: Read, Grep`（核实运行时不调 Bash）+ 显式 `model: opus`（审稿质量与写作会话解耦）；同步第四态 / 无声无菌 / 润色不新增事实 diff 守卫。
- **引用拍平 + TOC**：`revision-checklist.md` / `logic-and-structure.md` 提到 SKILL §5 一跳直链；`failure-cases.md` / `peer-vs-self-revision.md` / `writing-coaching-arc.md` 补 `## 目录`。
- **eval-record schema**：`version` 枚举加 `8.0`，`genre` 枚举对齐 constitution §0 精确中文名。
- **全站标点 dogfood**：技能自写的**规约散文**（SKILL / constitution / reviewer / 各 reference 与 eval README / 新建 harness）统一 GB/T 15834 弯引号、零破折号、无直角引号；面向用户的文案模板与输出样例同守。**豁免边界**（有意为之、非债）：`anti-ai-taste-anchors.md` / `ai-taste-examples.md` / `failure-cases.md` / `llm-judge-research-report.md` 是禁用样式目录与官方公文逐字引文，必须陈列破折号 / ASCII 引号作教学反例；`renzhongran-coverage-matrix.md` 整档 `scan-skip`；表格 N/A 单元格 `| — |` 与引例 blockquote 内的破折号是结构 / 陈列用途。

### Fixed

- **贪婪量词少计密集排比**（clean-context 评审逮出的 blocker）：`不是.{1,15}而是` 贪婪版会把同段紧挨的第二处否定平行吞并，使 3 连排比只计 2、漏触 WARN。改惰性量词 `.{1,15}?`，shell 端 `NEG_PARALLEL_RE` 与 python 端同步。
- **`--genre` 末位缺值死循环**：`--genre`（或 `--target`/`--log-to`）作末位参数漏带值时 `shift 2` 在 bash 3.2 越界不移位、`while $#>0` 恒真挂死。改 `shift; [ $# -gt 0 ] && shift`。
- **prose WS 对抗评审 12 findings 全迭代**：含 2 MAJOR（< 500 字 Polish 路径歧义、多轮迭代缺 reviewer 重跑）+ So-What G6 双归类 + 悬空 §7.7 交叉引用 + steelman 焦点未定义 + 无来源量化断言（`3/10→8/10` 降为定性）等。

## [7.0.1] — 2026-06-06（修复 install-blocking manifest）

### Fixed

- **`plugin.json` 删除 `"agents": "./agents/"` 与 `"skills": "./skills/"` 字段**。v7.0.0 为注册 `writing-reviewer` 子代理而手写了 `"agents": "./agents/"`，但 Claude Code 插件 manifest 不接受 `agents` 写成目录字符串，`claude plugin validate` 报 `agents: Invalid input`，导致 `claude plugin install writing-polish@xuan-jiang` 整体失败。agents / skills / commands 一律由 `agents/`、`skills/`、`commands/` 目录**自动发现**，无需在 manifest 声明（官方 feature-dev / pr-review-toolkit 即如此）。删除后 `writing-reviewer` 子代理与 `writing-polish`、`runse` 两个 skill 均正常加载。
- 行为零变化：仅修 manifest，技能与子代理内容不动。

## [7.0.0] — 2026-05-28（两世界拆分：per-use 自然语言反馈 + 数值评分下沉离线 + 任仲然立文实质轴）

### ⚠️ Breaking

- **评分链从 per-use 热路径整体移除**。每次改稿不再打 `0-3` 逐维分、不再写 `.writing-polish-trace/*.json`、不再 `max()` 汇总、不再有 5 维 mini-bar。改为 clean-context reviewer 返回**自然语言反馈 + 粗判闸门**（够好了 / 要改 / 红线未清）。依据：全行业改稿循环（Self-Refine / Reflexion / CRITIC / Constitutional-AI / Anthropic evaluator-optimizer cookbook）都用可执行 NL 反馈；数值逐维打分（G-Eval / Prometheus / MT-Bench）是**离线打榜**工具。
- **数值世界下沉 `evals/offline-harness/`**：`llm-judge-research-report.md`、`select-fewshot.sh`、`split-calibration.sh`、`scan-hard-gate.sh`、`eval-record.schema.json` 迁入，仅离线衡量 polisher 本身用。
- **删除** `prompts/`（整目录）、`prompts/reviewer.md`、`prompts/spot-check.md`、`schemas/reviewer-output.schema.json`、`scripts/auto-fix-loop.sh`、`.writing-polish-trace` 概念。
- **L3 reviewer 升级为 Claude Code 插件子代理** `agents/writing-reviewer.md`（只读工具 `Read, Bash, Grep`，结构性强制“只评不改”）；`plugin.json` 加 `"agents": "./agents/"`；`allowed-tools` 改 `Bash, Read, Edit, Write, Task`。
- **scan-output 契约版本** `6.0 → 7.0`（`scan-ai-taste.sh` + `schemas/scan-output.schema.json` const 同步）。
- **Rollback**：如需回到 v6.1 评分链，`git checkout` v6.1.0 tag。

### Added

- `agents/writing-reviewer.md`：clean-context 审稿子代理，按 立意 / 结构与论据 / 材料·事实 / AI味·标点 四焦点返回 `<feedback>` + `<verdict>`。
- **正向实质三焦点**（`constitution.md` §0.5）：立意 / 结构与论据 / 材料·事实——回应 Anthropic“单边评测导致单边优化”，补齐任仲然真正重视而 v6 缺失的“写得好”评价轴。
- **事实敬畏三态**（reviewer + Coach）：① 已有材料可证实 / ② 用户未提供需追问 / ③ 不得替用户编造。
- `references/coach-checkpoints.md`：Coach 监督生成弧（立意→构思→提纲→材料→结构，逐段 checkpoint）。
- `references/renzhongran-coverage-matrix.md`：任仲然《怎样写作》12 讲 → SKILL 行为 → reference → eval 的逐项继承审计矩阵。
- `evals/offline-harness/README.md` + `evals/README.md` 重写为“离线 dev-eval harness”。
- `split-calibration.sh` 非空 guard：`anchor=0` 时非零退出（code 4），杜绝 v6 那次 anchor 静默为空半年无人发现。

### Changed / Fixed

- **SKILL.md** 重写为 ~150 行：§0 两世界拆分 / §2.1 Coach 监督弧 / §2.2 Polish 4 步（L1 → reviewer → 串行改稿 → 验证）/ §4 四大审查焦点（替换 D1-D5 mini-rubric）。
- **constitution.md** 从“0-3 评分细则”改为“审稿判依据（好/差长啥样）”；D1-D5 折叠进单一“AI味·标点”焦点的四个面；剥离残留数值标签（`D4=2` 等）；§5 examples 保留为 before→after 参考对（双用途：reviewer 参考 + 离线 gold）。
- **reviewer-routing.md** 从“5 维→N reviewer”改为“焦点覆盖按长度/体裁分摊”，并发上限 5→3。
- **anchor 数据修复**：标 9 条 §5 人工 gold 记录 `verified: true`，`anchor-set.jsonl` 从 0 → 9，`eval-set.jsonl` 不再是 calibration 字节副本。
- **修正**：`scan-ai-taste.sh` 实际调用 `check-cn-quotes.py`，故后者保留（非冗余）；移除对已删 `auto-fix-loop.sh` 的提示。
- **文档债清零**：README 重写为 current-first（修 `min()`→反馈、删已不存在的 `evals.json`/`test-runner.sh` 文件树）；CONTRIBUTING 对齐 2026-05 官方 frontmatter（删 `effort`/`paths` 必填说法，修“直角引号”与国标矛盾）；TROUBLESHOOTING v4.2→v7.0；新增 `docs/status.md`；v4/v5 handoff + 过期 active memory + 旧调研归档至 `docs/archive/`。

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
  - §1.5.1“防火墙”在 IT 实物语境（机房 / 等保 / GB/T 22239 / WAF / NGFW / 入侵检测 / 部署 N 台 等）自动豁免
  - §1.5.2“对标”在党政咨询语境（政府工作报告 / 党中央 / 二十大 / 同级 / 国际先进 / 启示 / 经验 / 案例 等）自动豁免
- **Dynamic density thresholds**（§4 软阈值动态化）：按句子数计算阈值，不再固定 ≤ 3
  - 短文 < 200 句 → 阈值 ≤ 3（保持原阈值）
  - 中文 200-500 句 → 阈值 ≤ 6
  - 长文 500-1000 句 → 阈值 ≤ 9
  - 超长 ≥ 1000 句 → 阈值 ≤ 15
- **§1.8 咨询报告专属约束**（5 条）：第三方咨询机构对甲方交付物专用，含身份边界 / 结论先行 / 不背书厂商 / “其一/其二”分级 / 多方利益静默
- **§1.4.111 合规括号 7 类白名单**（docs-only）：法条文号 / 施行日期 / 缩写首释 / 表格备注 / 图表内嵌 / 计算说明 / 章节自引
- **6 篇新增锚本**（assets/real-world-anchors/）：
  - `06-cicpa-consulting-template.md` — 第三方咨询机构对甲方交付范本（cicpa 053 治理后）
  - `07-sic-digital-economy-report.md` — 国家数据局《数字中国发展报告（2024）》
  - `08-cyberspace-info-development.md` — 网信办《国家信息化发展报告（2024）》
  - `09-cicpa-info-plan-2021-2025.md` — 中注协五年信息化规划（甲方反向对照）
  - `10-ndrc-high-quality-development.md` — 发改委高质量发展新闻发布会发言
  - `11-gov-work-report-duibiao.md` — 北京 2024 政府工作报告“对标”用法
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
