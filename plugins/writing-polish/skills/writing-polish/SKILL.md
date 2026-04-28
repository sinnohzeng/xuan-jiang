---
name: writing-polish
description: |
  Assists writing, reviewing, polishing, and revising Chinese documents based on 《怎样写作》(任仲然). Make sure to invoke this skill whenever the user mentions writing, polishing, reviewing, drafting, revising, proofreading, or improving Chinese documents — even with indirect cues like 帮我看看, 改一改, 审一审, 起个稿, 拟个文, 搭提纲, 起草. Triggers: 润色, 审稿, 改稿, 帮我写, 帮我起草, 搭个提纲, 起草, 拟稿, 审一审, 改一改, polish this, review my writing, help me write, draft this, write an outline, proofread, DOCX 修订, 修改 Word 文档, 用修订模式润色. Genres: 公文, 讲话稿, 调研报告, 述职报告, 汇报发言稿, 随笔杂文, 自媒体. Three modes: writing assistance, light polish, deep structural revision. Strictly enforces 110+ anti-AI-taste rules — bans em-dashes, parenthetical asides, 接住/共情/看见你, 赋能/重塑/闭环 jargon, "不是X而是Y" patterns, and runs scripts/scan-ai-taste.sh as delivery gate. Does NOT trigger for translation, code review, data analysis, or English-only writing.
effort: max
paths: "**/*.docx, **/*.md, **/*.txt"
---

# 写作润色审稿 v4.0

基于《怎样写作》（任仲然）方法论 + 110 条硬核 AI 味约束的中文写作 skill。

> "好文稿好文章无疑是写出来的，但更重要的是改出来的。"
> "热写稿，冷改稿。"

## 1. 触发判断（Decision Tree）

收到用户请求后，按此顺序判断：

1. **是写作辅助还是审稿润色？**
   - 用户说"帮我写""帮我起草""搭个提纲""起草""拟稿" → 写作辅助工作流（§3.1）
   - 用户提供了现成文稿要修改 → 审稿润色工作流（§3.2）

2. **修改深度判断**：
   - "润色""polish""改改语言" → 轻度润色（侧重语言）
   - "帮我改""审稿""review" → 深度修改（全面审查）
   - "重写""重新组织" → 结构重建（可能大改）

3. **DOCX 还是普通文本？**
   - DOCX 文件 → §2 文件处理路由
   - Markdown / 纯文本 / 直接粘贴 → 直接处理

## 2. 文件处理路由

### 2.1 三种输入

- **Markdown / 纯文本**：直接 Read 工具读取
- **直接粘贴文本**：直接分析，无文件操作
- **DOCX 文件**：按下方决策树

### 2.2 DOCX 决策树

1. **读取理解内容**：`pandoc input.docx -t markdown --wrap=none`
   - 未装 pandoc 时提示：`brew install pandoc`（macOS）或 `apt install pandoc`（Linux）
   - 含修订标记读取：`pandoc --track-changes=all input.docx -t markdown --wrap=none`

2. **是否需要回写 DOCX？**
   - 是 → 阅读 `references/docx-editing-guide.md` 进入 DOCX 编辑工作流
   - 否 → 输出 Markdown / 纯文本即可

### 2.3 DOCX 编辑默认设定

- **默认启用 Track Changes（修订模式）**，除非用户明确要求直接修改
- **默认修订作者**：`"任仲然"`，用户可通过"用 XX 的名义修改"指定其他名称
- **编辑工具**：`docx-editor` Python 库（`pip install docx-editor python-docx`）
- **核心原则**：最小化修改标记、保留原始格式、Run 级别操作

## 3. 工作流大纲

### 3.1 写作辅助（5 步法）

详细方法论见 `references/writing-methodology.md`。范文锚点见 `assets/anchor-essays/`，**写作前必看 1-2 个对应文体的锚点摹仿**。

- [ ] **第 1 步：明确任务** — 阅读 `references/genre-guide.md` 对应文体，确认文体类型 + 写作目的 + 受众 + 用户希望深度（提纲 / 初稿 / 完整稿）
- [ ] **第 2 步：立意构思** — 锁定核心问题，选独有而新鲜角度；避免"全而又全"，一事一文聚焦重点；选小切口展大思路
- [ ] **第 3 步：搭建提纲** — 粗纲（框架 + 各级标题）→ 细纲（提炼基本判断和观点）；越上越要有高度，越下越要有实度
- [ ] **第 4 步：充实内容** — 事例典型不重复（"解剖三五十只麻雀不如换一只小白鼠"）；数据用到位增"实在感"；材料与观点协调统一
- [ ] **第 5 步：语言定调** — 朴实原则（少修饰、忌生僻词、不绕圈子）；整齐美与参差美交替；**完成后必跑 §4 三层防御**

