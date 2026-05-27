---
name: writing-polish
description: |
  Assists writing, reviewing, polishing, and revising Chinese documents based on 《怎样写作》(任仲然). Invoke this skill whenever the user mentions writing, polishing, reviewing, drafting, revising, proofreading, or improving Chinese documents, including indirect cues like 帮我看看, 改一改, 审一审, 起个稿, 拟个文, 搭提纲, 起草. Triggers: 润色, 审稿, 改稿, 帮我写, 帮我起草, 搭个提纲, 起草, 拟稿, 审一审, 改一改, polish this, review my writing, help me write, draft this, write an outline, proofread, DOCX 修订, 修改 Word 文档, 用修订模式润色. Genres: 公文, 讲话稿, 调研报告, 述职报告, 汇报发言稿, 随笔杂文, 自媒体. Three modes: writing assistance, light polish, deep structural revision. Strictly enforces 230+ anti-AI-taste rules: bans em-dashes and ASCII straight quotes, requires GB/T 15834 curly quotes, blocks 接住 共情 看见你 客服腔, blocks 赋能 重塑 闭环 抓手 公文黑话, blocks 三层防御 跑通 翻车 戏剧化叙事, blocks 作为一个 AI 助手 元注释, and runs scripts/scan-ai-taste.sh as delivery gate. Does NOT trigger for translation, code review, data analysis, or English-only writing.
effort: max
paths: "**/*.docx, **/*.md, **/*.txt"
---

# 写作润色审稿 v5.0（三层 hybrid，模型解耦）

基于《怎样写作》（任仲然）方法论 + 230 余条 AI 味约束 + 中注协多智能体审校 SOP 的中文写作 skill。v5.0 范式：**Layer 1 硬 Gate（脚本零模型） → Layer 2 LLM Judge（主对话） → Layer 3 多智能体审校（subagent）**。零外部 API 调用 —— judge / reviewer / rewriter 三角色都由 Claude Code 当前主对话模型扮演（对标 Anthropic 官方 `doc-coauthoring` SKILL 范式：纯 markdown instructions，0 行 API 调用代码）。

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
| 用 v5 LLM Judge 评分 | §4.4 + `references/constitution.md` + `prompts/llm-judge-research-report.md` |
| 派多智能体审校 | §4.5 + `prompts/multi-agent/{r1,r2,pre-mod,orchestrator}.md` |

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

**修订模式克制原则**：只改批注明确指向段落或事实性错误，不做文风层面全面改写，即使段落有 AI 味也克制处理；每处改动前自问“客户能在 track changes 里一眼看懂吗”。

## 4. AI 味自检（三层 hybrid，零容忍）

### 4.1 工作哲学

**真正的“去 AI 味”不是改词，是把表达从“标准答案”拉回“具体表达”**：
留犹豫、留偏执、留具体、留人称、长短句交错、该用数字时用数字、该点名时点名。

底层机制原理：见 `references/anti-ai-taste-anchors.md` §0。

### 4.2 三层架构总览

| Layer | 角色 | 谁执行 | 何时跑 | 模型依赖 |
|---|---|---|---|---|
| **L1 / 硬 Gate** | 30 条 codepoint 级机械红线（标点 / em-dash / 文号 / 元注释字面量） | `scripts/scan-ai-taste.sh` | 交付前必跑 | 零 |
| **L2 / LLM Judge** | 5 维 rubric pointwise 评分（D1 标点 / D2 套话 / D3 戏剧化 / D4 党政失配 / D5 模板感）+ Self-Refine ≤ 3 轮 | **主对话**读 `references/constitution.md` + `prompts/llm-judge-research-report.md` | L1 PASS 后默认跑 | Claude Code 当前主对话模型 |
| **L3 / 多智能体审校** | R1 并行评议（3-5 视角不重叠） + R2 fresh-eye 反查 + Pre-modification 动笔前审议 | **spawn clean-context subagent**（Agent 工具）| 高 stakes 触发（见 §4.5） | Claude Code 当前主对话模型 |

