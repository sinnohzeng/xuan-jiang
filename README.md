# 怎样写作：Claude 写作技能

> **"好文稿好文章无疑是写出来的，但更重要的是改出来的。"**
> 任仲然《怎样写作》

一个基于《怎样写作》（任仲然）系统化写作方法论的 Claude Code 技能。不仅能帮你审查、优化、润色各类文稿，还能从立意构思开始辅助你完成整个写作过程。覆盖公文、讲话稿、调研报告、述职报告、汇报发言稿、随笔杂文、自媒体文章七大文体，支持 Markdown、DOCX、纯文本三种格式。

---

## 这是什么？

**writing-polish** 是一个 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 技能（Skill），它将一本凝聚了数十年党政机关写作经验的著作《怎样写作》全部十二讲的内容，转化为 AI 可执行的写作方法论和审稿工作流。

这个技能解决两个问题：

**一是"写不出来"的问题。** 当你面对空白文档不知从何下笔时，技能会按照立意、构思、提纲、材料、文风五个步骤，引导你搭建文稿的骨架和血肉。你可以说"帮我搭一个调研报告的提纲"或"帮我写一篇关于安全生产的讲话稿"，技能会根据文体特点给出专业的写作指导。

**二是"改不到位"的问题。** 当你有了初稿需要润色时，技能会按照"先大后小"的专业审稿流程，从立意主题到字词标点，用五种思维方式多维审视你的文稿。它不是简单地改几个错别字，而是像一位经验丰富的老笔杆子那样，先看骨架是否端正，再看血肉是否丰满，最后看皮肤是否光洁。

### 核心理念

这些原则来自原书，贯穿技能的每一个环节：

| 原则 | 含义 |
|------|------|
| **热写稿，冷改稿** | 写的时候趁热打铁，改的时候要晾一晾冷一冷。就像淬火，把烧红的铁钎放在冷水里才能变成钢钎 |
| **先大后小** | 先改立意主题和结构布局，再改段落语句，最后改字词标点。"一头扎进细微处"只能起到校对员的作用 |
| **以意役法** | 主题是元帅，"意犹帅也，无帅之兵，谓之乌合"。所有技巧和方法都要服从主题 |
| **先减后加** | "精简、去冗、消肿"。减法做完了再做加法 |
| **求精、求准** | 精：主题厚实深邃，思想精确无误，文辞精彩朴实。准：事实准确，判断精准，每段话都有风险意识 |
| **尊重原作** | 可改可不改的就不改。改别人的文稿要尊重精神劳动成果。但该改的一定要改到位 |

---

## 两大核心能力

### 能力一：写作辅助

当你需要从零开始写作或搭建框架时，技能按以下五个步骤辅助：

```
第一步：明确写作任务
├── 确认文体类型，加载文体专属写作标准
├── 确认写作目的和受众
└── 确认深度：搭提纲、写初稿、还是完整成稿

第二步：立意与构思
├── 锁定一个核心问题，选择独有而新鲜的角度
├── 避免"全而又全"的陷阱：一事一文，聚焦重点
└── 选小切口展大思路，确定写作的切入点

第三步：搭建提纲
├── 粗纲：搭建框架，拟定各级标题
├── 细纲：提炼基本判断和思想观点
└── 越往上一级标题越要有高度，越往下一级越要有实度

第四步：充实内容
├── 事例要典型不雷同，"解剖三五十只麻雀不如换一只小白鼠"
├── 数据及比例要用到位，抽象叙述不如具体数据有"实在感"
└── 材料与观点要协调统一

第五步：语言定调
├── 根据文体和受众确定语言风格
├── 朴实原则：少修饰语、忌生僻词、不绕圈子
└── 整齐美与参差美交替出现效果最佳
```

### 能力二：审稿润色

当你有了现成文稿需要修改时，技能按以下流程系统审查：

