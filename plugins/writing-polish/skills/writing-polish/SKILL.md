---
name: writing-polish
description: Coaches, drafts, polishes, and audits Chinese documents based on 《怎样写作》(任仲然). Three modes — coach (帮我写/起草/拟稿/搭提纲), polish (润色/审稿/改稿, default for ambiguous triggers), audit (快速过/checkpoint). Triggers on 润色/审稿/改稿/帮我写/起草/拟稿/搭提纲/审一审/改一改/polish/review/proofread/帮我看看/DOCX 修订. Does NOT trigger for translation, code review, English-only writing.
allowed-tools: Bash, Read, Edit, Write, Agent
---

# writing-polish v6.1

任仲然《怎样写作》+ 230 余条 AI 味红线 + Anthropic Evaluator-Optimizer 范式（主对话编排，clean-context reviewer 必跑兜底）。

> "好文稿是改出来的。热写稿，冷改稿。"

**Prerequisites**：bash + python3.9+（macOS 自带）+ pandoc（仅 DOCX 模式 `brew install pandoc`）。`scripts/scan-ai-taste.sh` 已 chmod +x。

## §0 Skill 速览

| 项 | 内容 |
|---|---|
| **三层架构** | L1 = `scan-ai-taste.sh` regex 硬扫 230 红线；L2 = 主对话自评 5 维并 Write trace 文件；L3 = clean-context `Agent()` reviewer（**Polish mode 默认至少 1 跑**）|
| **评分量纲** | 0-3 整数 + `"unknown"`，0=无瑕、3=系统性违规。汇总 `max()`（任一审稿人认为更差就以更差为准 = 保守裁判）|
| **可验证性** | L2 必须 Write `.writing-polish-trace/<draft>-<ts>.json`，**文件缺 = L2 弃权 → L3 兜底全维度**。schema 校验 `schemas/reviewer-output.schema.json` |

## §1 Mode 路由

### 1.1 触发词表

| Mode | 触发关键词 | 默认行为 | 输出 | 时长 |
|---|---|---|---|---|
| **Coach** | 帮我写 / 起草 / 拟稿 / 搭提纲 / 草稿 / draft this / outline | 多轮交互（摹仿→制造→创造） | 提纲 + 段落范本 | 5-15 min |
| **Polish** | 润色 / 审稿 / 改稿 / polish / review / proofread | 主对话编排 + ≥ 1 clean-context reviewer | 修改稿 + 5 维 mini-bar | 2-5 min |
| **Audit** | 快速过 / 扫一下 / 检查一下 / checkpoint | 脚本主导，零 reviewer | pass/fail + 违反点 | 30s |

### 1.2 触发词歧义解析

歧义触发词「帮我看看」「改一改」→ 主对话**先估字数再给推荐 + 理由**，30s 窗口可改：

| draft 字数 | 默认 | 推荐理由 |
|---|---|---|
| < 500 字 | Audit | 短稿红线扫描足够，spawn reviewer 不划算 |
| 500-3000 字 | Polish | 标准润色，1 个 D5 spot-check 兜底 |
| > 3000 字 | Polish（分段） | 长稿升级 3 reviewer 并行 |

文案示例：`「建议 Polish（800 字属标准润色档；将 spawn 1 个 D5 reviewer 兜底）。30s 内回复 audit/coach 可改。」`

用户已在触发词里明示 mode（如「润色」「快速过」）→ 跳过该步。

## §2 Protocols

### 2.1 Coach Protocol

1. **体裁判断 + 准备**：读 [`references/genre-guide.md`](references/genre-guide.md) §<体裁> + [`references/writing-methodology.md`](references/writing-methodology.md) + 选 [`assets/real-world-anchors/`](assets/real-world-anchors/) 对应锚本
2. **摹仿 → 制造 → 创造**：按 [`references/writing-coaching-arc.md`](references/writing-coaching-arc.md) 三段弧推进，每阶段给提纲 + 段落骨架
3. **转 Polish 收尾**：最终稿走一遍 Polish Protocol

### 2.2 Polish Protocol（7 步，主对话照此执行）