**模型解耦原则**：本 skill 不指定 judge / reviewer 模型，也不调外部 API。Claude Code 当前会话模型即 judge 模型，模型升级自动跟随。`evals/` 目录下的 `llm-judge-runner.py` / `model_adapter.py` / `self-refine-loop.py` 是 dev-only 跨模型 calibration 工具，生产路径不依赖。

### 4.3 Layer 1 / 硬 Gate（脚本，零模型）

#### 4.3.1 写作前 (Preventive)

启动写作或审稿任务前，必读：
1. `references/anti-ai-taste-anchors.md` 的 §0 核心机制和 §1 红线 124 条 + §1.5 戏剧化分类 + §1.6 客服话术 + §1.7 Wikipedia 长尾盲区
2. `references/ai-taste-examples.md` 的反例对照（让眼睛记住什么是 AI 味）
3. 对应文体在 `assets/anchor-essays/` 中的 1 至 2 个原书范例，以及 `assets/real-world-anchors/` 中的真实文件参考

#### 4.3.2 写作中 (In-line)

每段写完后做心理 grep，命中即重写。完整禁用词清单见 `references/anti-ai-taste-anchors.md` §1，本 SKILL 不展开列举（避免红线词污染 scanner 扫描结果）。

#### 4.3.3 交付前 Gate (必须执行)

```bash
bash scripts/scan-ai-taste.sh "$OUTPUT_FILE"
```

任何红线指标未达标，**禁止交付**，重写直至通过。

量化阈值（详见 `references/anti-ai-taste-anchors.md` §4）：
- 破折号 = 0、括号内补充 = 0、强对比句式 = 0
- 红线词集合命中 = 0
- 已经 ≤ 3、核心 ≤ 3、这一 ≤ 2
- 句长标准差 ≥ 8

### 4.4 Layer 2 / LLM Judge（主对话执行，模型解耦）

**执行者**：Claude Code 当前主对话模型。**不**调外部 API、**不**读 `~/.config/xuan-jiang/config.yaml`、**不**需要任何 BYOM 环境变量。

**触发**：L1 PASS 后默认跑（除非用户显式说"跳过 LLM judge"）。

**输入**（主对话顺序读取，全程无脚本调用）：
1. 待审文档全文（主对话已在上下文）
2. `references/constitution.md`（5 维 rubric 成文宪法 SSOT，按 8 文体切片）
3. `prompts/llm-judge-research-report.md`（咨询报告 judge prompt；其他文种走 `references/genre-guide.md` 选对应 sub-rubric）

**执行步骤**（主对话顺序）：
1. **文种识别** → 按 `references/genre-guide.md` 加载对应 sub-rubric
2. **5 维 pointwise 评分**（0-3 分 + `unknown` 逃生舱）：
   - D1 标点合规（GB/T 15834）
   - D2 AI 套话密度
   - D3 戏剧化 / 隐喻 / 大厂黑话
   - D4 党政语境失配
   - D5 模板感 / 结构同质化
3. **Self-Refine 闭环**：任一维 ≥ 2 → 主对话改稿 → 重新 5 维评分 → 分数单调升才继续，最多 3 轮（4 轮以上 churn，Self-Refine arxiv 2303.17651 实证上限）
4. **输出 judge report**：5 维分 + 关键违反引文 + 修订建议

**为什么主对话当 judge 而不调脚本 API**：
- Anthropic 官方 `doc-coauthoring` SKILL 范式：纯 markdown instructions，0 行 API 调用
- 模型自动跟随 Claude Code 升级（Sonnet 4.6 → 4.7 → 5 不需要 BYOM 切换）
- 单一上下文窗口下 judge / rewriter 同一个模型，self-refine 闭环最自然
- 零 API key、零 model_adapter setdefault bug 风险

### 4.5 Layer 3 / 多智能体审校（spawn clean-context subagent）

