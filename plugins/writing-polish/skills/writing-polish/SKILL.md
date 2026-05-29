---
name: writing-polish
description: Coaches, drafts, polishes, and audits Chinese documents using 《怎样写作》(任仲然). Three modes — coach (帮我写/起草/拟稿/搭提纲), polish (润色/审稿/改稿, default for ambiguous triggers), audit (快速过/checkpoint). Triggers on 润色/审稿/改稿/帮我写/起草/拟稿/搭提纲/审一审/改一改/polish/review/proofread/帮我看看/DOCX 修订. Does NOT trigger for translation, code review, English-only writing.
allowed-tools: Bash, Read, Edit, Write, Task
---

# writing-polish v7.0

任仲然《怎样写作》+ 230 余条 AI 味红线 + clean-context 反馈式审校（Anthropic evaluator-optimizer 范式）。

> 「好文稿是改出来的。热写稿，冷改稿。」

**Prerequisites**：bash + python3.9+（macOS 自带）+ pandoc（仅 DOCX 模式 `brew install pandoc`）。`scripts/scan-ai-taste.sh` 已 chmod +x。

## §0 速览：评价分两个世界

写作评价分两层，本技能严格区分（per-use 不打数值分，数值只在离线）：

| | per-use 热路径（每次改稿都跑） | 离线 dev-eval（只在改规则时跑） |
|---|---|---|
| 目的 | 让这一篇变好 | 衡量本技能本身好不好 |
| 评价输出 | **自然语言可执行反馈 + 粗判闸门**（够好了/要改/红线未清） | 数值逐维分（offline benchmark） |
| 落点 | `scan-ai-taste.sh`（L1 硬扫）+ `agents/writing-reviewer.md`（clean-context reviewer） | [`evals/offline-harness/`](evals/offline-harness/) |

- **每篇改稿只用自然语言反馈**：reviewer 指到具体句、说清 why、给改法；主对话据此串行改稿。不打 0-3 分、不写 trace、不取 max。
- **reviewer 同时查正向实质轴**：立意 / 结构与论据 / 材料·事实，不只查 AI 味——单边评测导致单边优化（Anthropic 2026-01）。

## §1 Mode 路由

### 1.1 触发词表

| Mode | 触发关键词 | 默认行为 | 输出 | 时长 |
|---|---|---|---|---|
| **Coach** | 帮我写 / 起草 / 拟稿 / 搭提纲 / 草稿 / draft / outline | 监督生成弧（立意→构思→提纲→材料→结构，逐段 checkpoint） | 提纲 + 段落范本 | 5-15 min |
| **Polish** | 润色 / 审稿 / 改稿 / polish / review / proofread | L1 硬扫 + ≥ 1 clean-context reviewer + 主对话串行改稿 | 修改稿 + 按焦点分组 NL 复盘 + verdict | 2-5 min |
| **Audit** | 快速过 / 扫一下 / 检查一下 / checkpoint | 脚本主导，零 reviewer | pass/fail + 红线分类 | 30s |

### 1.2 触发词歧义解析

歧义触发词「帮我看看」「改一改」→ 主对话先估字数（可用 `scripts/word-count-check.sh`）再给推荐 + 理由，30s 窗口可改：

| draft 字数 | 默认 | 理由 |
|---|---|---|
| < 500 字 | Audit | 短稿红线扫描足够，spawn reviewer 不划算 |
| 500-3000 字 | Polish | 标准润色，1 个全焦点 reviewer |
| > 3000 字 | Polish（分段） | 长稿升级 2-3 个按焦点分摊的 reviewer |

文案示例：`「建议 Polish（800 字属标准档；将 spawn 1 个全焦点 reviewer）。30s 内回复 audit/coach 可改。」`。用户已在触发词明示 mode → 跳过该步。

## §2 Protocols

### 2.1 Coach Protocol（监督生成弧）

按 [`references/coach-checkpoints.md`](references/coach-checkpoints.md) 走 立意→构思→提纲→材料→结构 五段，每段一个用户确认 checkpoint（**默认可跳过，不强制**）。要点：