```
第一步：通读与识别
├── 完整阅读全文，不急于动笔
├── 识别文体类型（7种文体专属标准）
└── 判断修改深度（轻度润色 / 深度修改 / 结构重建）

第二步：结构性审查（先从大处着眼）
├── 立意与主题 — 主题是否清晰统领全文？
├── 内容与观点 — 事实是否真实？论据是否充分？
├── 结构设计 — "四梁八柱"是否稳妥？
├── 逻辑延展 — 逻辑主线是否贯穿始终？
└── 多维审视 — 用五种思维方式从不同角度发现问题

第三步：细节打磨（再从小处着手）
├── 语言 — 朴实精准？有无生造词汇？
├── 表达方式 — 叙述/议论/说明是否得当？
├── 字斟句酌 — 标点、用词、术语一致性
└── 去除 AI 痕迹 — 消除破折号行文、括号嵌套等 AI 特征

第四步：输出
├── 轻度润色 → 直接输出修改后全文
├── 深度修改 → 审查报告 + 修改后全文
└── DOCX 回写 → Track Changes 修订模式编辑
```

---

## 七种文体专属标准

技能为每种文体都配备了专属的审查标准和操作化的审查问题，不是笼统地"帮你改改语言"，而是针对文体特点进行深度审查。

### 规范性公文

从政治性与政策性、规范性与权威性、指导性与可操作性三个维度审查。内置老石的公文写作三原则：克服泛泛而谈增强目的性，克服照抄照转增强针对性，克服文牍主义增强实用性。覆盖决议、意见、通知、报告、纪要五种常见文种。

### 领导讲话稿

审查"三个吃透"是否做到位：吃透真实情况、吃透上级精神、吃透领导意图。然后从实度、深度、高度、新鲜度、气势五个维度评估质量。每个维度都有具体的审查问题，比如实度维度会问"是否做到了七分实二三分文"，深度维度会问"是在编大筐还是在挖深井"。

### 调研报告

按"真实深高新活"六字标准审查。根据调研报告的五种常用类型分别指导：情况类要写实写准，问题类要以问题为主线，经验类要防止搞成"十全大补丸"，研究类要做到"新深专"，历史类要还原本来面目。

### 述职报告

以"三个取胜法"为审查框架：以实取胜、以数取胜、以事和绩取胜。其中"以数取胜"方法论特别详细，区分了工作量化、成效量化、职务行为量化三个层次，以及粗数据与细数据的不同使用场景。

### 汇报稿和发言稿

拆分为四个子类型分别指导。汇报稿突出"先决性"特征，学习会发言稿要做到"三个结合得紧密"，座谈会发言稿要立足本部门职能说话，对照检查发言稿从真实诚信、准确具体、深刻实在、严谨清晰、朴实无华五个标准进行审查。

### 随笔和杂文

以"真情智善理美"六字诀和"三有五可"为标准。三有是有料有趣有度，缺一不可。五可是可追素雅、可舒情怀、可发感慨、可阐事理、可明志向。

### 自媒体写作

以"短快真实新"五字诀为总纲，配备精练标题、精彩开篇、淘金句三大方法论。标题遵循"吸引力法则"，开篇对激发阅读欲望带有决定性，金句是红花其他句子是绿叶。

---

## 五种思维方式多维审稿

这是技能的一个独特能力。传统审稿往往只从逻辑维度看问题，本技能在结构性审查阶段引入了原书提出的五种思维方式，从不同维度发现单一视角下看不到的问题：

| 思维方式 | 审什么 | 具体问题 |
|---------|--------|---------|
| 系统工程思维 | 整体性和连贯性 | 文稿作为系统是否完整有序？有无碎片化？ |
| 唯物辩证思维 | 多维度审视 | 是否只从一个角度论述？有无辩证分析？ |
| 形象想象思维 | 生动性和感染力 | 有无恰当比喻？抽象论题是否写得活？ |
| 创意创新思维 | 新意 | 是否在炒冷饭？有无跳出惯性思维？ |
| 逻辑思维 | 推理和判断 | 概念是否清晰？因果是否成立？ |

---

## 何其芳十二项修改清单

技能内置了基于何其芳修改文章经验的系统化审校清单。何其芳说"古今中外，凡是文章写得好的人，大概都在修改上用过功夫"。这十二项覆盖了写作中最常见的问题：