**触发条件**（任一即触发，主对话自行判断）：
- 用户显式 opt-in（"派几个 agent 审一遍 / 多智能体 review / 用 v5 完整跑一遍 / R1+R2"）
- 文档 ≥ 3000 字
- 文种 ∈ {咨询报告 G3 / 公文 G1 / 述职 G4 / 大会讲话 G2}
- 用户已对 Layer 2 输出连退 2 次（暗示 L2 看不出问题）

**执行范式**（用 Claude Code `Agent` 工具 spawn clean-context subagent，**不**调脚本）：

1. **Pre-modification（动笔前方案审议）**
   - 主对话写改稿草案 + 改动 rationale
   - `Agent(subagent_type="general-purpose", prompt=<prompts/multi-agent/pre-mod.md 套用 placeholder>)`
   - subagent 审议方案 → 主对话决策是否动手

2. **R1（3-5 视角并行评议）**
   - 同一条消息内 spawn 多个 `Agent` 并行调用（不重叠维度：fact / style / consulting / IA / a11y）
   - 每个用 `prompts/multi-agent/r1.md` 模板，仅替换视角 placeholder
   - subagent clean context 反推 spec（Cognition 2026-04 范式，Devin 实测 +2 bugs/PR 58% severe）

3. **R2（fresh-eye 反查）**
   - spawn 1 个 fresh subagent **不传 R1 trajectory**
   - 用 `prompts/multi-agent/r2.md` 模板反查"R1 之后还能发现什么"

4. **主对话 orchestrator-synthesis**
   - 读 `prompts/multi-agent/orchestrator.md` 按 P0-P5 优先级整合：重大事实 → 客户敏感 → 严重 AI 腔 → 中度 → 文风 → 美学
   - **Edit 串行**（不并行写文件）+ **行号倒序**（避免行号偏移）
   - **收敛判停**：连续 2 轮 < 20% 采纳率 OR severe = 0 → 退出

**主对话应用每条 finding 前必跑（决策三问机械化 checklist）**：
- [ ] 这条 finding 违反了 SSOT 吗？（违反才采纳）
- [ ] 这条 finding 颗粒度有增益吗？（同义改写不采纳）
- [ ] R1 多个 finding 重复加严同一处吗？（取最严不取并集）

### 4.6 重要保留项（NOT AI 味，应主动使用）

- **“一是…二是…三是…”** 是党政公文标准列举法，不是 AI 痕迹，国办、财政部、DRC 真实文件大量使用
  - 一级：中文数字“一、二、三”
  - 二级：`一是 / 二是` 或 `（一）/（二）`
  - 末段请示：`其一 / 其二 / 其三`
- **判断词软化**：业已、基本、总体、较为、相对，避免绝对化
- **结构引入语**：按照…要求、围绕…、聚焦…、依托…、基于…、通过…
- **公文动词**：推动、推进、加快、加强、强化、完善、健全（在范例中验证过的）

### 4.7 失败重写指引（L1/L2 FAIL 时）

<!-- scan-skip -->
1. **定位**：看 scan 输出（L1）或 judge report（L2）指向的违规位置，从上到下处理。同一行多类违规时优先改 §1.4 标点（最容易改）和 §1.5.1 戏剧化（替换词清单见 anchors §1.5.1）。
2. **选范例**：从 `assets/anchor-essays/` 或 `assets/real-world-anchors/` 选一个同文体段落，看真实公文怎么表达同一意思。
3. **重写**：不要做“机械替换为同义词”。例：把“打通业务闭环”改成“打通业务回路”仍是黑话；正确做法是改成“完成业务流程的各个环节”，回到事实陈述。
4. **再扫**：重写后再跑 L1 scan + L2 主对话 judge，直至 L1 退出码 0 + L2 五维全部 ≤ 1。多轮失败查 `references/failure-cases.md` 同类历史案例与 `TROUBLESHOOTING.md`。
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
| **`constitution.md`** | **v5 LLM Judge 成文宪法，5 维 rubric 按 8 文体切片** | **Layer 2 跑前必读** |
| `failure-cases.md` | scan 失败案例库与重写过程 | scan 多轮失败时 |
| `citation-spec.md` | 模糊归因的具体改写模板 | 引用 / 归因写作时 |

