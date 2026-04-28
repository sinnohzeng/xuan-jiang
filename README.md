# 轩匠 Xuan-Jiang

让 Claude Code 写出像人写的中文，不是机器吐的中文。

轩匠是一个专注中文写作的 Claude Code 插件。它把任仲然 40 年公文写作方法论（《怎样写作》）转化为 AI 可执行的工作流，并加装了一套 110 条硬约束的「AI 味免疫系统」。

> 2026-04 重大重构：开发者工作流插件已迁出至独立仓库 [workflow-toolkit](https://github.com/sinnohzeng/workflow-toolkit)，本仓库专注写作。

---

## 这个 Skill 解决什么问题

让 AI 写中文稿子，常见三种翻车场景。

第一种翻车是写出来「正确但没人想读」。通篇都对，但全是大词、政策口号、抽象动词，删一半字意思不变。这是 RLHF 训练后默认的"标准答案机"模式。

第二种翻车是改稿改成「校对员」。AI 拿到一篇文稿，只会改错别字、调整标点、统一术语，遇到立意不清、结构失衡、材料不实这些根本问题就装看不见。

第三种翻车是写出来一眼能看出「机器味」。破折号到处插、括号里塞补充信息、套话连接词反复出现、客服腔情感套话满天飞。读者看一眼就知道这是 AI 写的。

writing-polish v4.0 装备了三件武器对应这三种翻车：

一是把任仲然全书 8 万字的方法论结构化成 7 大文体的专属审稿标准，让 AI 知道「公文要看立意、调研要看真深高新活、述职要看三取胜」。

二是把何其芳 12 项修改清单 + 五维结构性审查 + 老石 5 项体会落地为可勾选的 checklist，让 AI 不再当校对员。

三是建立 110 条硬约束 + scripts/scan-ai-taste.sh 自动闸门，AI 改完的稿子必须通过 grep 扫描才允许交付。

---

## 安装

```bash
claude plugin marketplace add https://github.com/sinnohzeng/xuan-jiang.git
claude plugin install writing-polish@xuan-jiang
```

调用：`/writing-polish` 或拼音别名 `/runse`。

---

## v4.0 完整能力

### 一、七大文体专属工作流

| 文体 | 审查标准 | 典型场景 |
|------|---------|---------|
| 规范性公文 | 政治性、规范性、操作性 | 通知、意见、报告、决议、纪要 |
| 领导讲话稿 | 三个吃透 + 实度/深度/高度/新鲜度/气势 | 会议讲话、动员部署 |
| 调研报告 | 真实深高新活六字标准 + 老石 5 项体会 | 专题调研、情况报告 |
| 述职报告 | 三取胜：以实/以数/以事和绩 | 年度述职、考核述职 |
| 汇报发言稿 | 四种子类型各有侧重 | 汇报、座谈、对照检查 |
| 随笔杂文 | 真情智善理美 + 有料有趣有度 | 评论、随笔、杂感 |
| 自媒体 | 短快真实新 + 标题术 + 开头术 | 公众号、头条、短视频 |

每种文体配套了原书摘录的方法论加上一份可勾选的操作 checklist。比如领导讲话稿的「三个吃透」就是 13 项操作清单，从「上网搜信息」到「与领导点对点接上头」逐项确认。

### 二、AI 味免疫系统（v4.0 灵魂）

#### 110 条硬约束分类

```
红线 110 条
├── 中文词汇  50 条（互联网政策口号 / 学术翻译腔 / 套话连接词 / 情感空话 / 客服情感套话）
├── 英文词汇  30 条（Claude 中英混训会带英文模式入中文）
├── 句式      20 条（否定平行 / 三连排比 / 说教反射 / 模糊归因）
└── 标点格式  10 条（破折号 / 括号内插入 / 冒号三段分号 / 自造概念加引号 / 装饰 emoji）

橙线 60 条 + 结构反模式 15 条
```

完整清单见 [references/anti-ai-taste-anchors.md](plugins/writing-polish/skills/writing-polish/references/anti-ai-taste-anchors.md)。每一条都有「为什么是 AI 味」的简短理由，让 Claude 理解原理而非死记词表。

#### 三层防御工作流

```
L1 写作前  ➜  必读核心机制 + 110 红线 + 10 段反例对照 + 1-2 个范文锚点
L2 写作中  ➜  每段写完做 10 项心理 grep（标点、客服词、对比句式、套话连接、空话、分词挂尾）
L3 交付前  ➜  scripts/scan-ai-taste.sh 自动扫描，红线达不到阈值禁止交付
```

#### scan-ai-taste.sh 闸门示例

```bash
$ bash scripts/scan-ai-taste.sh draft.md

▼ §1.1 中文词汇红线（阈值 = 0）
  ✗ 中文红线词命中: 7 处
  3:在新时代背景下，要充分推动基层治理升级。

▼ §1.3 句式红线（阈值 = 0）
  ✗ 否定平行结构: 1 处

▼ 句长方差（阈值 ≥ 8）
  ✓ 句长标准差: 12.3 / 平均 21 字 / 句子数 18

================================================
[X] FAIL: 有 4 项硬红线违规，禁止交付
```

退出码：0 = PASS、1 = FAIL（红线违规）、2 = WARN（软阈值警告）。可直接接进 CI 或交付脚本。

### 三、范文锚点库（v4.0 新增）

写作辅助时，AI 不凭空生成。它先读 1-2 个真实范文做摹仿对照。

#### 8 个《怎样写作》原书锚点（assets/anchor-essays/）

| 编号 | 范文 | 学什么 |
|---|---|---|
| 01 | 红黄绿三盏灯 | 小素材一材多用，茅盾"拉拉扯扯法" |
| 02 | 粮食生产讲话稿 | 内容摹仿，老话题写新意 |
| 03 | 生态兴省演讲稿 | 结构紧凑，五点感想七分钟讲完 |
| 04 | 问题就是时代的口号 | 立意贯穿，从一句名言到一篇文章 |
| 05 | 全省农村工作会议讲话 | 指导性表达，量化要求加考核机制 |
| 06 | 述职报告三取胜 | 以实/以数/以事和绩 |
| 07 | 学习会发言稿 | 三个结合得紧密 |
| 08 | 基层党组织任期意见 | 专项性意见一步入题 |

#### 5 个真实政府文件锚本（assets/real-world-anchors/）

| 编号 | 来源 | 学什么 |
|---|---|---|
| 01 | 国务院办公厅 政务平台移动端建设指南 | 工作原则段：坚持 XX + 长句分号 |
| 02 | 国家信息中心 低空经济问题诊断 | 问题章节：虽然...但仍存在 + 数据支撑 |
| 03 | 国家信息中心 低空经济政策建议 | 政策章节：动宾短语标题 + 省略主语 |
| 04 | 国务院发展研究中心 钱平凡数据经济文章 | 一是 XX 的 XX：标准公文列举 + 数据论证 |
| 05 | 财政部 中小企业数字化转型试点通知 | 八字对仗动宾短语 + 四字短语正文 |

每个锚本都标注了 URL 和季度续抓 SOP，URL 失效时用 Firecrawl 续抓即可。

### 四、DOCX 修订模式

支持 Track Changes（修订模式），默认作者「任仲然」。判定逻辑：

| 场景 | 信号 | 策略 |
|---|---|---|
| 修订模式交付 | 客户给批注版 docx | 定点精修，避免每段都动 |
| 大范围重写 | 用户明确说"重写" | 全面对齐锚本，可重构段落 |
| 简要版新写 | 让起草新版或压缩 | 按锚本直写，不带 track changes |

技术路线见 [references/docx-editing-guide.md](plugins/writing-polish/skills/writing-polish/references/docx-editing-guide.md)。依赖 pandoc（读取）+ docx-editor + python-docx（编辑）。

---

## 文件结构

```
plugins/writing-polish/skills/writing-polish/
├── SKILL.md                          222 行，主入口（v4.0 从 446 行压缩到 222 行）
├── scripts/
│   ├── scan-ai-taste.sh              249 行，L3 自动闸门
│   └── word-count-check.sh            45 行，句长方差检查
├── references/                       按需载入的 8 个深度文档
│   ├── anti-ai-taste-anchors.md      470 行，110 红线 + 60 橙线 + 15 结构反模式
│   ├── ai-taste-examples.md          233 行，10 段反例对照
│   ├── writing-methodology.md        264 行，五种思维 + 立意构思提纲材料语言
│   ├── genre-guide.md                7 大文体审查标准 + 三吃透 + 三取胜模板
│   ├── revision-checklist.md         何其芳 12 项 + 三维系统审查
│   ├── logic-and-structure.md        逻辑主线 + 结构模式审查
│   ├── docx-editing-guide.md         DOCX Track Changes 编辑全指南
│   └── gongwen-format.md             GB/T 9704 党政公文格式规范
├── assets/                           用于产出的素材
│   ├── anchor-essays/                《怎样写作》原书 8 范文锚点
│   ├── real-world-anchors/           5 个真实政府文件锚本
│   └── docx-templates/               DOCX 修订模板
└── evals/
    ├── evals.json                    5 条 regression test
    └── README.md                     主观输出测试方法
```

---

## 使用方式

### 写作辅助

```
帮我写一篇关于安全生产的讲话稿
搭个提纲，主题是数字化转型
```

Claude 会：识别文体 ➜ 读对应文体 genre-guide ➜ 选 1-2 个范文锚点摹仿 ➜ 立意构思 ➜ 搭提纲 ➜ 充实内容 ➜ 跑 L3 闸门。

### 审稿润色

```
帮我润色这篇文章
审稿 /path/to/speech.docx
```

Claude 会：通读识别 ➜ 结构性审查（立意 / 内容 / 结构 / 逻辑 / 五种思维）➜ 细节打磨 ➜ 跑 L3 闸门 ➜ 输出审查报告 + 修改稿。

### DOCX 修订

```
用修订模式帮我改 /path/to/document.docx
```

默认 Track Changes，作者「任仲然」。可指定其他作者：「用张三的名义修改」。

---

## 前置依赖（可选）

```bash
brew install pandoc                  # macOS / DOCX 读取
apt install pandoc                   # Ubuntu / Debian
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
| Cursor | `.cursor/rules/` | `.mdc`（Markdown + YAML frontmatter） |
| Windsurf | `.windsurf/rules/` | Markdown（12K 字符限制） |
| Cline | `.clinerules/` | Markdown |
| Copilot | `.github/instructions/` | Markdown + YAML |

---

## 方法论来源与版本

写作方法论来自任仲然《怎样写作》（党建读物出版社 2019 年）。任仲然曾任中组部研究室主任，40 余年公文写作与审稿经验。

AI 味约束清单基于 2024-2026 年中英文社区调研，主要信源包括 Wikipedia 官方《Signs of AI writing》指南、Originality.ai 千万词级语料分析、GPTZero AI Vocabulary 数据库，以及国务院办公厅、国家信息中心、国务院发展研究中心、财政部等机关真实文件锚本。

| 版本 | 发布 | 关键变化 |
|---|---|---|
| v3.0.0 | 2026-04 | 7 大文体 + 何其芳 12 项 |
| v3.1.0 | 2026-04 | 离线锚本库 + 初版 AI 味 SOP（约 30 条规则）|
| v4.0.0 | 2026-04 | 110 条 AI 味硬约束 + 8 范文锚点 + 三层防御闸门 + 完整对标 2026 Anthropic Skills 标准 |

---

## 相关项目

- [workflow-toolkit](https://github.com/sinnohzeng/workflow-toolkit)：开发者日常工作流 Skill 集合（已从本仓库拆分）

## License

MIT。写作方法论版权归原作者任仲然所有。

---

> 任仲然在《怎样写作》中写道：「好文稿好文章无疑是写出来的，但更重要的是改出来的。」