```
step 1 — L1 hard gate
  bash scripts/scan-ai-taste.sh --target <draft> --json
  → 读 JSON: exit_code / summary.red_line_violations_total / summary.categories

step 2 — L2 self-judge + 必须 Write trace 文件
  2.1 读 draft + §3 D1-D5 mini-rubric（不确信某维 → 读 references/constitution.md §D{X}）
  2.2 为每维输出符合 schemas/reviewer-output.schema.json 的对象，source="L2-self"
  2.3 用 Write 工具落 .writing-polish-trace/<draft-name>-<unix-ts>.json
        格式：{"l2": [{"dimension":"D1","source":"L2-self","score":0|1|2|3|"unknown",...}, ...]}
  2.4 用户可见区只显示一行摘要：
        "L2 self-judge: D1✓ D2⚠ D3✓ D4✓ D5⚠ → trace .writing-polish-trace/...json"
  2.5 trace 文件未写成功 → 视为 L2 弃权 → step 3 强制 L3 全维度兜底

step 3 — L3 reviewer（默认必跑 ≥ 1，按 references/reviewer-routing.md 分摊）
  3.1 跑 scripts/select-fewshot.sh <draft> <dimension> 拼 prompt §4 校准锚
  3.2 默认：spawn 1 个 D5 spot-check（prompts/spot-check.md，轻量）
  3.3 升级 3 reviewer 并行（D2 + D3 + D5）当：
        - draft > 2000 字
        - 体裁 ∈ {规范公文 / 调研报告 / 述职报告 / 咨询报告}
        - L2 任一 score ≥ 2
        - L2 弃权（trace 文件缺失）
  3.4 体裁特例：规范公文 / 咨询报告 → D1 + D2 + D5
  3.5 每 spawn 立刻一行用户可见 `[spawn reviewer-D5...]`，返回时 `[D5 score=1 ✓]`
  3.6 失败 retry 1 次（2s 退避）；2 次都失败记 missing-vote
  3.7 汇总：D{X} 取 L2_score 与所有 L3_score(D{X}) 的 max（更差为准）

step 4 — 修改 draft（single-linear-writer，见 §4.5）
  4.1 先备份：cp <draft> <draft>.polish-backup-$(date +%s).md
  4.2 优先级：红线违反 > L2/L3 高分维度（score ≥ 2）> soft warnings
  4.3 行号倒序修改（避免 offset 漂移）
  4.4 draft > 5000 字 → 分段串行处理，每段独立验证

step 5 — 验证（clean-context spot-check，禁用 L2 自评回路）
  5.1 重跑 step 1 → 期望 red_line_violations_total = 0
  5.2 spawn 1 个 clean-context Agent 跑 prompts/spot-check.md 对修改稿做 D5 spot-check
  5.3 spot-check score ≤ 1 且 L1 通过 → step 6
  5.4 否则 step 4 第二轮；2 轮仍 fail → 上报用户决策

step 6 — 输出（格式见 §6）
  1. 修改后 draft（核心交付）
  2. 5 维状态符号 mini-bar（✓ ⚠ ✗ ?）
  3. 1 行修改概览
  4. 撤销命令
  5. trace 文件路径（.writing-polish-trace/*.json）

step 7 — opt-in 日志（用户启用 --log-to 时）
  scan-ai-taste.sh 自动写 L1 部分；主对话在 polish session 收尾时附加
  L2/L3 评分 + rules_not_covered_but_feels_off → 同一 jsonl
```

### 2.3 Audit Protocol（2 步）

```
step 1: bash scripts/scan-ai-taste.sh --target <draft> --json
step 2: 输出 pass/fail + 红线分类列表
        若 fail，末尾追问"切到 Polish 自动修复？"（不直接修，等用户确认）
```

### 2.4 DOCX 桥接（Polish/Audit 通用）

```bash
pandoc <input.docx> -t markdown -o /tmp/<name>.md          # 输入
# 跑 Polish 或 Audit（同上）
pandoc /tmp/<name>.md -t docx -o <output.docx> --reference-doc=<input.docx>  # 回写
python3 scripts/docx-review-workflow.py <input.docx> <output.docx>           # 可选 Track Changes
```

## §3 D1-D5 mini-rubric（0-3 量纲，3=最差）

> SSOT: [`references/constitution.md`](references/constitution.md) §D1-§D5；本段是 cached compact mirror，改前对照。

| 维度 | 名称 | 0 分（无瑕） | 3 分（系统违规） | 典型 fail |
|---|---|---|---|---|
| **D1** | 标点 / 格式 | GB/T 15834 全合规 | 多处 ASCII 直引号 / em-dash / 半角括号紧贴英文 | "项目—结果" 用 em-dash |
| **D2** | 显式 AI 套话 | 党政中性 / 无套话 | 大量大厂黑话密集出现 | "赋能链路、跑通闭环" |
| **D3** | 隐喻强度 | 平实表达 / IT 实物语境合法术语 | 全篇戏剧化叙事 | "三层防御""跑通""翻车" |
| **D4** | 大厂 vs 党政语境失配 | 语境一致 | 全篇错位 | 「对标」党政合法 vs 大厂赛马 |
| **D5** | 整体散文 AI 体 | 具体克制 / 论据—论点链清晰 | 全篇假大空 / 否定平行堆砌 | "不仅 X 更是 Y，由此可见" |

每维 0-3 整数或 `"unknown"`（证据不足时）。L2 与 L3 取 `max()`（保守裁判）。

