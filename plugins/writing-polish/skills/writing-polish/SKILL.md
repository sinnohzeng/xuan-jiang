---
name: writing-polish
description: |
  Coaches, drafts, polishes, and audits Chinese documents based on 《怎样写作》(任仲然), using LLM supervision by the calling Claude Code session itself — zero external API calls. Three modes: coach (帮我写/起草/拟稿/搭提纲, multi-turn), polish (润色/审稿/改稿, default for ambiguous triggers like 帮我看看), audit (快速过/checkpoint, script-only). Three-layer architecture: L1 regex hard gate via scripts/scan-ai-taste.sh enforcing 230+ rules from anti-ai-taste-anchors.md; L2 main-session D1-D5 self-judge using mini-rubric in §3 (detail in references/constitution.md); L3 optional clean-context multi-reviewer spawned by main-session Agent() when draft > 2000 chars or genre ∈ {规范公文/调研报告/述职报告/咨询报告} or L2 any-dim < 3, template in prompts/reviewer.md. Strictly enforces: GB/T 15834 curly quotes (bans ASCII straight quotes + em-dashes), 公文黑词清单 (赋能/重塑/闭环/抓手), 元注释黑名单 (作为一个 AI 助手), 戏剧化叙事黑名单 (三层防御/跑通/翻车). Genres: 公文/讲话稿/调研报告/述职报告/汇报发言稿/随笔杂文/自媒体/咨询报告. Triggers: 润色, 审稿, 改稿, 帮我写, 帮我起草, 搭个提纲, 起草, 拟稿, 审一审, 改一改, polish this, review my writing, help me write, draft this, write an outline, proofread, DOCX 修订, 修改 Word 文档. Does NOT trigger for: translation, code review, data analysis, English-only writing.
effort: max
paths: "**/*.docx, **/*.md, **/*.txt"
---

# writing-polish v6.0

任仲然《怎样写作》+ 230 余条 AI 味红线 + Anthropic `doc-coauthoring` 范式（主对话即 LLM judge，零外部 API）。

> "好文稿是改出来的。热写稿，冷改稿。"

**Prerequisites**：bash + python3.9+（macOS 自带）+ pandoc（仅 DOCX 模式 `brew install pandoc`）。`scripts/scan-ai-taste.sh` 已 chmod +x。

## §1 Mode 路由

### 1.1 触发词表

| Mode | 触发关键词 | 默认行为 | 输出 | 时长 |
|---|---|---|---|---|
| **Coach** | 帮我写 / 起草 / 拟稿 / 搭提纲 / 草稿 / draft this / outline | 多轮交互（摹仿→制造→创造） | 提纲 + 段落范本 | 5-15 min |
| **Polish** | 润色 / 审稿 / 改稿 / polish / review / proofread | 单轮主导 / 长稿分段 | 修改稿 + 5 维评分 | 2-5 min |
| **Audit** | 快速过 / 扫一下 / 检查一下 / checkpoint | 脚本主导 | pass/fail + 违反点 | 30s |

### 1.2 触发词歧义解析

歧义触发词如「帮我看看」「改一改」→ 默认 **Polish**，主对话开场追问「快速扫描还是深度润色？」，给用户 30s 窗口切换 Audit。明示歧义但不阻塞默认流。

## §2 Protocols

### 2.1 Coach Protocol

1. **体裁判断 + 准备**：读 [`references/genre-guide.md`](references/genre-guide.md) §<体裁> + [`references/writing-methodology.md`](references/writing-methodology.md) + 选 [`assets/real-world-anchors/`](assets/real-world-anchors/) 对应锚本
2. **摹仿 → 制造 → 创造**：按 [`references/writing-coaching-arc.md`](references/writing-coaching-arc.md) 三段弧推进，每阶段给提纲 + 段落骨架
3. **转 Polish 收尾**：最终稿走一遍 Polish Protocol

### 2.2 Polish Protocol（7 步，主对话照此执行）

```
step 1 — 跑 L1 hard gate
  bash scripts/scan-ai-taste.sh --target <draft> --json
  → 读 JSON: exit_code / summary.red_line_violations_total / summary.categories

step 2 — L2 self-judge（主对话内联，零外部 API）
  读 draft + §3 D1-D5 mini-rubric → 输出 5 维 JSON：
  { "D1": {score, rationale, fixes}, ..., "D5": {...} }
  L2 不确信某维 → 读 references/constitution.md §D{X} 详细 rubric 补足

step 3 — L3 触发判断
  任一满足 → spawn 3 clean-context Agent，单条消息内并行：
    - draft 字数 > 2000
    - 体裁 ∈ {规范公文 / 调研报告 / 述职报告 / 咨询报告}
    - L2 任一维度 score < 3
  spawn 模板：prompts/reviewer.md
  L2 与 L3 评分取 min 汇总（保守裁判）

step 4 — 修改 draft（single-linear-writer，见 §4.6）
  4.1 先备份：cp <draft> <draft>.polish-backup-$(date +%s).md
  4.2 优先级：红线违反 > L2/L3 低分维度 > soft warnings
  4.3 行号倒序修改（避免 offset 漂移）
  4.4 draft > 5000 字 → 分段串行处理，每段独立验证

step 5 — 验证
  重跑 step 1 + step 2 → 期望 red_line=0 且 L2 所有维 ≥ 3
  若仍 fail → 至多再 1 轮 step 4-5；2 轮后仍 fail 上报用户决策

step 6 — 输出（格式见 §6）
  1. 修改后 draft（核心交付）
  2. 5 维 mini-bar
  3. 1 行修改概览
  4. 撤销命令

step 7 — opt-in 日志（用户启用 --log-to 时）
  scan-ai-taste.sh 自动写 L1 部分；主对话在 polish session 收尾
  时附加 L2/L3 评分 + rules_not_covered_but_feels_off → 同一 jsonl
```