### 3.2 审稿润色（3 步法 — 先大后小，先减后加）

完整修改清单见 `references/revision-checklist.md`（何其芳 12 项 + 三维系统审查）。

- [ ] **第 1 步：通读识别** — 完整读一遍**不动笔**；识别文体；判断修改深度（轻度 / 深度 / 结构重建）
- [ ] **第 2 步：结构性审查（大处着眼）** — 按优先级审：
  - 立意主题（一句话能否概括？是否跑题？是否"全而又全"？）
  - 内容观点（事实真实？判断有据？事例典型不雷同？数据用到位？）
  - 结构（四梁八柱稳否？比重均衡？层级适当？— 详见 `references/logic-and-structure.md`）
  - 逻辑（主线清晰？并列在同一水平线？递进由表及里？前后衔接？）
  - 五种思维方式审视（系统 / 辩证 / 形象想象 / 创意 / 逻辑）
- [ ] **第 3 步：细节打磨（小处着手）** — 语言（删 / 改 / 保留三策）、表达方式（叙述 / 议论 / 说明）、字斟句酌（标点 / 用词 / 术语 / 句长）、**§4 三层 AI 味防御**

### 3.3 修订模式 DOCX 交付 vs 大范围重写

| 场景 | 识别信号 | 修改策略 |
|---|---|---|
| **修订模式 DOCX 交付** | 客户已给批注版 docx 要求 track changes | **定点精修**：只改有明确问题的段落，避免每段都动 |
| **大范围重写** | 用户明确说"重写""深度改写""大幅调整" | 全面对齐 §4 锚本与指纹，可重构段落、调标题、增删 |
| **简要版新写** | 用户让起草新简要版或在原基础上压缩 | 按锚本直接写，不带 track changes |

**判定优先级**：(1) 目录下有客户批注版 docx → 修订模式；(2) 用户明确要求"重写" → 大范围重写；(3) 冲突时以用户当前指令为准。

**修订模式克制原则**：只改批注明确指向段落或事实性错误，不做文风层面全面改写（即使段落有 AI 味也克制处理）；每处改动前自问"客户能在 track changes 里一眼看懂吗？"

## 4. AI 味硬约束（三层防御，零容忍）

### 4.1 工作哲学

**真正的"去 AI 味"不是改词，是把表达从「标准答案」拉回「具体表达」**：
留犹豫、留偏执、留具体、留人称、长短句交错、该用数字时用数字、该点名时点名。

底层机制原理：见 `references/anti-ai-taste-anchors.md` §0。

### 4.2 三层防御

#### L1 写作前（Preventive）

启动写作或审稿任务前，必读：
1. `references/anti-ai-taste-anchors.md` §0 核心机制 + §1 红线 110 条
2. `references/ai-taste-examples.md` 10 段反例对照（让眼睛记住"什么是 AI 味"）
3. 对应文体的 1-2 个 `assets/anchor-essays/` 范文锚点 + `assets/real-world-anchors/` 真实文件锚本

### L2 写作中（In-line）

每段写完后必做心理 grep，任何一项命中立即重写本段：

- [ ] 没有破折号 — 或 ——
- [ ] 没有"xxx（如 …）"或"xxx（即 …）"括号内插入
- [ ] 没有"接住/共情/看见你"客服腔
- [ ] 没有"赋能/重塑/闭环/抓手/链路/打造"公文黑话
- [ ] 没有"在某种意义上说/不可磨灭的/在...的背景下"翻译腔
- [ ] 没有"首先…其次…最后"三段式套壳
- [ ] 没有"值得注意的是/综上所述/由此可见"套话连接词
- [ ] 没有"令人印象深刻/至关重要/充满活力"情感空话
- [ ] 没有"不是 X 而是 Y / 不仅...更是"否定平行
- [ ] 段尾没有"…，体现了 X / 反映了 Y / 彰显了 Z"分词挂总结

### L3 交付前（Gate）— 必须执行

```bash
bash scripts/scan-ai-taste.sh "$OUTPUT_FILE"
```

任何红线指标未达标，**禁止交付**，重写直至通过。

量化阈值（详见 `references/anti-ai-taste-anchors.md` §4）：
- 破折号 = 0、括号内补充 = 0、强对比句式 = 0
- 红线词集合命中 = 0
- 已经 ≤ 3、核心 ≤ 3、这一 ≤ 2
- 句长标准差 ≥ 8（人写有长短交错）

