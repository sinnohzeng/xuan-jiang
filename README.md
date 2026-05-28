# 轩匠 Xuan-Jiang

让 Claude Code 写出像人写的中文，而不是机器吐的中文。

轩匠是一个专注中文写作的 Claude Code 插件。它把任仲然 40 年公文写作方法论（《怎样写作》）转化为 AI 可执行的工作流，并配套了一套 230 余条规则的中文写作规范检查机制。规范来源覆盖 GB/T 15834-2011《标点符号用法》、GB/T 9704-2012《党政机关公文格式》、Wikipedia 官方《Signs of AI writing》完整版以及国务院办公厅、国家信息中心、国务院发展研究中心、财政部等机关的真实文件参考。

> 2026-04 重大重构：开发者工作流插件已迁出至独立仓库 [workflow-toolkit](https://github.com/sinnohzeng/workflow-toolkit)，这个仓库专注写作。

---

## 这个技能解决什么问题

让 AI 写中文稿子，常见三种不达标情况。

第一种是写出来“正确但没人想读”。通篇都对，但全是大词、政策口号、抽象动词，删一半字意思不变。这是 RLHF 训练后默认的“标准答案机”模式。

第二种是改稿改成“校对员”。AI 拿到一篇文稿，只会改错别字、调整标点、统一术语，遇到立意不清、结构失衡、材料不实这些根本问题就装看不见。

第三种是写出来一眼能看出“机器味”。破折号到处插、括号里塞补充信息、套话连接词反复出现、客服腔情感套话满天飞、伪极客腔战斗化叙事、互联网大厂黑话堆砌。读者看一眼就知道这是 AI 写的。

**v6.0 当前状态**（2026-05-28）：无历史包袱重构 + 协议化 SKILL + LLM 监督真落地 + 任仲然 65%→79% 继承。

- **L1 regex 硬 Gate**：`scripts/scan-hard-gate.sh`（CI 强制 30 条最小集）+ `scripts/scan-ai-taste.sh`（交付前 230+ 条 + `--json` / `--log-to` / `--target` flag，主对话可消费 JSON 路由 L2/L3）
- **L2 主对话内联 self-judge**：SKILL.md §3 内联 D1-D5 mini-rubric（5 行表格 + scoring anchor + 典型 fail），主对话不读 constitution.md 也能完整评分；不确信时再读详细 rubric
- **L3 clean-context 多 reviewer**：触发条件（draft > 2000 字 / 体裁 ∈ {规范公文/调研/述职/咨询} / L2 任一维 < 3）满足时，主对话单条消息内 spawn 3 个 Agent，prompt 模板 [`prompts/reviewer.md`](plugins/writing-polish/skills/writing-polish/prompts/reviewer.md)，返回严格 JSON 符合 [`schemas/reviewer-output.schema.json`](plugins/writing-polish/skills/writing-polish/schemas/reviewer-output.schema.json)，L2 与 L3 取 min（保守裁判）
- **零外部 API**：v6.0 起所有 LLM 调用由主 Claude Code session 承担；删除 v5.x dev-only `llm-judge-runner.py` / `model_adapter.py` / `self-refine-loop.py`
- **三契约层**（schemas/）：scan-output / reviewer-output / eval-record JSON Schema，约束 scan-ai-taste.sh / reviewer Agent / 日志 jsonl 的 I/O 形状
- **任仲然继承度补齐**：新增 [`writing-coaching-arc.md`](plugins/writing-polish/skills/writing-polish/references/writing-coaching-arc.md)（L1§2 观察+L1§3 摹仿三段弧+L1§4 大胆写+L2§3 规律再造）+ [`peer-vs-self-revision.md`](plugins/writing-polish/skills/writing-polish/references/peer-vs-self-revision.md)（L12 改自己 vs 改他人辨证法 + L3 reviewer "他批"礼貌必读）

完整协议见 [`SKILL.md`](plugins/writing-polish/skills/writing-polish/SKILL.md)（212 行，6 段 protocol 剧本）。v5.x → v6.0 break changes + calibration 对比见 [`evals/v6.0-baseline/comparison.md`](plugins/writing-polish/skills/writing-polish/evals/v6.0-baseline/comparison.md)。

---

## 基础能力（v4.3 沉淀，v5.x 保留不动）

writing-polish v4.3 配套了三组方法对应这三种情况。

一是把任仲然全书 8 万字的方法论结构化成 7 大文体的专属审稿标准。AI 由此知道公文要看立意、调研要看真实深高新活、述职要看以实以数以事和绩取胜。

二是把何其芳 12 项修改清单、五维结构性审查以及老石 5 项调研报告体会落地为可勾选的清单。AI 不再只当校对员。

三是建立 230 余条规则与 `scripts/scan-ai-taste.sh` 自动校验。AI 改完的稿子必须通过 grep 扫描才允许交付。**v4.3 关键升级**：

- **上下文感知白名单**：「防火墙」在 IT 实物语境（机房 / 等保 / WAF / NGFW）自动豁免；「对标」在党政咨询语境（政府工作报告 / 党中央 / 同级 / 国际先进）自动豁免。±2 行扩窗匹配，告别一刀切误判
- **千句密度动态阈值**：短文 < 200 句 ≤ 3，长文 ≥ 1000 句 ≤ 15。IT 行业必备术语在长文中合理高频不再触发警告
- **§1.8 咨询报告专属约束**：第三方咨询机构对甲方交付的 5 条身份铁律（不锚甲方规划 / 结论先行 / 不背书厂商 / 「其一/其二」分级 / 多方利益静默）
- **11 篇真实锚本**：含 cicpa 第三方咨询交付范本 + 政府工作报告对标用法 + 国家数据局 / 网信办 / 发改委公开报告
- **evals 双轨化**：6 条 fixtures 入库（含 2 条反向哨兵防漏检），fixtures 在 v6.0 已用新 `--json` 输出回归通过；v5.x `test-runner.sh` / `calibration-runner.sh` 已归档 evals/legacy/v5.x/
- **历史**：v5.0/v5.1 范式探索遗产已被 v6.0 重构超越，详见 CHANGELOG.md v6.0 entry break-change 清单

---

## 安装

```bash
claude plugin marketplace add https://github.com/sinnohzeng/xuan-jiang.git
claude plugin install writing-polish@xuan-jiang
```

调用：`/writing-polish` 或拼音别名 `/runse`。

---

## v4.2 完整能力

### 一、七大文体专属工作流

| 文体 | 审查标准 | 典型场景 |
|------|---------|---------|
| 规范性公文 | 政治性、规范性、操作性 | 通知、意见、报告、决议、纪要 |
| 领导讲话稿 | 三个吃透与五维度（实度、深度、高度、新鲜度、气势） | 会议讲话、动员部署 |
| 调研报告 | 真实深高新活六字标准与老石 5 项体会 | 专题调研、情况报告 |
| 述职报告 | 三取胜：以实、以数、以事和绩 | 年度述职、考核述职 |
| 汇报发言稿 | 四种子类型各有侧重 | 汇报、座谈、对照检查 |
| 随笔杂文 | 真情智善理美、有料有趣有度 | 评论、随笔、杂感 |
| 自媒体 | 短快真实新与标题术、开头术 | 公众号、头条、短视频 |

每种文体配套了原书摘录的方法论以及一份可勾选的操作清单。比如领导讲话稿的“三个吃透”是 13 项操作清单，从“上网搜信息”到“与领导点对点接上头”逐项确认。

### 二、AI 味免疫机制（v4.2 完整版）

#### AI 味的五层成因

理解原理胜于死记词表。AI 味是五层叠加：

1. **训练目标**。RLHF 把模型推向高通过率，温和、完整、安全的“标准答案机”。
2. **解码策略**。生成时 token 概率最高的句子，是统计上最像好答案的句子，不是某个真人会写的句子。
3. **训练数据同质化**。互联网被 AI 反向污染，模型学到上一代模型已加工过的模板。
4. **统计性思维替代语言思维**。人是先有想法再找词；AI 是预测下一个最可能的词，倾向最安全最高频。
5. **戏剧化偏好（v4.1 新增）**。AI 受互联网产品文案、游戏文案、自媒体爆款标题污染，倾向用动作化、战斗化、夸张化词汇制造冲击感，但正式中文书面语应平实克制。

<!-- scan-skip -->
#### 230 余条规则分类

本节为元论述，列举所有规则分类与代号，scan-ai-taste.sh 会跳过本节扫描。

```
红线 156 条
├── §1.1 中文词汇  50 条（互联网政策口号、学术翻译腔、套话连接词、情感空话、客服情感套话）
├── §1.2 英文词汇  50 条（v4.2 扩到 50，覆盖 Wikipedia 完整词表）
├── §1.3 句式      20 条（否定平行、三连排比、说教反射、模糊归因）
├── §1.4 标点格式  17 条（v4.2 新增加粗冒号、数字 list、标题化、英文标点穿插四条）
├── §1.5 戏剧化偏好与大厂黑话与网络口语（v4.1 引入）
│   ├── §1.5.1 战斗化叙事
│   ├── §1.5.2 互联网大厂黑话（v4.2 补腾讯美团长尾）
│   ├── §1.5.3 网络口语与网感词
│   └── §1.5.4 程序员产品经理腔（软警告，v4.2 文档化判定规则）
├── §1.6 元注释与客服话术（v4.2 新增，约 20 条）
│   ├── §1.6.1 元注释开头
│   ├── §1.6.2 自我介绍与身份声明
│   ├── §1.6.3 免责声明
│   ├── §1.6.4 服务话术段尾
│   └── §1.6.5 拟人化集体代词
└── §1.7 Wikipedia 长尾盲区（v4.2 新增，8 类）
    ├── §1.7.1 Reference markup bugs（oaicite 等残留代码）
    ├── §1.7.2 Placeholder dates（占位符日期）
    ├── §1.7.3 Elegant variation
    ├── §1.7.4 Avoidance of basic copulatives
    ├── §1.7.5 Inline-header vertical lists
    ├── §1.7.6 Skipping heading levels
    ├── §1.7.7 Thematic breaks before headings
    └── §1.7.8 Concrete 滥用

橙线 60 条 + 结构反模式 17 条（v4.2 加话题漂移与形容词堆砌两条）
```
<!-- /scan-skip -->

完整清单见 [references/anti-ai-taste-anchors.md](plugins/writing-polish/skills/writing-polish/references/anti-ai-taste-anchors.md)。每一条都有”为什么是 AI 味”的简短理由，让 Claude 理解原理而非死记词表。

<!-- scan-skip -->
#### v4.2 新增重点

本节为元论述，列举 v4.2 新规则与禁用词示例，scan-ai-taste.sh 会跳过本节扫描。

- **§1.6 元注释与客服话术**：覆盖”作为一个 AI 助手”、”以下是几点说明”、”希望对您有帮助”等 RLHF 客服腔指纹，约 20 条。
- **§1.7 Wikipedia 长尾盲区**：对照 Wikipedia 完整版补 8 类，含 oaicite 残留代码、Placeholder dates（2025-xx-xx 等）、雅化变奏、回避系动词等确凿 AI 输出指纹。
- **§1.4 标点格式扩展**：每段加粗冒号、数字 list 滥用、标题化偏好、英文标点穿插。
- **工程化收尾**：新增 `scripts/check-dependencies.sh` 依赖检查、`scripts/auto-fix-loop.sh` 自动修复循环、`scripts/docx-review-workflow.py` DOCX 一键化、`evals/test-runner.sh` 回归批跑、`references/failure-cases.md` 失败案例库、`references/citation-spec.md` 模糊归因专题。
- **dogfooding 收紧**：SKILL.md 自身去除”对标””范文锚点”等被自身规则禁的词；evals/README.md 收紧 scan 豁免边界。
<!-- /scan-skip -->

#### v4.1 新增的几类典型 AI 味场景

<!-- scan-skip -->
本节为元论述，列举的违规词是教学示例，scan-ai-taste.sh 会跳过本节扫描。

**(1) 中文标点必须用大陆国标弯引号**（依据 GB/T 15834-2011 § 4.8）

| 正确 | 错误 |
|------|------|
| 他说"很重要"、'七月流火'是什么意思 | 他说"很重要"（ASCII 直引号） |
| 双层嵌套：外层"X'内层'X" | 他说「很重要」（直角引号是港台或日式） |

直角引号「」『』在大陆党政公文不用。AI 默认输出 ASCII 直引号或乱用直角引号，是中英语料混训留下的指纹。

**(2) 数学符号代替自然语言**

正式中文里禁用 `+` 加号、`=` 等号、`→` 箭头、`&` 符号、`/` 斜杠（在并列短语位置）。这是程序员或产品经理腔的指纹。

| 错误（机械替换也错） | 正确（重构句子） |
|---|---|
| 数据 + 算法 + 算力 | 数据、算法和算力构成三大要素 |
| 数据和算法和算力 | 同上 |
| 代码 = 文档 | 代码本身就是文档，不再单独维护说明 |
| 效率 + 质量 | 既要追求效率，也要保证质量 |

改写规则强调"重构整段表述"，不接受机械替换为"和""与"。

**(3) 半中半英术语**（依据 [RightCapitalHQ/chinese-style-guide](https://github.com/RightCapitalHQ/chinese-style-guide) 与 [zh-style-guide](https://zh-style-guide.readthedocs.io/)）

| 错误 | 正确 |
|---|---|
| 操作 checklist | 操作清单 |
| 前端 dev 服务器 | 前端开发服务器 |
| AI workflow | AI 工作流 |
| prompt 工程 | 提示词工程（首次出现可加括注 Prompt Engineering） |
| 一份 framework | 一套框架 |

商品名、产品名、公司名（GitHub、Anthropic、DOCX）保留英文。
<!-- /scan-skip -->

<!-- scan-skip -->
**(4) 战斗化叙事（§1.5.1）**

| 错误 | 正确 |
|---|---|
| 三件武器 | 三种方法、三个工具 |
| 三层防御工作流 | 三步检查流程 |
| 自动闸门 | 自动检查、校验 |
| 装上一套规则 | 配套一套规则 |
| 加装免疫系统 | 引入免疫机制 |
| 翻车、踩坑 | 失误、积累实施经验 |
| 吐文字、吐结果 | 输出文本、产出 |
| 跑通、走通 | 运行稳定、经实践验证 |

**(5) 互联网大厂黑话（§1.5.2）**

阿里系、字节系、百度系等大厂黑话全部禁用。

| 错误 | 正确 |
|---|---|
| 抓手、切入点 | 依据、载体、着力点 |
| 赋能、深度赋能 | 支持、推动、提升 XX 能力 |
| 闭环、生态闭环 | 流程、全程管理 |
| 拉通、对齐 | 统筹、对照、协调 |
| 链路、全链路 | 流程、各环节 |
| 沉淀下来 | 积累、形成 |
| 底层逻辑、顶层设计 | 基本原理、根本规律、总体设计 |
| 颗粒度 | 详细程度、标准、范围 |
| 对标 | 参照、比较 |
| 赛道 | 领域、方向 |

**(6) 网络口语与网感词（§1.5.3）**

| 错误 | 正确 |
|---|---|
| 本仓库、本文、本号 | 这个仓库、本指南、本说明（或不用代词） |
| 锚点、范文锚点 | 范例、参考样本、真实文件示例 |
| 硬约束、硬指标 | 强制规则、必须达到的标准 |
| dogfooding、吃自己狗粮 | 用自己的产品验证 |
| 干货、满满的干货 | 要点、重点内容 |
| 梭哈、All in、押注 | 投入、集中力量做 |
<!-- /scan-skip -->

#### 三步检查流程

```
第一步：写作前  →  必读核心机制、110 红线、10 段反例对照、1 至 2 个范文参考
第二步：写作中  →  每段写完做 11 项心理 grep（标点、客服词、对比句式、套话、空话、分词挂尾、ASCII 直引号、加号箭头、戏剧化词、大厂黑话）
第三步：交付前  →  scripts/scan-ai-taste.sh 自动扫描，红线达不到阈值禁止交付
```

#### 自动校验输出示例

```bash
$ bash scripts/scan-ai-taste.sh draft.md

▼ §1.4 标点红线（阈值 = 0）
  [X] 破折号: 1 处 (须 = 0)
  [X] §1.4.111 直角引号 「」『』（港台 / 日式）: 3
  [X] §1.4.112 数学符号代替自然语言（+ = →）: 2

▼ §1.5 戏剧化、大厂黑话、网络口语（阈值 = 0）
  [X] §1.5.1 战斗化叙事: 4 处
  [X] §1.5.3 网络口语与网感词: 6 处

▼ 句长方差（阈值 ≥ 8）
  [V] 句长标准差: 12.3 / 平均 21 字 / 句子数 18

================================================
[X] FAIL: 有 5 项硬红线违规，禁止交付
```

退出码：0 为 PASS、1 为 FAIL（红线违规）、2 为 WARN（软阈值警告）。可直接接进 CI 或交付脚本。

### 三、范文与真实文件参考库（v4.0 新增）

写作辅助时，AI 不凭空生成。它先读 1 至 2 个真实范文做摹仿对照。

#### 8 个《怎样写作》原书范文（assets/anchor-essays）

| 编号 | 范文 | 学什么 |
|---|---|---|
| 01 | 红黄绿三盏灯 | 小素材一材多用，茅盾“拉拉扯扯法” |
| 02 | 粮食生产讲话稿 | 内容摹仿，老话题写新意 |
| 03 | 生态兴省演讲稿 | 结构紧凑，五点感想七分钟讲完 |
| 04 | 问题就是时代的口号 | 立意贯穿，从一句名言到一篇文章 |
| 05 | 全省农村工作会议讲话 | 指导性表达，量化要求与考核机制 |
| 06 | 述职报告三取胜 | 以实、以数、以事和绩 |
| 07 | 学习会发言稿 | 三个结合得紧密 |
| 08 | 基层党组织任期意见 | 专项性意见一步入题 |

#### 5 个真实政府文件参考（assets/real-world-anchors）

| 编号 | 来源 | 学什么 |
|---|---|---|
| 01 | 国务院办公厅 政务平台移动端建设指南 | 工作原则段：坚持 XX 与长句分号 |
| 02 | 国家信息中心 低空经济问题诊断 | 问题章节：虽然 X 但仍存在 Y 与数据支撑 |
| 03 | 国家信息中心 低空经济政策建议 | 政策章节：动宾短语标题与省略主语 |
| 04 | 国务院发展研究中心 钱平凡数据经济文章 | 一是 XX 的 XX：标准公文列举与数据论证 |
| 05 | 财政部 中小企业数字化转型试点通知 | 八字对仗动宾短语与四字短语正文 |

每个参考文件都标注了 URL 和季度续抓办法，URL 失效时用 Firecrawl 续抓即可。

### 四、DOCX 修订模式

支持 Track Changes（修订模式），默认作者“任仲然”。判定逻辑：

| 场景 | 信号 | 策略 |
|---|---|---|
| 修订模式交付 | 客户给批注版 docx | 定点精修，避免每段都动 |
| 大范围重写 | 用户明确说“重写” | 全面对齐参考文件，可重构段落 |
| 简要版新写 | 让起草新版或压缩 | 按参考文件直写，不带 track changes |

技术路线见 [references/docx-editing-guide.md](plugins/writing-polish/skills/writing-polish/references/docx-editing-guide.md)。依赖 pandoc（读取）以及 docx-editor 与 python-docx（编辑）。

---

## 文件结构

```
plugins/writing-polish/skills/writing-polish/
├── SKILL.md                          主入口（v4.2 含快速导航与失败重写指引）
├── scripts/
│   ├── scan-ai-taste.sh              第三步自动校验（v4.2 含 §1.6 §1.7 与 --suggest-fix）
│   ├── check-cn-quotes.py            标点与中英混排校验（v4.2 加英文标点穿插检测）
│   ├── word-count-check.sh           句长方差与段落同质化检查
│   ├── check-dependencies.sh         pandoc / docx-editor 等依赖检查（v4.2 新增）
│   ├── auto-fix-loop.sh              scan 失败时自动修复循环（v4.2 新增）
│   └── docx-review-workflow.py       DOCX 修订模式一键化（v4.2 新增）
├── references/                       按需载入的深度文档
│   ├── anti-ai-taste-anchors.md      156 条红线、60 条橙线、17 条结构反模式
│   ├── ai-taste-examples.md          反例对照（v4.2 加文体与修改深度两个维度）
│   ├── failure-cases.md              真实失败案例库（v4.2 新增）
│   ├── citation-spec.md              模糊归因改写专题（v4.2 新增）
│   ├── writing-methodology.md        五种思维与立意构思提纲材料语言
│   ├── genre-guide.md                7 大文体审查标准、三吃透清单、三取胜模板
│   ├── revision-checklist.md         何其芳 12 项与三维系统审查
│   ├── logic-and-structure.md        逻辑主线与结构模式审查
│   ├── docx-editing-guide.md         DOCX Track Changes 编辑全指南
│   └── gongwen-format.md             GB/T 9704 党政公文格式规范
├── assets/                           用于产出的素材
│   ├── anchor-essays/                《怎样写作》原书 8 范例
│   ├── real-world-anchors/           真实政府文件参考
│   └── docx-templates/               DOCX 修订模板
└── evals/
    ├── evals.json                    20 条 regression test（v4.2 加反向用例与边界 case）
    ├── test-runner.sh                批量回归测试（v4.2 新增）
    └── README.md                     主观输出测试方法
```

---

## 使用方式

### 写作辅助

```
帮我写一篇关于安全生产的讲话稿
搭个提纲，主题是数字化转型
```

Claude 的工作流：识别文体，读对应文体 genre-guide，选 1 至 2 个范文摹仿，立意构思，搭提纲，充实内容，最后跑第三步校验。

### 审稿润色

```
帮我润色这篇文章
审稿 /path/to/speech.docx
```

Claude 的工作流：通读识别，结构性审查（立意、内容、结构、逻辑、五种思维），细节打磨，跑第三步校验，输出审查报告与修改稿。

### DOCX 修订

```
用修订模式帮我改 /path/to/document.docx
```

默认 Track Changes，作者为“任仲然”。可指定其他作者：用张三的名义修改。

---

## 前置依赖（可选）

```bash
brew install pandoc                  # macOS / DOCX 读取
apt install pandoc                   # Ubuntu 或 Debian
pip install docx-editor python-docx  # DOCX 编辑（修订模式）
```

不安装也能用。Markdown 和纯文本无依赖，DOCX 依赖只在读写 Word 时才用。

---

## 跨平台移植

原生支持 Claude Code。其他 AI 编程工具直接复制 `SKILL.md` 和 `references/`：

| 工具 | 规则目录 | 格式 |
|------|---------|------|
| Claude Code | Plugin 或 `~/.claude/skills/` | Markdown |
| Claude.ai | Skills 上传 zip | Markdown |
| Cursor | `.cursor/rules/` | `.mdc`（Markdown 加 YAML frontmatter） |
| Windsurf | `.windsurf/rules/` | Markdown（12K 字符限制） |
| Cline | `.clinerules/` | Markdown |
| Copilot | `.github/instructions/` | Markdown 加 YAML |

---

## 方法论与规范来源

写作方法论来自任仲然《怎样写作》（党建读物出版社 2019 年）。任仲然曾任中组部研究室主任，40 余年公文写作与审稿经验。

中文标点规范依据 GB/T 15834-2011《标点符号用法》（教育部语言文字信息管理司归口）。中英混排规范参考 [zh-style-guide](https://zh-style-guide.readthedocs.io/) 与 [RightCapitalHQ/chinese-style-guide](https://github.com/RightCapitalHQ/chinese-style-guide)。

AI 味约束清单基于 2024 至 2026 年中英文社区调研，主要信源包括 Wikipedia 官方《Signs of AI writing》指南、Originality.ai 千万词级语料分析、GPTZero AI Vocabulary 数据库，以及国务院办公厅、国家信息中心、国务院发展研究中心、财政部等机关真实文件参考。

| 版本 | 发布 | 关键变化 |
|---|---|---|
| v3.0.0 | 2026-04 | 7 大文体与何其芳 12 项 |
| v3.1.0 | 2026-04 | 离线参考文件库与初版 AI 味 SOP（约 30 条规则） |
| v4.0.0 | 2026-04 | 110 条 AI 味规则、8 范例、三步检查、符合 2026 Anthropic Skills 标准 |
| v4.1.0 | 2026-04 | 新增戏剧化偏好分类（§1.5）、GB/T 15834 弯引号、数学符号、半中半英三类红线，规则总数到 140 余条 |
| v4.2.0 | 2026-04 | 新增 §1.6 客服话术 20 条、§1.7 Wikipedia 长尾 8 类、§1.4 标点 4 条；工程化收尾（依赖检查、自动修复、DOCX 一键化、回归批跑、失败案例库、模糊归因专题）；自检收紧（SKILL.md 自身去自违规、evals 豁免边界收紧）；规则总数到 230 余条 |

---

## 相关项目

- [workflow-toolkit](https://github.com/sinnohzeng/workflow-toolkit)：开发者日常工作流 Skill 集合（已从这个仓库拆分）

## License

MIT。写作方法论版权归原作者任仲然所有。

---

> 任仲然在《怎样写作》中写道：“好文稿好文章无疑是写出来的，但更重要的是改出来的。"
