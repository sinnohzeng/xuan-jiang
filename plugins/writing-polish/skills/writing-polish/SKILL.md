---
name: writing-polish
description: |
  Assists writing, reviewing, polishing, and revising Chinese documents based on 《怎样写作》(任仲然). Invoke this skill whenever the user mentions writing, polishing, reviewing, drafting, revising, proofreading, or improving Chinese documents, including indirect cues like 帮我看看, 改一改, 审一审, 起个稿, 拟个文, 搭提纲, 起草. Triggers: 润色, 审稿, 改稿, 帮我写, 帮我起草, 搭个提纲, 起草, 拟稿, 审一审, 改一改, polish this, review my writing, help me write, draft this, write an outline, proofread, DOCX 修订, 修改 Word 文档, 用修订模式润色. Genres: 公文, 讲话稿, 调研报告, 述职报告, 汇报发言稿, 随笔杂文, 自媒体. Three modes: writing assistance, light polish, deep structural revision. Strictly enforces 230+ anti-AI-taste rules: bans em-dashes and ASCII straight quotes, requires GB/T 15834 curly quotes, blocks 接住 共情 看见你 客服腔, blocks 赋能 重塑 闭环 抓手 公文黑话, blocks 三层防御 跑通 翻车 戏剧化叙事, blocks 作为一个 AI 助手 元注释, and runs scripts/scan-ai-taste.sh as delivery gate. Does NOT trigger for translation, code review, data analysis, or English-only writing.
effort: max
paths: "**/*.docx, **/*.md, **/*.txt"
---

# 写作润色审稿 v4.3

基于《怎样写作》（任仲然）方法论 + 230 余条 AI 味约束的中文写作 skill。v4.3 新增上下文感知白名单（防火墙 IT 语境 / 对标 党政语境自动豁免）、千句密度动态阈值、咨询报告专属约束（§1.8）、11 篇真实锚本与双轨 evals 体系。

> “好文稿好文章无疑是写出来的，但更重要的是改出来的。”
> “热写稿，冷改稿。”

## 0. 快速导航

| 我要做什么 | 读哪里 |
|---|---|
| 写稿 / 起草 / 搭提纲 | §3.1 五步法 + §4 AI 味检查 + `references/writing-methodology.md` + `assets/anchor-essays/` |
| 审稿 / 润色 / 改稿 | §3.2 三步法 + §4 AI 味检查 + `references/revision-checklist.md` |
| DOCX 修订模式 | §2 文件处理路由 + `references/docx-editing-guide.md` + `scripts/docx-review-workflow.py` |
| 学写作方法 | `references/writing-methodology.md` 和 `references/genre-guide.md` |
| 查 AI 味规则 | `references/anti-ai-taste-anchors.md`（必读 §0 核心机制） |
| 看反例对照 | `references/ai-taste-examples.md` |
| 查公文格式国标 | `references/gongwen-format.md` |
| scan 失败排错 | §4.4 失败重写指引 + `references/failure-cases.md` + `TROUBLESHOOTING.md` |
| 看跨工具对照 | `docs/research/cross-skill-benchmark.md` |
| 写民俗玄学 / 情绪价值长文 | §3.4 + `references/folklore-emotional-value-style.md` |

## 1. 触发判断（Decision Tree）

收到用户请求后，按此顺序判断：

1. **是写作辅助还是审稿润色？**
   - 用户说“帮我写”“帮我起草”“搭个提纲”“起草”“拟稿”，则进入写作辅助工作流（§3.1）
   - 用户提供了现成文稿要修改，则进入审稿润色工作流（§3.2）

2. **修改深度判断**：
   - “润色”“改改语言”或英文 polish，按轻度润色处理（侧重语言）
   - “帮我改”“审稿”或英文 review，按深度修改处理（全面审查）
   - “重写”“重新组织”，按结构重建处理（可能大改）

3. **DOCX 还是普通文本？**
   - DOCX 文件，转入 §2 文件处理路由
   - Markdown 或纯文本或直接粘贴，直接处理

## 2. 文件处理路由

### 2.1 三种输入

- **Markdown / 纯文本**：直接 Read 工具读取
- **直接粘贴文本**：直接分析，无文件操作
- **DOCX 文件**：按下方决策树

### 2.2 DOCX 决策树

1. **读取理解内容**：`pandoc input.docx -t markdown --wrap=none`
   - 未装 pandoc 时先跑 `bash scripts/check-dependencies.sh`，按提示装
   - 含修订标记读取：`pandoc --track-changes=all input.docx -t markdown --wrap=none`