1. **准备**：判体裁 → 读 [`references/genre-guide.md`](references/genre-guide.md) §<体裁> + [`references/writing-methodology.md`](references/writing-methodology.md) + 选 [`assets/real-world-anchors/`](assets/real-world-anchors/) 同体裁锚本。
2. **立意 ✋**：收敛到「一个」核心问题（拒「全而又全」）+ 小切口→大思路 + 列观察日志（3-5 条具体细节）。
3. **提纲 ✋**：粗纲 → 细纲（每段 1 行判断）+ 标注同级并列/递进。提纲早出手、初稿晚出手。
4. **材料 ✋·事实敬畏**：列素材清单，每条标三态——①可证实直接用 / ②未提供需追问（列清单问用户，**不替写**）/ ③不得编造。
5. **成稿**：用确认的提纲 + 素材填内容，结构服务内容，朴实克制。
6. **收尾**：成稿走一遍 Polish Protocol。

路由：「教我写作 / 练笔」→ [`references/writing-coaching-arc.md`](references/writing-coaching-arc.md)（摹仿→制造→创造 技能弧）；「帮我写这篇」→ 上述生产弧。

### 2.2 Polish Protocol（4 步，主对话照此执行）

```
step 1 — L1 hard gate
  bash scripts/scan-ai-taste.sh --target <draft> --json
  → 读 exit_code / summary.red_line_violations_total / summary.categories
  → 红线命中入「待修清单」（不立即改）

step 2 — clean-context reviewer(s)（默认 ≥ 1，按 references/reviewer-routing.md 分焦点）
  2.1 定 reviewer 数与各自 focus（按长度/体裁分摊焦点，见 routing 决策表）
  2.2 每个 reviewer 用 Task 工具 spawn writing-reviewer 子代理（clean context），任务 prompt 注入：
        draft 全文 + 该 reviewer 的 focus 列表 + constitution 对应体裁切片 + 当前日期 + 项目豁免清单
  2.3 每 spawn 一行用户可见 [spawn writing-reviewer focus=立意+结构]；返回时 [verdict=要改]
  2.4 reviewer 返回 <feedback>（按焦点分组 NL）+ <verdict>够好了|要改|红线未清</verdict>
  2.5 失败 retry 1 次（2s 退避）；2 次失败记 missing-review（不静默降级 = fix-the-tool-don't-fallback）

step 3 — 修改 draft（single-linear-writer，主对话串行，见 §4.5）
  3.1 先备份：cp <draft> <draft>.polish-backup-$(date +%s).md
  3.2 优先级：红线违反 > reviewer 标注的实质问题（立意/结构/材料）> AI 味软提示
  3.3 行号倒序修改（避免 offset 漂移）；draft > 5000 字 → 分段串行
  3.4 事实层：reviewer 标「需追问/不得编造」的缺口 → 向用户追问，绝不替写

step 4 — 验证 + 输出
  4.1 重跑 step 1 → 期望 red_line_violations_total = 0
  4.2 仍有 reviewer verdict = 红线未清 / 要改（实质类）→ 再走一轮 step 3；最多 2 轮，仍不过上报用户
  4.3 输出（格式见 §6）
```

### 2.3 Audit Protocol（2 步）

```
step 1: bash scripts/scan-ai-taste.sh --target <draft> --json
step 2: 输出 pass/fail + 红线分类列表；若 fail，末尾追问「切到 Polish 自动修复？」（不直接修，等确认）
```

### 2.4 DOCX 桥接（Polish/Audit 通用）

```bash
pandoc <input.docx> -t markdown -o /tmp/<name>.md          # 输入
# 跑 Polish 或 Audit（同上）
pandoc /tmp/<name>.md -t docx -o <output.docx> --reference-doc=<input.docx>  # 回写
python3 scripts/docx-review-workflow.py <input.docx> <output.docx>           # 可选 Track Changes
```

## §3 红线 4 铁律速查

> SSOT: [`references/anti-ai-taste-anchors.md`](references/anti-ai-taste-anchors.md) §0-§3；`scan-ai-taste.sh` 字面执行。

1. **GB/T 15834 标点**：弯引号 `"" ''`（U+201C/D/2018/9），禁 ASCII 直引号 / em-dash / 直角引号 / 半角括号紧贴英文术语
2. **公文黑词**：赋能 / 重塑 / 闭环 / 抓手 / 链路 / 颗粒度 / 拉通 / 跑通 / 复盘 / 对齐 / 三件套
3. **元注释**：作为一个 AI 助手 / 让我为您整理 / 希望对您有帮助 / 以上仅供参考
4. **戏剧化叙事**：三层防御 / 跑通 / 翻车 / 大刀阔斧 / 一战成名（IT 实物语境例外，scan ±2 行白名单）