1. 抽象笼统，叙事不具体，说理不充分
2. 根据不足，就下断语
3. 强调一点不加限制，反驳走极端，没有分寸
4. 大家都知道的事情说太多
5. 别人不知道的事情说太少
6. 随便放在一起，没有中心，没有层次
7. 写到下句不管上句，写到后面不管前面
8. 信手写来，离题万里，偏又爱惜，舍不得割弃
9. 抄书太多，使人昏昏欲睡
10. 生造词汇，乱用术语，疙里疙瘩，词不达意
11. 没有吸取说话里面的好处，只剩下啰唆重复
12. 摹仿翻译文字造长句子，逗号到底

每一项都配有"典型表现"描述，帮助快速识别文稿中是否存在对应问题，以及具体的修法建议。

---

## 去除 AI 行文痕迹

技能在润色过程中会严格消除 AI 生成内容的九种典型特征，确保输出的文稿读起来像人写的，不像机器生成的。这些规则是在修订一篇五万字太空经济研究报告的实战中逐条验证和提炼出来的。

**禁止破折号行文。** 破折号是 AI 生成内容最明显的特征之一，技能会把所有破折号改为逗号或句号，重新组织句子。

**禁止括号内嵌大量信息。** 在句子中间用括号插入补充说明是另一种典型的 AI 行文方式。技能会把括号里的内容融入正文，用逗号衔接，写成完整通顺的句子。括号只用于极短的注释，比如标注缩写全称。

**坚持使用逗号。** 逗号是中文行文的基本衔接工具，遇到需要补充说明或转折的地方，优先用逗号连接，写成自然流畅的句子。

**禁止"如果说…那么…"句式。** 这是 AI 生成内容中最常见的比喻引入方式，应改为直接判断式表述。

**警惕 AI 过渡词。** "总的来看""必须承认""展望未来""值得注意的是"等过渡词是 AI 行文的高频特征，偶尔出现无妨，密集使用则需要改写，直接陈述观点，去掉铺垫。

**避免冒号标题滥用。** AI 生成的标题几乎都用"XX：YYYYYY"格式，如果全文所有小节标题都是这种格式，应将部分改为更自然的表述。

**控制引号使用频率。** AI 倾向于给每个概念性词汇加引号，引号应仅在首次引入特定概念或确需强调时使用，后续出现不再加引号。

**精简引用堆砌。** AI 生成的研究报告几乎每段都以"据XXX统计""据XXX发布的报告"开头，读来像数据汇编。关键数据保留来源标注，其余将来源移至句末或脚注。

**改善机械化列举。** "一是…二是…三是…"是 AI 行文的典型排列方式，密集出现时应将部分改为自然段落叙述。

---

## 多格式支持

### Markdown 和纯文本

直接读取分析，无需额外工具。用户也可以直接粘贴文本到对话中。

### DOCX 文件

技能支持完整的 DOCX 工作流：

- **读取分析**：通过 pandoc 自动转换为 Markdown 后分析
- **编辑回写**：使用 `docx-editor` Python 库，默认启用 Track Changes 修订模式
- **修订作者**：默认为"任仲然"，用户可通过"用 XX 的名义修改"等方式指定其他名称
- **公文排版**：从零创建公文时，自动遵循 GB/T 9704-2012《党政机关公文格式》国家标准

---

## 安装方式

本技能原生为 Claude Code 设计，同时也可在其他主流 AI 编程工具中使用。

### Claude Code

#### Marketplace 安装（推荐）

两步完成。第一步注册 marketplace，第二步安装插件：

```bash
# 第一步：注册 marketplace（只需执行一次）
claude plugin marketplace add https://github.com/sinnohzeng/zen-yang-xie-zuo.git

# 第二步：安装插件
claude plugin install writing-polish@zen-yang-xie-zuo
```

后续更新只需一条命令：

```bash
claude plugin update writing-polish@zen-yang-xie-zuo
```

#### 手动复制

将 `skills/writing-polish/` 文件夹复制到 `~/.claude/skills/` 目录：

```bash
git clone https://github.com/sinnohzeng/zen-yang-xie-zuo.git
cp -r zen-yang-xie-zuo/skills/writing-polish ~/.claude/skills/
```

这种方式不支持自动更新，需要手动拉取新版本后重新复制。