2. **是否需要回写 DOCX？**
   - 需要回写，先阅读 `references/docx-editing-guide.md` 进入 DOCX 编辑工作流，或直接调用 `scripts/docx-review-workflow.py` 一键化
   - 不需要回写，直接输出 Markdown 或纯文本

### 2.3 DOCX 编辑默认设定

- **默认启用 Track Changes（修订模式）**，除非用户明确要求直接修改
- **默认修订作者**：`“任仲然”`，用户可通过“用 XX 的名义修改”指定其他名称
- **编辑工具**：`docx-editor` Python 库（`pip install docx-editor python-docx`）
- **核心原则**：最小化修改标记、保留原始格式、Run 级别操作

## 3. 工作流大纲

### 3.1 写作辅助（5 步法）

详细方法论见 `references/writing-methodology.md`。原书范例见 `assets/anchor-essays/`，**写作前必看 1 至 2 个对应文体的原书范例做摹仿**。

- [ ] **第 1 步：明确任务**。阅读 `references/genre-guide.md` 对应文体，确认四件事：文体类型、写作目的、受众，以及用户希望的深度（提纲、初稿或完整稿）
- [ ] **第 2 步：立意构思**。锁定核心问题，选独有而新鲜的角度；避免“全而又全”，一事一文聚焦重点；选小切口展大思路
- [ ] **第 3 步：搭建提纲**。先搭粗纲（框架与各级标题），再写细纲（提炼基本判断和观点）。越上越要有高度，越下越要有实度
- [ ] **第 4 步：充实内容**。事例典型不重复（“解剖三五十只麻雀不如换一只小白鼠”）；数据用到位增“实在感”；材料与观点协调统一
- [ ] **第 5 步：语言定调**。朴实原则，少修饰、忌生僻词、不绕圈子；整齐美与参差美交替。完成后必跑 §4 的三步检查

### 3.2 审稿润色（3 步法：先大后小，先减后加）

完整修改清单见 `references/revision-checklist.md`，含何其芳 12 项与三维系统审查。

- [ ] **第 1 步：通读识别**。完整读一遍，不动笔；识别文体；判断修改深度（轻度、深度或结构重建）
- [ ] **第 2 步：结构性审查（大处着眼）**。按优先级审：
  - 立意主题（一句话能否概括？是否跑题？是否“全而又全”？）
  - 内容观点（事实真实？判断有据？事例典型不雷同？数据用到位？）
  - 结构（四梁八柱稳否？比重均衡？层级适当？详见 `references/logic-and-structure.md`）
  - 逻辑（主线清晰？并列在同一水平线？递进由表及里？前后衔接？）
  - 五种思维方式审视：系统、辩证、形象想象、创意和逻辑
- [ ] **第 3 步：细节打磨（小处着手）**。语言用删、改、保留三策；区分叙述、议论、说明三种表达方式；字斟句酌注意标点、用词、术语和句长。最后跑 §4 的三步 AI 味检查

### 3.3 修订模式 DOCX 交付与大范围重写

| 场景 | 识别信号 | 修改策略 |
|---|---|---|
| **修订模式 DOCX 交付** | 客户已给批注版 docx 要求 track changes | **定点精修**：只改有明确问题的段落，避免每段都动 |
| **大范围重写** | 用户明确说“重写”“深度改写”“大幅调整” | 全面参照 §4 范例，可重构段落、调标题、增删 |
| **简要版新写** | 用户让起草新简要版或在原基础上压缩 | 按范例直写，不带 track changes |

**判定优先级**：(1) 目录下有客户批注版 docx，按修订模式；(2) 用户明确要求“重写”，按大范围重写；(3) 冲突时以用户当前指令为准。

### 3.4 民俗玄学 / 情绪价值类长文

用户明确要求“只聊玄学”“只聊情绪价值”“不聊医学 / 科学判断”时，按 `references/folklore-emotional-value-style.md` 执行：
- 整体讲述与个人具体分析分开；整体部分不要反复代入个人名字，最后单设“某某的单独分析”。
- 口吻克制温柔，少断言，多用“可以理解为”“更容易被说成”“民俗里常讲”；明确这是文化叙事和情绪价值，不作事实预测。
- 可锚定一位中国作家的气质来定调。痣相、身体民俗类长文优先用汪曾祺散文方向：清淡、家常、温和，只借气质，不摹仿具体句子。
- 飞书场景下的长篇调研或系统性文章，优先交付飞书云文档；聊天里只发链接、变更点和自检结果。
- 写完仍必须运行 `scripts/scan-ai-taste.sh`，通过后才能交付。

## 4. AI 味约束（三步检查，零容忍）

### 4.1 工作哲学

**真正的“去 AI 味”不是改词，是把表达从“标准答案”拉回“具体表达”**：
留犹豫、留偏执、留具体、留人称、长短句交错、该用数字时用数字、该点名时点名。