## §4 红线 4 铁律速查

> SSOT: [`references/anti-ai-taste-anchors.md`](references/anti-ai-taste-anchors.md) §0-§3；scan-ai-taste.sh 字面执行。

1. **GB/T 15834 标点**：弯引号 `"" ''`（U+201C/D/2018/9），禁 ASCII 直引号 / em-dash / 直角引号 / 半角括号紧贴英文术语
2. **公文黑词**：赋能 / 重塑 / 闭环 / 抓手 / 链路 / 颗粒度 / 拉通 / 跑通 / 复盘 / 对齐 / 三件套
3. **元注释**：作为一个 AI 助手 / 让我为您整理 / 希望对您有帮助 / 以上仅供参考
4. **戏剧化叙事**：三层防御 / 跑通 / 翻车 / 大刀阔斧 / 一战成名（IT 实物语境例外，scan ±2 行白名单）

## §4.5 五权分立 + 单线程 writer

| 目录 | 职责 |
|---|---|
| `SKILL.md` | protocol（操作序列） |
| `prompts/` | spawn template（reviewer / spot-check） |
| `references/` | substance（评分细则 / 体裁 / 案例 / routing） |
| `scripts/` | gate logic（regex / fewshot 选取 / 依赖检查） |
| `assets/` | 锚本（真实公文范本） |

依赖方向单向无环：`SKILL.md ──> { prompts/, references/, scripts/, assets/ }`；`scripts/check-dependencies.sh --check-cycles` 自动报警反向引用。

**Polish step 4 单线程 writer 铁律**：修改 draft 必由主对话串行，禁 spawn parallel writers（Cognition Walden Yan：actions carry implicit decisions，并行写会产生不可 reconcile 的冲突）。L3 reviewer 评分阶段并行，writer 阶段串行。

## §4.6 Contracts

| 契约文件 | 消费方 | 用途 |
|---|---|---|
| [`schemas/scan-output.schema.json`](schemas/scan-output.schema.json) | 主对话 | scan-ai-taste.sh --json 输出 |
| [`schemas/reviewer-output.schema.json`](schemas/reviewer-output.schema.json) | L2 trace / L3 reviewer / spot-check | 0-3 量纲 + source 枚举 |
| [`schemas/eval-record.schema.json`](schemas/eval-record.schema.json) | --log-to / evals/ | jsonl 单行结构 |

契约改动 = break change，必同步 schemas/ + 所有 consumer + bump SKILL 版本。

## §4.7 anchor / eval 隔离铁律

| 文件 | 用途 | 注入 prompt? |
|---|---|---|
| [`evals/anchor-set.jsonl`](evals/anchor-set.jsonl) | reviewer few-shot 校准锚 | ✅ 仅注入 verified 样本 |
| [`evals/eval-set.jsonl`](evals/eval-set.jsonl) | κ 一致性 / regression 测试 | ❌ **禁止注入**（Grader Gaming 红线） |

详 [`evals/README.md`](evals/README.md)。

## §5 资源路由表（Mode → 必读，progressive disclosure）

| Mode | 必读 | 按需 |
|---|---|---|
| **Coach** | `references/writing-coaching-arc.md` + `assets/anchor-essays/` | 体裁后 `references/genre-guide.md` §<X> |
| **Polish** | `prompts/reviewer.md` + `prompts/spot-check.md` + `references/reviewer-routing.md` | L2 不确信 → `references/constitution.md` §D{X} |
| **Audit** | `scripts/scan-ai-taste.sh` | L1 fail → `references/anti-ai-taste-anchors.md` |

完整 19 资源路由 → [`references/resource-routing.md`](references/resource-routing.md)（按需加载）。

## §6 输出格式 + 修改哲学

### Polish mode 输出（固定结构）

```
1. 修改稿（核心交付，markdown / docx）

2. 5 维状态符号 mini-bar（0=最好，3=最差；"unknown"=?）：
   D1 ✓ (0)   D2 ⚠ (1)   D3 ✓ (0)   D4 ⚠ (2)   D5 ? (unknown)

3. 修改概览（1 行）：
   "改了 3 处黑词、2 处长句切分、1 处立意补强"

4. 撤销命令：
   cp <draft>.polish-backup-<timestamp>.md <draft>

5. trace 文件：
   .writing-polish-trace/<draft>-<unix-ts>.json
```

### 修改哲学 + 严守纪律

- 先大后小（立意 → 结构 → 段落 → 字词）+ 先减后加 + 可改可不改的不改 + 受众/批评者换位 + 念改
- 不返回 5 页报告、不主动加 emoji、不夸/贬作者（[`references/peer-vs-self-revision.md`](references/peer-vs-self-revision.md) "他批"礼貌）、不引入元注释、只交付结果