#### 符号链接（本地开发）

适合需要修改和调试技能的开发者：

```bash
git clone https://github.com/sinnohzeng/zen-yang-xie-zuo.git
ln -s $(pwd)/zen-yang-xie-zuo/skills/writing-polish ~/.claude/skills/writing-polish
```

对仓库的修改会立即生效，无需重新安装。

### TRAE（字节跳动）

TRAE 使用 `.trae/rules/` 目录存放项目级规则，格式为 Markdown。将技能核心文件复制为 TRAE 规则：

```bash
git clone https://github.com/sinnohzeng/zen-yang-xie-zuo.git
mkdir -p .trae/rules
cp zen-yang-xie-zuo/skills/writing-polish/SKILL.md .trae/rules/writing-polish.md
cp zen-yang-xie-zuo/skills/writing-polish/references/*.md .trae/rules/
```

也可以在 TRAE 设置界面中，打开 Rules 面板手动创建规则文件，将 SKILL.md 的内容粘贴进去。

### Cursor

Cursor 使用 `.cursor/rules/` 目录存放规则，格式为 `.mdc`（带 YAML 头部的 Markdown）。需要手动添加头部信息：

```bash
git clone https://github.com/sinnohzeng/zen-yang-xie-zuo.git
mkdir -p .cursor/rules
```

在 `.cursor/rules/` 中创建 `writing-polish.mdc` 文件，添加如下头部后粘贴 SKILL.md 的内容：

```yaml
---
description: 写作润色审稿，触发词：润色、审稿、改稿、帮我写、polish、review writing
alwaysApply: false
---
```

参考文件同理，每个文件加上头部后放入 `.cursor/rules/` 目录即可。

### Windsurf（Codeium）

Windsurf 使用 `.windsurf/rules/` 目录，格式为 Markdown：

```bash
git clone https://github.com/sinnohzeng/zen-yang-xie-zuo.git
mkdir -p .windsurf/rules
cp zen-yang-xie-zuo/skills/writing-polish/SKILL.md .windsurf/rules/writing-polish.md
cp zen-yang-xie-zuo/skills/writing-polish/references/*.md .windsurf/rules/
```

注意 Windsurf 对规则文件有总计 12,000 字符的限制，可能需要精简内容或只选用核心文件。

### Cline（VS Code 插件）

Cline 使用 `.clinerules/` 目录，格式为 Markdown：

```bash
git clone https://github.com/sinnohzeng/zen-yang-xie-zuo.git
mkdir -p .clinerules
cp zen-yang-xie-zuo/skills/writing-polish/SKILL.md .clinerules/writing-polish.md
cp zen-yang-xie-zuo/skills/writing-polish/references/*.md .clinerules/
```

### GitHub Copilot

Copilot 使用 `.github/copilot-instructions.md` 作为全局指令，或 `.github/instructions/` 目录存放多个指令文件：

```bash
git clone https://github.com/sinnohzeng/zen-yang-xie-zuo.git
mkdir -p .github/instructions
cp zen-yang-xie-zuo/skills/writing-polish/SKILL.md .github/instructions/writing-polish.instructions.md
```

Copilot 的指令文件支持 YAML 头部指定作用范围，可按需添加：

```yaml
---
applyTo:
  - "**/*.md"
  - "**/*.txt"
  - "**/*.docx"
---
```

### Augment Code

Augment 使用 `.augment/rules/` 目录或项目根目录的 `.augment-guidelines` 文件：

```bash
git clone https://github.com/sinnohzeng/zen-yang-xie-zuo.git
mkdir -p .augment/rules
cp zen-yang-xie-zuo/skills/writing-polish/SKILL.md .augment/rules/writing-polish.md
cp zen-yang-xie-zuo/skills/writing-polish/references/*.md .augment/rules/
```

### 各工具规则系统对照