## §4 三大审查焦点 + 红线（NL，reviewer 据此分组反馈）

> SSOT: [`references/constitution.md`](references/constitution.md) §0「四大审查焦点」+ §0.5「正向实质三焦点」。per-use 不打数值分。

| 焦点 | 好的样子 | 差的样子 |
|---|---|---|
| **立意** | 一文一主题、小切口大思路、有穿透力 | 全而又全、开篇堆大词、平淡正确 |
| **结构与论据** | 同级层次清楚、结构服务内容、论点—论据链连贯 | 僵化三段式、并列失衡、论证跳跃 |
| **材料·事实** | 货真价实、多样、有数据；事实三态分明 | 模糊副词堆砌、缺数据支撑、编造/含糊归因 |
| **AI味·标点** | 平实克制、标点合规、语境一致 | 黑词密集、戏剧化隐喻、ASCII 标点、否定平行 |

**事实敬畏三态**（材料焦点核心）：① 已有材料可证实 → 用；② 用户未提供需追问 → 列清单问用户，不替写；③ 不得替用户编造。

## §4.5 五权分立 + 单线程 writer

| 目录 | 职责 |
|---|---|
| `SKILL.md` | protocol（操作序列） |
| `agents/writing-reviewer.md` | clean-context reviewer 子代理（只评不改，返回 NL 反馈 + verdict） |
| `references/` | substance（评判依据 / 体裁 / 案例 / routing / 12 讲覆盖矩阵） |
| `scripts/` | gate logic（L1 regex / 字数 / 依赖检查） |
| `assets/` | 锚本（真实公文范本 + 任仲然 8 范例） |
| `evals/offline-harness/` | 离线数值评测（改规则时才用，不进 per-use 路径） |

**Polish step 3 单线程 writer 铁律**：改 draft 必由主对话串行，禁 spawn parallel writers（Cognition Walden Yan：actions carry implicit decisions，并行写产生不可 reconcile 的冲突）。reviewer 评分阶段可并行，writer 阶段串行。

## §5 资源路由表（Mode → 必读，progressive disclosure）

| Mode | 必读 | 按需 |
|---|---|---|
| **Coach** | `references/coach-checkpoints.md` + `references/writing-coaching-arc.md` + `assets/anchor-essays/` | 体裁后 `references/genre-guide.md` §<X> |
| **Polish** | `agents/writing-reviewer.md` + `references/reviewer-routing.md` | reviewer 需判依据 → `references/constitution.md` 体裁切片 |
| **Audit** | `scripts/scan-ai-taste.sh` | L1 fail → `references/anti-ai-taste-anchors.md` |

完整资源路由 → [`references/resource-routing.md`](references/resource-routing.md)（按需加载）。任仲然 12 讲继承审计 → [`references/renzhongran-coverage-matrix.md`](references/renzhongran-coverage-matrix.md)。

## §6 输出格式 + 修改哲学

### Polish mode 输出（固定结构）

```
1. 修改稿（核心交付，markdown / docx）
2. 按焦点分组的 NL 复盘 + 总 verdict：
   【立意】补强了一处…  【结构】切分了 2 处长段…  【材料/事实】1 处缺数据已向你追问…  【AI味/标点】改了 3 处黑词
   → verdict: 够好了
3. 修改概览（1 行）："改了 3 处黑词、2 处长句切分、1 处立意补强"
4. 撤销命令：cp <draft>.polish-backup-<timestamp>.md <draft>
```

### 修改哲学 + 严守纪律

- 先大后小（立意 → 结构 → 段落 → 字词）+ 先减后加 + 可改可不改的不改 + 受众/批评者换位 + 念改
- 不返回 5 页报告、不主动加 emoji、不夸/贬作者（[`references/peer-vs-self-revision.md`](references/peer-vs-self-revision.md)「他批」礼貌）、不引入元注释、只交付结果
- per-use 不打数值分、不写 trace 文件——数值评测在 [`evals/offline-harness/`](evals/offline-harness/)