### 2.3 Audit Protocol（2 步）

```
step 1: bash scripts/scan-ai-taste.sh --target <draft> --json
step 2: 输出 pass/fail + 红线分类列表
        若 fail，末尾追问"切到 Polish 自动修复？"（不直接修，等用户确认）
```

### 2.4 DOCX 桥接（Polish/Audit 通用）

```bash
# 输入
pandoc <input.docx> -t markdown -o /tmp/<name>.md

# 跑 Polish 或 Audit（同上）

# 回写（保留原 docx 样式）
pandoc /tmp/<name>.md -t docx -o <output.docx> --reference-doc=<input.docx>

# 可选 Track Changes
python3 scripts/docx-review-workflow.py <input.docx> <output.docx>
```

## §3 D1-D5 mini-rubric（L2 内联评分细则）

> SSOT: [`references/constitution.md`](references/constitution.md) §D1-§D5；本段是 cached compact mirror，改前对照。

| 维度 | 名称 | 1 分（系统违规） | 5 分（无瑕） | 典型 fail |
|---|---|---|---|---|
| **D1** | 标点 / 格式 | 多处 ASCII 直引号 / em-dash / 半角括号紧贴英文 | GB/T 15834 全合规 | "项目—结果" 用 em-dash |
| **D2** | 语言朴实 | 大量大厂黑话 / 戏剧化叙事 | 党政中性表达 | "赋能链路、跑通闭环" |
| **D3** | 议论方法 | 否定平行结构、僵化收尾、模糊副词堆砌 | 论据—论点链清晰 | "不仅 X 更是 Y，由此可见" |
| **D4** | 思维 | 单一线性 / 概念套娃 / 缺辩证 | 5 种思维明显（系统/辩证/形象/创新/逻辑） | 通篇平铺，无层次切换 |
| **D5** | 立意 | 无帅之兵 / 主题散乱 / AI 体散文 | 一句话能概括全文主旨 | "全而又全"无重心 |

每维 1-5 整数。L2 与 L3（如触发）取 min。

## §4 红线 4 铁律速查

> SSOT: [`references/anti-ai-taste-anchors.md`](references/anti-ai-taste-anchors.md) §0-§3；scan-ai-taste.sh 字面执行。

1. **GB/T 15834 标点**：弯引号 `""` `''`（U+201C/D/2018/9），禁 ASCII 直引号 / em-dash / 直角引号 / 半角括号紧贴英文术语
2. **公文黑词**：赋能 / 重塑 / 闭环 / 抓手 / 链路 / 颗粒度 / 拉通 / 跑通 / 复盘 / 对齐 / 三件套
3. **元注释**：作为一个 AI 助手 / 让我为您整理 / 希望对您有帮助 / 以上仅供参考
4. **戏剧化叙事**：三层防御 / 跑通 / 翻车 / 大刀阔斧 / 一战成名（IT 实物语境例外，scan ±2 行白名单）

## §4.5 五权分立 + 单线程 writer

| 目录 | 职责 |
|---|---|
| `SKILL.md` | protocol（操作序列） |
| `prompts/` | spawn template |
| `references/` | substance（评分细则 / 体裁 / 案例） |
| `scripts/` | gate logic（regex） |
| `assets/` | 锚本（真实公文范本） |

依赖方向单向无环：`SKILL.md ──> { prompts/, references/, scripts/, assets/ }`。

**Polish step 4 单线程 writer 铁律**：修改 draft 必由主对话串行，禁 spawn parallel writers（Cognition Walden Yan：actions carry implicit decisions，并行写会产生不可 reconcile 的冲突）。L3 reviewer 评分阶段并行，writer 阶段串行。

## §4.7 Contracts

| 契约文件 | 消费方 | 用途 |
|---|---|---|
| [`schemas/scan-output.schema.json`](schemas/scan-output.schema.json) | 主对话 | scan-ai-taste.sh --json 输出 |
| [`schemas/reviewer-output.schema.json`](schemas/reviewer-output.schema.json) | L3 reviewer / 主对话 | spawn Agent 返回 |
| [`schemas/eval-record.schema.json`](schemas/eval-record.schema.json) | --log-to / evals/ | jsonl 单行结构 |