底层机制原理：见 `references/anti-ai-taste-anchors.md` §0。

### 4.2 三步检查

#### 第一步：写作前 (Preventive)

启动写作或审稿任务前，必读：
1. `references/anti-ai-taste-anchors.md` 的 §0 核心机制和 §1 红线 124 条 + §1.5 戏剧化分类 + §1.6 客服话术 + §1.7 Wikipedia 长尾盲区
2. `references/ai-taste-examples.md` 的反例对照（让眼睛记住什么是 AI 味）
3. 对应文体在 `assets/anchor-essays/` 中的 1 至 2 个原书范例，以及 `assets/real-world-anchors/` 中的真实文件参考

#### 第二步：写作中 (In-line)

每段写完后必做心理 grep，任何一项命中立即重写本段。下列 checklist 列举禁用词作教学示例，scan-ai-taste.sh 会跳过本段扫描。

<!-- scan-skip -->

- [ ] 没有破折号 — 或 ——
- [ ] 没有 xxx 括号内插入式补充
- [ ] 没有 接住 共情 看见你 客服腔
- [ ] 没有 赋能 重塑 闭环 抓手 链路 打造 公文黑话
- [ ] 没有 在某种意义上说 不可磨灭的 在...的背景下 翻译腔
- [ ] 没有 首先...其次...最后 三段式套壳
- [ ] 没有 值得注意的是 综上所述 由此可见 套话连接词
- [ ] 没有 令人印象深刻 至关重要 充满活力 情感空话
- [ ] 没有 不是 X 而是 Y 不仅...更是 否定平行
- [ ] 段尾没有 体现了 X 反映了 Y 彰显了 Z 分词挂总结
- [ ] 中文里没有 ASCII 直引号 和直角引号「」，要用大陆国标弯引号
- [ ] 没有数学符号加号 等号 箭头做并列连词
- [ ] 没有 三层防御 闸门 跑通 翻车 战斗化叙事（§1.5.1）
- [ ] 没有 抓手 闭环 对标 拉通 颗粒度 大厂黑话（§1.5.2）
- [ ] 没有 本仓库 锚点 硬约束 dogfooding 网络口语（§1.5.3）
- [ ] 没有 作为一个 AI 助手 元注释开头（§1.6）

<!-- /scan-skip -->

#### 第三步：交付前 (Gate)，必须执行

优先在当前项目根目录执行：

```bash
bash scripts/scan-ai-taste.sh "$OUTPUT_FILE"
```

如果当前项目没有本地 `scripts/scan-ai-taste.sh`，使用本 skill 自带脚本路径执行，不要停止在“脚本不存在”：

```bash
bash /home/claw/xuan-jiang/plugins/writing-polish/skills/writing-polish/scripts/scan-ai-taste.sh "$OUTPUT_FILE"
```

任何红线指标未达标，**禁止交付**，重写直至通过。

量化阈值（详见 `references/anti-ai-taste-anchors.md` §4）：
- 破折号 = 0、括号内补充 = 0、强对比句式 = 0
- 红线词集合命中 = 0
- 已经 ≤ 3、核心 ≤ 3、这一 ≤ 2
- 句长标准差 ≥ 8

### 4.3 重要保留项（NOT AI 味，应主动使用）

- **“一是…二是…三是…”** 是党政公文标准列举法，不是 AI 痕迹，国办、财政部、DRC 真实文件大量使用
  - 一级：中文数字“一、二、三”
  - 二级：`一是 / 二是` 或 `（一）/（二）`
  - 末段请示：`其一 / 其二 / 其三`
- **判断词软化**：业已、基本、总体、较为、相对，避免绝对化
- **结构引入语**：按照…要求、围绕…、聚焦…、依托…、基于…、通过…
- **公文动词**：推动、推进、加快、加强、强化、完善、健全（在范例中验证过的）

### 4.4 失败重写指引（scan FAIL 时怎么办）

第三步 scan 失败后，按下面三步循环重写：

<!-- scan-skip -->
1. **定位**：看 scan 输出指向的违规行号，从上到下处理。同一行多类违规时优先改 §1.4 标点（最容易改）和 §1.5.1 戏剧化（替换词清单见 anchors §1.5.1）。
2. **选范例**：从 `assets/anchor-essays/` 或 `assets/real-world-anchors/` 选一个同文体段落，看真实公文怎么表达同一意思。
3. **重写**：不要做“机械替换为同义词”。例：把“打通业务闭环”改成“打通业务回路”仍是黑话；正确做法是改成“完成业务流程的各个环节”，回到事实陈述。
4. **再扫**：重写后再跑 scan，直至退出码 0。多轮失败查 `references/failure-cases.md` 同类历史案例与 `TROUBLESHOOTING.md`，或调 `bash scripts/auto-fix-loop.sh “$FILE”` 让脚本尝试 1 至 2 轮自动修复。
<!-- /scan-skip -->