### 4.3 重要保留项（NOT AI 味，应主动使用）

- **"一是…二是…三是…"** 是党政公文标准列举法，不是 AI 痕迹（国办、财政部、DRC 真实文件大量使用）
  - 一级：中文数字"一、二、三"
  - 二级：`一是 / 二是` 或 `（一）/（二）`
  - 末段请示：`其一 / 其二 / 其三`
- **判断词软化**：业已、基本、总体、较为、相对（避免绝对化）
- **结构引入语**：按照…要求、围绕…、聚焦…、依托…、基于…、通过…
- **公文动词**：推动、推进、加快、加强、强化、完善、健全（在锚本中验证过的）

## 5. 输出格式

| 修改深度 | 输出 |
|---|---|
| **轻度润色** | 直接输出修改后全文，关键修改处加简要说明 |
| **深度修改** | 先输出审查报告，再输出修改后全文（见下方模板） |
| **DOCX 回写** | 阅读 `references/docx-editing-guide.md`，用 `docx-editor` 执行（默认 Track Changes）；同时输出 Markdown 审查报告方便对照 |

**深度修改报告模板**：
```
## 审查总评
- 文体：[识别的文体]
- 总体评价：[1-2 句话]
- 修改深度：[轻度润色 / 中度修改 / 深度重构]

## 结构性问题（大改）
1. [问题 + 位置 + 修改建议]

## 细节问题（小改）
1. [问题 + 位置 + 修改建议]

## AI 味自检结果
[scripts/scan-ai-taste.sh 输出]

## 修改后全文
[完整修改稿]
```

**交付前**：建议用户"念改"——边念边改，口耳并用，能发现默看时漏掉的问题。

## 6. 修改哲学

- **天下文章一大改** — 没有一稿成型的好文章。重要文稿三分写七分改
- **热写稿，冷改稿** — 写时趁热打铁，改时晾一晾冷一冷。像淬火
- **先大后小** — 先改立意主题和结构，再改段落语句，最后改字词标点
- **先减后加** — 精简、去冗、消肿。减法做完再做加法
- **求精求准** — 精：主题深邃、思想精确、文辞朴实；准：事实准确、判断精准、风险意识
- **尊重原作** — 可改可不改的不改。但该改的一定改到位
- **换位修改** — 从受众和批评者两个角度审视
- **改到位的标志** — "改得没什么可改的了，乃至发现个别改过的词句又改回来的时候"

## 7. 资源索引

### references/（按需载入文档）
| 文件 | 用途 | 何时读 |
|---|---|---|
| `writing-methodology.md` | 5 种思维 + 立意/构思/提纲/材料/语言 + 老石经验 | 写作辅助前 |
| `genre-guide.md` | 7 大文体专属审查标准 + 三吃透 + 三取胜模板 | 识别文体后 |
| `revision-checklist.md` | 何其芳 12 项 + 系统审查 + 定稿标准 | 深度审稿时 |
| `logic-and-structure.md` | 逻辑主线 + 结构模式审查 | 结构性审查时 |
| `docx-editing-guide.md` | DOCX Track Changes 编辑全指南 | DOCX 回写前 |
| `gongwen-format.md` | GB/T 9704 党政公文格式规范 | 公文格式化 |
| **`anti-ai-taste-anchors.md`** | **110 红线 + 60 橙线 + 15 结构反模式 + 量化阈值** | **任何写作 / 修改前必读** |
| **`ai-taste-examples.md`** | **10 段反例 + 改写对照** | **第一次用本 skill 时必读** |

### assets/（用于产出的素材）
| 目录 | 内容 | 何时用 |
|---|---|---|
| `anchor-essays/` | 《怎样写作》原书 8 个范文锚点 | 写作辅助时摹仿 |
| `real-world-anchors/` | 5 个真实文件锚本（国办 / DRC / 财政部 / 国家信息中心） | 公文 / 咨询报告对标 |
| `docx-templates/` | DOCX 修订模式模板 | DOCX 回写时复用 |

### scripts/（自动化工具）
| 文件 | 用途 |
|---|---|
| `scan-ai-taste.sh` | **L3 Gate：交付前必跑的 AI 味自动扫描** |
| `word-count-check.sh` | 句长方差 + 段落同质化检查 |

### evals/（测试用例）
- `evals.json`：3 条真实场景 test prompt，用于 regression test
- `README.md`：写作类主观输出 evals 说明