| 工具 | 规则目录 | 文件格式 | 字符限制 |
|------|---------|---------|---------|
| Claude Code | `~/.claude/skills/` 或 Plugin | Markdown | 无硬性限制 |
| TRAE | `.trae/rules/` | Markdown | 未公开 |
| Cursor | `.cursor/rules/` | `.mdc`（Markdown + YAML 头部） | 未公开 |
| Windsurf | `.windsurf/rules/` | Markdown | 12,000 字符 |
| Cline | `.clinerules/` | Markdown | 未公开 |
| Copilot | `.github/instructions/` | Markdown + YAML 头部 | 代码审查场景 4,000 字符 |
| Augment | `.augment/rules/` | Markdown | 约 49,000 字符 |

### 前置依赖（可选）

DOCX 读取：

```bash
brew install pandoc    # macOS
apt install pandoc     # Ubuntu/Debian
```

DOCX 编辑回写，仅在需要修改 DOCX 文件并回写时安装：

```bash
pip install docx-editor python-docx
```

---

## 使用方法

安装后，在 Claude Code 对话中使用以下任意方式触发。

### 写作辅助

```
帮我写一篇关于安全生产的讲话稿
帮我搭一个调研报告的提纲
帮我起草一份工作通知
help me write an outline for a research report
draft a speech about team building
```

### 审稿润色

```
帮我润色这篇文章
请审一下这个稿子
帮我改改这篇讲话稿
优化一下这篇调研报告
polish this article for me
review my writing
```

### 指定文件

```
帮我润色 /path/to/article.md
审稿 /path/to/speech.docx
用修订模式帮我改 /path/to/document.docx
```

### 指定修改深度

```
轻度润色一下语言就好         → 侧重语言和表达
帮我全面审查这篇文稿         → 结构到细节全面审查
这篇写得不太好，帮我重新组织  → 可能涉及结构重建
```

---

## 技能架构

```
writing-polish/
├── SKILL.md                           # 核心工作流：写作辅助 + 审稿润色 + 快速参考表 + 修改哲学
└── references/
    ├── writing-methodology.md         # 写作方法论：五种思维方式 + 立意 + 构思 + 提纲 + 材料 + 语言
    ├── genre-guide.md                 # 七种文体专属审查标准，每种都有操作化审查问题
    ├── revision-checklist.md          # 何其芳十二项清单 + 三项系统梳理 + 换位修改法
    ├── logic-and-structure.md         # 逻辑审查 + 结构审查：渔网隐喻 + 鸟巢隐喻的操作化转化
    ├── docx-editing-guide.md          # DOCX 编辑完整指南：docx-editor 用法 + 验证流程
    └── gongwen-format.md             # 党政公文排版规范（GB/T 9704）+ 日期时间和数字使用规范
```

技能采用渐进式加载架构，节省 AI 上下文窗口：

- **第一层**：技能名称和触发描述，始终在上下文中
- **第二层**：SKILL.md 核心工作流（347 行），技能触发时加载
- **第三层**：六个参考文件（共 1503 行），按需加载。比如只有识别出特定文体时才加载 genre-guide.md，只有需要编辑 DOCX 时才加载 docx-editing-guide.md

---

## 方法论来源

本技能的全部方法论提炼自：

**《怎样写作》**，任仲然 著，党建读物出版社，2019 年

任仲然长期在党政机关工作，既有从事具体工作的实践，又有担任高级领导职务的经历。善于总结提炼，对写作问题有深刻的思考和见解。本书从"写作其实并不难"入手，系统讲述了写作的思维逻辑、立意构思、材料结构、语言表达，以及七种常用文体的具体写法，并以修改文稿文章的经验收尾。

本技能从全书十二讲中系统提取了：

- **5 种思维方式**的写作和审稿应用方法
- **完整的写作辅助工作流**，从立意到成稿的五步法
- **系统化的审稿工作流**，从大处着眼到小处着手的四步法
- **7 种文体专属标准**，每种都有操作化的审查问题
- **12 项修改清单**，每项配有典型表现描述
- **12 类常见问题速查表**，快速定位和解决问题

---

## 许可

本技能为开源项目，方法论版权归原著作者任仲然所有。技能代码遵循 MIT 许可证。

---

## 致谢

感谢任仲然先生数十年写作经验的无私分享，使得这些宝贵的写作方法论能够以 AI 技能的形式服务更多写作者。

> "写作不是文字的简单排列组合，而是思想的创造和精神的奉献。"
