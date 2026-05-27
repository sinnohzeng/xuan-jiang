---
name: writing-polish
description: |
  Assists writing, reviewing, polishing, and revising Chinese documents based on 《怎样写作》(任仲然). Invoke this skill whenever the user mentions writing, polishing, reviewing, drafting, revising, proofreading, or improving Chinese documents, including indirect cues like 帮我看看, 改一改, 审一审, 起个稿, 拟个文, 搭提纲, 起草. Triggers: 润色, 审稿, 改稿, 帮我写, 帮我起草, 搭个提纲, 起草, 拟稿, 审一审, 改一改, polish this, review my writing, help me write, draft this, write an outline, proofread, DOCX 修订, 修改 Word 文档, 用修订模式润色. Genres: 公文, 讲话稿, 调研报告, 述职报告, 汇报发言稿, 随笔杂文, 自媒体. Three modes: writing assistance, light polish, deep structural revision. Strictly enforces 230+ anti-AI-taste rules: bans em-dashes and ASCII straight quotes, requires GB/T 15834 curly quotes, blocks 接住 共情 看见你 客服腔, blocks 赋能 重塑 闭环 抓手 公文黑话, blocks 三层防御 跑通 翻车 戏剧化叙事, blocks 作为一个 AI 助手 元注释, and runs scripts/scan-ai-taste.sh as delivery gate. Does NOT trigger for translation, code review, data analysis, or English-only writing.
effort: max
paths: "**/*.docx, **/*.md, **/*.txt"
---

# 写作润色审稿 v5.1（三层 hybrid，模型解耦，多智能体实装）

基于《怎样写作》（任仲然）方法论 + 230 余条 AI 味约束 + 中注协多智能体审校 SOP 的中文写作 skill。**主对话即 orchestrator**，零外部 API 调用，模型升级自动跟随 Claude Code。

> "好文稿好文章无疑是写出来的，但更重要的是改出来的。""热写稿，冷改稿。"

## §1 触发判断 + 3 mode 路径

收到用户请求后，先识别**协助 vs 审稿** + **修改深度** + **文件类型**：

| 触发信号 | mode | 走哪几层 | 主要 reference |
|---|---|---|---|
| "帮我写 / 起草 / 搭提纲 / 拟稿" | 协助写作 | L1 only（写完时跑 scan）| [`references/writing-methodology.md`](references/writing-methodology.md) + [`assets/anchor-essays/`](assets/anchor-essays/) |
| "润色 / 改改语言 / polish" | 轻润色 | L1 + L2 | [`references/constitution.md`](references/constitution.md) + [`references/revision-checklist.md`](references/revision-checklist.md) |
| "审稿 / 改稿 / review" | 中度修改 | L1 + L2 + Self-Refine ≤ 3 轮 | constitution.md + revision-checklist.md |
| "重写 / 深度改 / 多智能体 review / R1+R2" | 深度审稿 | L1 + L2 + **L3 多智能体** | + [`prompts/multi-agent/orchestration-guide.md`](prompts/multi-agent/orchestration-guide.md) |
| L3 自动触发条件 | — | 文档 ≥ 3000 字 / G1 G2 G3 G4 G8 文体 / L2 连退 2 次 | 见 orchestration-guide.md §1 |

**DOCX 文件**默认启用 Track Changes，作者默认"任仲然"，详 [`references/docx-editing-guide.md`](references/docx-editing-guide.md)。

## §2 三层架构（L1 / L2 / L3）

| 层 | 角色 | 执行者 | 何时跑 |
|---|---|---|---|
| **L1 硬 Gate** | 30 条 codepoint 级机械红线（标点 / em-dash / 文号 / AI 元注释字面） | `scripts/scan-hard-gate.sh`（CI 强制最小集）+ `scripts/scan-ai-taste.sh`（交付前完整版） | 任何输出交付前必跑 |
| **L2 LLM Judge** | D1-D5 五维 pointwise 评分 + Self-Refine ≤ 3 轮 | **主对话**读 [`references/constitution.md`](references/constitution.md) + [`prompts/llm-judge-research-report.md`](prompts/llm-judge-research-report.md) | L1 PASS 后默认跑 |
| **L3 多智能体审校** | 1 主 Opus orchestrator + 3-5 路 Sonnet R1 并行 + 1 路 Opus R2 fresh-eye / Pre-mod | **主对话** spawn clean-context Agent，参 [`prompts/multi-agent/orchestration-guide.md`](prompts/multi-agent/orchestration-guide.md) | 深度审稿 / 3000+ 字 / 高 stakes 文体 |

**模型解耦原则**：本 SKILL 不调外部 API，主对话即 judge / orchestrator。`scripts/llm-judge-runner.py` / `model_adapter.py` / `self-refine-loop.py` 是 dev-only 跨模型 calibration 工具，生产路径不依赖。模型路由真值源：[`config/default.yaml`](config/default.yaml)。

## §3 红线 4 铁律速查（写完每段自查）