契约改动 = break change，必同步 schemas/ + 所有 consumer + bump SKILL 版本。

## §4.8 --log-to opt-in（v6.1 evolution-queue 种子）

```bash
bash scripts/scan-ai-taste.sh --target <draft> --json --log-to ~/.writing-polish/log.jsonl
```

默认关；用户主动开启后，每次 polish session 写一行 JSON 到目标文件，含：

- L1 scan summary + L2 自评 + L3 评分（如有）
- `rules_not_covered_but_feels_off`（reviewer 觉得是 AI 味但 230 规则未覆盖的样本）

v6.1 evolution-queue 消费这批日志，按频次排序后人工评审晋升为新规则。

## §5 资源路由表（按 load-when 查表）

| 资源 | scope | load when |
|---|---|---|
| [`references/anti-ai-taste-anchors.md`](references/anti-ai-taste-anchors.md) | all | L1 fail 时查规则细则 |
| [`references/constitution.md`](references/constitution.md) | polish | L2 self-judge 不确信时读详细 rubric |
| [`references/revision-checklist.md`](references/revision-checklist.md) | polish | step 4 修改阶段决策依据 |
| [`references/genre-guide.md`](references/genre-guide.md) §<X> | all | 体裁判断后读对应章节 |
| [`references/writing-methodology.md`](references/writing-methodology.md) | coach | Coach step 1 |
| [`references/writing-coaching-arc.md`](references/writing-coaching-arc.md) | coach | Coach 全程（摹仿→制造→创造） |
| [`references/peer-vs-self-revision.md`](references/peer-vs-self-revision.md) | polish, L3 | reviewer 必读（"他批"语气） |
| [`references/logic-and-structure.md`](references/logic-and-structure.md) | polish D3 | L2 D3 评分时读 |
| [`references/gongwen-format.md`](references/gongwen-format.md) | polish 公文 | 体裁 = 规范公文 时读 |
| [`references/citation-spec.md`](references/citation-spec.md) | polish 调研 | 体裁 = 调研报告 时读 |
| [`references/docx-editing-guide.md`](references/docx-editing-guide.md) | docx | DOCX 模式必读 |
| [`references/ai-taste-examples.md`](references/ai-taste-examples.md) | L2, L3 | 评分时可选引用反例对照 |
| [`references/failure-cases.md`](references/failure-cases.md) | polish | scan 多轮失败时查同类历史 |
| [`prompts/reviewer.md`](prompts/reviewer.md) | polish L3 | L3 spawn 模板 |
| [`prompts/llm-judge-research-report.md`](prompts/llm-judge-research-report.md) | polish 咨询 | 体裁 = 咨询报告 时附加 |
| [`assets/real-world-anchors/`](assets/real-world-anchors/) | coach, polish | 体裁判断后展示锚本 |
| [`assets/anchor-essays/`](assets/anchor-essays/) | coach | 摹仿阶段（《怎样写作》8 篇范例） |
| [`scripts/scan-ai-taste.sh`](scripts/scan-ai-taste.sh) | polish, audit | L1 hard gate 主体（--json 输出供主对话） |
| [`scripts/scan-hard-gate.sh`](scripts/scan-hard-gate.sh) | CI | 最小集 30 条码点级（毫秒级） |
| [`scripts/auto-fix-loop.sh`](scripts/auto-fix-loop.sh) | polish | 自动修复 1-2 轮（可选） |
| [`scripts/docx-review-workflow.py`](scripts/docx-review-workflow.py) | docx | Track Changes 自动化 |
| [`scripts/check-dependencies.sh`](scripts/check-dependencies.sh) | setup | 首次使用 sanity check |
| [`scripts/word-count-check.sh`](scripts/word-count-check.sh) | polish | 句长方差 / 段同质化 |
| [`scripts/check-cn-quotes.py`](scripts/check-cn-quotes.py) | polish | 中文引号专项验证 |

## §6 输出格式 + 修改哲学

### Polish mode 输出（固定结构）

```
1. 修改稿（核心交付，markdown / docx）

2. 5 维 mini-bar:
   D1 ████░ 4/5   D2 ███░░ 3/5   D3 █████ 5/5   D4 ███░░ 3/5   D5 ████░ 4/5

3. 修改概览（1 行）:
   "改了 3 处黑词、2 处长句切分、1 处立意补强"

4. 撤销命令:
   cp <draft>.polish-backup-<timestamp>.md <draft>
```

### 修改哲学 + 严守纪律

- 先大后小（立意 → 结构 → 段落 → 字词）+ 先减后加 + 可改可不改的不改 + 受众/批评者换位 + 念改
- 不返回 5 页报告、不主动加 emoji、不夸/贬作者（[`references/peer-vs-self-revision.md`](references/peer-vs-self-revision.md) "他批"礼貌）、不引入元注释、只交付结果