### assets（用于产出的素材）

| 目录 | 内容 | 何时用 |
|---|---|---|
| `anchor-essays/` | 《怎样写作》原书的 8 个范例 | 写作辅助时摹仿 |
| `real-world-anchors/` | 真实文件参考，来源含国办、国家信息中心、国务院发展研究中心、财政部 | 公文或咨询报告参照 |
| `docx-templates/` | DOCX 修订模式模板 | DOCX 回写时复用 |

### prompts（v5 LLM Judge / 多智能体审校的 instructions）

| 文件 | 用途 | 何时用 |
|---|---|---|
| `llm-judge-research-report.md` | Layer 2 咨询报告 5 维 rubric judge prompt | L2 跑咨询报告时主对话读 |
| `multi-agent/r1.md` | Layer 3 R1 并行评议模板（视角 placeholder） | R1 spawn subagent 时套用 |
| `multi-agent/r2.md` | Layer 3 R2 fresh-eye 反查模板 | R2 spawn fresh subagent 时套用 |
| `multi-agent/pre-mod.md` | Layer 3 Pre-modification 动笔前方案审议模板 | 重大改稿前审议方案 |
| `multi-agent/orchestrator.md` | Layer 3 主对话整合 finding 的 P0-P5 优先级 + 决策三问 | R1+R2 收完整合时主对话读 |
| `multi-agent/_task-spec-skeleton.md` | 评审任务书六要素骨架（角色 / 路径 / 维度 / 约束 / 输出格式 / 输出上限） | 自定义多智能体任务时套用 |

### scripts（自动化工具）

| 文件 | 用途 |
|---|---|
| `scan-ai-taste.sh` | **Layer 1 Gate：交付前必跑的 AI 味自动扫描** |
| `scan-hard-gate.sh` | Layer 1 codepoint 级硬规则（标点 / em-dash / 文号 / 元注释字面量 30 条） |
| `check-cn-quotes.py` | 标点 / 中英混排校验（弯引号、加号、直角引号、英文标点穿插） |
| `word-count-check.sh` | 句长方差与段落同质化检查 |
| `check-dependencies.sh` | pandoc / docx-editor 等依赖检查 |
| `auto-fix-loop.sh` | scan 失败时自动尝试 1 至 2 轮修复 |
| `docx-review-workflow.py` | DOCX 修订模式一键化（读 → scan → track changes → 输出） |
| `llm-judge-runner.py` | **dev-only**：跨模型 calibration 跑批，**生产路径不调** |
| `model_adapter.py` | **dev-only**：OpenAI-compatible BYOM 适配器，仅 calibration 期用 |
| `self-refine-loop.py` | **dev-only**：脚本化 self-refine 闭环，calibration 跨模型对比用 |

### evals（dev-only 测试用例 + calibration baseline）

- `evals.json`：20 条真实场景 test prompt，含反向用例与边界 case
- `calibration-set.jsonl`：173 段 cicpa auto-baseline（v5.0-rc1 Sprint 1）
- `calibration-results-baseline-v50rc1/`：v5.0 stable baseline κ 报告
- `cohen-kappa.py` + `calibration-runner.sh`：跨模型一致度回归
- `README.md`：写作类主观输出 evals 说明
- `test-runner.sh`：回归测试与 baseline 对比

> 注：v5.0 生产路径（L2 LLM Judge）由主对话直接读 `references/constitution.md` + `prompts/llm-judge-research-report.md` 执行，**不调** `scripts/llm-judge-runner.py`。后者仅用于 dev 期跨模型一致度 calibration。

### docs（项目级文档）
- `docs/research/cross-skill-benchmark.md`：跨工具对照记录与季度续抓办法
- `TROUBLESHOOTING.md`：常见问题指引