1. **中文标点**：双引号必须 `""` 弯引号（U+201C/D），ASCII `"` `'` 在中文上下文违规（除代码块 / URL / 英文术语）；半角括号 `()` 紧跟英文术语 → 全角 `（）`；em-dash `—` / `——` 禁用；详 anti-ai-taste-anchors.md §1.4
2. **大厂黑话禁用**：赋能 / 重塑 / 闭环 / 抓手 / 链路 / 颗粒度 / 拉通 / 跑通 / 复盘 / 对齐颗粒度 / 三件套 → 改为党政中性表达；同词跨文体条件判决详 constitution.md §6.2
3. **散文 AI 体禁用**：「不仅 X 更是 Y」否定平行 / 「综上所述 / 由此可见」僵化收尾 / 「充分 / 深入 / 全面 / 大幅」单段 ≥ 2 处模糊副词堆砌（G3/G8 必扣 D5）；详 constitution.md §6.1
4. **AI 元注释禁用**：作为一个 AI 助手 / 让我为您整理 / 希望对您有帮助 / 以上仅供参考 → 删除全部

完整规则见 [`references/anti-ai-taste-anchors.md`](references/anti-ai-taste-anchors.md)（230+ 条字面 anchor SSOT）。

## §4 资源路由表

| 资源 | 何时读 / 用 |
|---|---|
| [`references/writing-methodology.md`](references/writing-methodology.md) | 协助写作 5 步法（明确任务 / 立意构思 / 搭提纲 / 充实内容 / 语言定调） |
| [`references/genre-guide.md`](references/genre-guide.md) | 识别文体后按 G1-G8 加载专属审查标准 |
| [`references/revision-checklist.md`](references/revision-checklist.md) | 审稿 3 步法（通读识别 / 结构性审查 / 细节打磨）+ 何其芳 12 项 |
| [`references/logic-and-structure.md`](references/logic-and-structure.md) | 逻辑主线 / 结构模式审查 |
| [`references/anti-ai-taste-anchors.md`](references/anti-ai-taste-anchors.md) | **任何写作或修改前必读**：字面 anchor SSOT |
| [`references/constitution.md`](references/constitution.md) | **Layer 2 跑前必读**：5 维 rubric × 8 文体切片 + Example A-N 14 个 + §6 模糊副词雷达 |
| [`references/ai-taste-examples.md`](references/ai-taste-examples.md) | 反例对照（首次使用此 SKILL 时通读一次） |
| [`references/failure-cases.md`](references/failure-cases.md) | scan 多轮失败时查同类历史案例 |
| [`references/citation-spec.md`](references/citation-spec.md) | 引用 / 归因写作时 |
| [`references/docx-editing-guide.md`](references/docx-editing-guide.md) | DOCX 回写前 |
| [`references/gongwen-format.md`](references/gongwen-format.md) | 公文格式化（GB/T 9704） |
| [`references/layer3-walkthrough.md`](references/layer3-walkthrough.md) | Layer 3 多智能体审校完整 worked example |
| [`prompts/llm-judge-research-report.md`](prompts/llm-judge-research-report.md) | L2 评分时主对话读 |
| **[`prompts/multi-agent/orchestration-guide.md`](prompts/multi-agent/orchestration-guide.md)** | **L3 触发时主对话读：自主判断派几个 reviewer + 派哪几维 + Agent 工具 spawn 语法** |
| [`assets/anchor-essays/`](assets/anchor-essays/) | 写作协助时摹仿（《怎样写作》8 篇范例） |
| [`assets/real-world-anchors/`](assets/real-world-anchors/) | 公文 / 咨询参照（11 篇真实文件） |
| [`scripts/scan-hard-gate.sh`](scripts/scan-hard-gate.sh) | CI 强制 30 条最小集（毫秒级） |
| [`scripts/scan-ai-taste.sh`](scripts/scan-ai-taste.sh) | 交付前完整版扫描（230+ 条，秒级） |
| [`scripts/docx-review-workflow.py`](scripts/docx-review-workflow.py) | DOCX 修订模式一键化 |
| [`scripts/llm-judge-runner.py`](scripts/llm-judge-runner.py) | **dev-only**：跨模型 calibration，生产路径不调 |
| [`scripts/self-refine-loop.py`](scripts/self-refine-loop.py) | **dev-only**：脚本化 self-refine 跨模型对比 |
| [`scripts/model_adapter.py`](scripts/model_adapter.py) | **dev-only**：OpenAI-compatible BYOM 适配器 |
| [`evals/calibration-set.jsonl`](evals/calibration-set.jsonl) | 173 段 cicpa auto-baseline（v5.0-rc1 Sprint 1） |
| [`evals/layer3-convergence.jsonl`](evals/layer3-convergence.jsonl) | L3 每次 run append 5 字段 JSON，累积分析 L3 价值 |

## §5 修改哲学（一句话）

天下文章一大改：先大后小（立意 → 结构 → 段落 → 字词标点）+ 先减后加 + 求精求准 + 尊重原作（可改可不改的不改）+ 换位修改（受众视角 + 批评者视角）。完整哲学详 [`references/revision-checklist.md`](references/revision-checklist.md) 末段。

## §6 输出格式

| 修改深度 | 输出 |
|---|---|
| **协助写作 / 轻润色** | 直接输出修改后全文，关键修改处加 1-2 行说明 |
| **中度修改 / 深度审稿** | 审查报告（含文体识别 + 五维评分 + 关键修改清单）+ 修改后全文 |
| **L3 多智能体** | 同上 + Layer 3 finding 采纳清单（按 P0-P5）+ 收敛轮数 + jsonl 记录确认 |
| **DOCX 回写** | 调 `scripts/docx-review-workflow.py` 一键化（默认 Track Changes 作者 "任仲然"） |

**交付前**：建议用户"念改"——边念边改，口耳并用，能发现默看时漏掉的问题。