## 5. 输出格式

| 修改深度 | 输出 |
|---|---|
| **轻度润色** | 直接输出修改后全文，关键修改处加简要说明 |
| **深度修改** | 先输出审查报告，再输出修改后全文（见下方模板） |
| **DOCX 回写** | 阅读 `references/docx-editing-guide.md`，用 `docx-editor` 执行（默认 Track Changes）；同时输出 Markdown 审查报告方便对照。也可调 `scripts/docx-review-workflow.py` 一键化 |

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

**交付前**：建议用户“念改”，边念边改，口耳并用，能发现默看时漏掉的问题。

## 6. 修改哲学

- **天下文章一大改**：没有一稿成型的好文章。重要文稿三分写七分改
- **热写稿，冷改稿**：写时趁热打铁，改时晾一晾冷一冷。像淬火
- **先大后小**：先改立意主题和结构，再改段落语句，最后改字词标点
- **先减后加**：精简、去冗、消肿。减法做完再做加法
- **求精求准**：精：主题深邃、思想精确、文辞朴实；准：事实准确、判断精准、风险意识
- **尊重原作**：可改可不改的不改。但该改的一定改到位
- **换位修改**：从受众和批评者两个角度审视
- **改到位的标志**：“改得没什么可改的了，乃至发现个别改过的词句又改回来的时候”

## 7. 资源索引

### references（按需载入文档）

| 文件 | 用途 | 何时读 |
|---|---|---|
| `writing-methodology.md` | 五种思维、立意、构思、提纲、材料、语言以及老石经验 | 写作辅助前 |
| `genre-guide.md` | 七大文体专属审查标准，含三吃透清单和三取胜模板 | 识别文体后 |
| `revision-checklist.md` | 何其芳十二项、系统审查、定稿标准 | 深度审稿时 |
| `logic-and-structure.md` | 逻辑主线和结构模式审查 | 结构性审查时 |
| `docx-editing-guide.md` | DOCX Track Changes 编辑全指南 | DOCX 回写前 |
| `gongwen-format.md` | GB/T 9704 党政公文格式规范 | 公文格式化 |
| **`anti-ai-taste-anchors.md`** | **124 条红线、60 条橙线、17 条结构反模式以及量化阈值** | **任何写作或修改前必读** |
| **`ai-taste-examples.md`** | **反例对照（含按文体、按修改深度分维度）** | **首次使用此技能时必读** |
| `failure-cases.md` | scan 失败案例库与重写过程 | scan 多轮失败时 |
| `citation-spec.md` | 模糊归因的具体改写模板 | 引用 / 归因写作时 |
| `folklore-emotional-value-style.md` | 民俗玄学与情绪价值长文写法，含“整体讲述 / 个人分析”分离和汪曾祺式温和口吻 | 用户要求只聊玄学、民俗、情绪价值时 |

### assets（用于产出的素材）

| 目录 | 内容 | 何时用 |
|---|---|---|
| `anchor-essays/` | 《怎样写作》原书的 8 个范例 | 写作辅助时摹仿 |
| `real-world-anchors/` | 真实文件参考，来源含国办、国家信息中心、国务院发展研究中心、财政部 | 公文或咨询报告参照 |
| `docx-templates/` | DOCX 修订模式模板 | DOCX 回写时复用 |

### scripts（自动化工具）
| 文件 | 用途 |
|---|---|
| `scan-ai-taste.sh` | **L3 Gate：交付前必跑的 AI 味自动扫描** |
| `check-cn-quotes.py` | 标点 / 中英混排校验（弯引号、加号、直角引号、英文标点穿插） |
| `word-count-check.sh` | 句长方差与段落同质化检查 |
| `check-dependencies.sh` | pandoc / docx-editor 等依赖检查 |
| `auto-fix-loop.sh` | scan 失败时自动尝试 1 至 2 轮修复 |
| `docx-review-workflow.py` | DOCX 修订模式一键化（读 → scan → track changes → 输出） |

### evals（测试用例）
- `evals.json`：20 条真实场景 test prompt，含反向用例与边界 case
- `README.md`：写作类主观输出 evals 说明
- `test-runner.sh`：回归测试与 baseline 对比

### docs（项目级文档）
- `docs/research/cross-skill-benchmark.md`：跨工具对照记录与季度续抓办法
- `TROUBLESHOOTING.md`：常见问题指引
