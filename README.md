# 轩匠 Xuan-Jiang

让 Claude Code 写出像人写的中文，而不是机器吐的中文。

轩匠是一个专注中文写作的 Claude Code 插件。它把任仲然 40 年公文写作方法论（《怎样写作》）转化为 AI 可执行的写作与润色工作流，配套一套无歧义硬红线 + 软信号的中文 AI 味检查机制（语境判断交 clean-context 审稿子代理），并用 clean-context 审稿子代理做反馈式审校。

> 2026-04 重大重构：开发者工作流插件已迁出至独立仓库 [workflow-toolkit](https://github.com/sinnohzeng/workflow-toolkit)，本仓库专注写作。

---

## 这个技能解决什么问题

让 AI 写中文稿子，常见三种不达标：

1. **正确但没人想读**：通篇都对，全是大词、政策口号、抽象动词，删一半字意思不变（RLHF“标准答案机”模式）。
2. **改稿改成校对员**：只改错别字、标点、术语，遇到立意不清、结构失衡、材料不实这些根本问题就装看不见。
3. **一眼能看出机器味**：破折号到处插、括号塞补充、套话连接词反复、客服腔、伪极客战斗化叙事、大厂黑话堆砌。

轩匠分别用“立意/结构/材料正向审查”“先大后小的改稿哲学”“无歧义硬红线扫描与 clean-context 复核”对应这三种。

---

## 动笔之前：先问清谁在读、怎么读到

任何写作与润色之前，轩匠先核实四件事：读者是谁（具体到单位、层级、拿这份材料去干什么），我方是谁（与读者的关系、有没有资格下判断和提要求），读者经由什么媒介接收（会场口播听到、纸面印发读到、屏幕扫读、微信即时通讯、机器解析），以及有没有第二受众（讲话稿印发下去给谁读、抄送到哪里）。四个问题的答案共同决定口吻：身份关系摆错，措辞再讲究也是错的。

讲话与党课类稿子还要多走一步：逐句预演听众反应，问一句“台下的人听了会怎么想、会不会多想”。写给熟人和私人读者的稿子则反过来收敛：防的是商务腔和过度客气，不是越界。方法论出处是任仲然《怎样写作》第七讲的受众三问：一要明白谁要讲话，二要明白在什么场合对什么人讲话，三要明白印发下去的讲话给谁看。

协议入口见 [`SKILL.md`](plugins/writing-polish/skills/writing-polish/SKILL.md)，四问细则与场景包见 [`stance-and-register.md`](plugins/writing-polish/skills/writing-polish/references/stance-and-register.md)。

---

## v7.0 架构：评价分两个世界

写作评价分两层，轩匠严格区分（这是 v7.0 的核心重构，对齐业界 Self-Refine / Reflexion / Anthropic evaluator-optimizer 的做法）：

| | per-use 热路径（每次改稿都跑） | 离线 dev-eval（只在改规则时跑） |
|---|---|---|
| 目的 | 让这一篇变好 | 衡量 polisher 本身好不好 |
| 评价输出 | **自然语言可执行反馈与粗判**（够好了/要改/红线未清） | 数值逐维分（offline benchmark） |
| 落点 | `scan-ai-taste.sh`（L1 硬扫）与 `agents/writing-reviewer.md` | `evals/offline-harness/` |

**为什么这么分**：改稿循环要的是“指到具体句、怎么改”的可执行反馈，一个 `0-3` 分数没法直接编辑；而数值逐维打分（G-Eval / Prometheus / MT-Bench 流派）的价值是可聚合、跨样本比较，那是离线衡量“这个 polisher 好不好”需要的，不是单篇改稿需要的。

### 四种模式

| Mode | 触发 | 行为 |
|---|---|---|
| **Coach** | 帮我写 / 起草 / 拟稿 / 搭提纲 | 监督生成弧：站位四问、立意、构思、提纲、材料、结构，逐段 checkpoint（含事实敬畏三态：可证实 / 需追问 / 不得编造） |
| **Polish** | 润色 / 审稿 / 改稿（歧义触发默认） | L1 硬扫，至少 1 个 clean-context reviewer 返回按焦点分组的自然语言反馈，主对话串行改稿 |
| **Audit** | 快速过 / 扫一下 / checkpoint | 脚本主导，30 秒出 pass/fail 与红线分类 |
| **Express** | 快速改 / 帮我顺一下 / 看看这段 | 一行式站位确认、L1 scan、单轮改稿（无 reviewer） |

### 五大审查焦点

reviewer 不打数值分，按五个焦点给反馈：**口吻与站位**（第一顺位：站位四问、身份关系、媒介匹配）、**立意**（一文一主题、反“全而又全”）、**结构与论据**（同级层次、论点与论据链）、**材料·事实**（货真价实、数据支撑、事实敬畏三态）、**AI味·标点·翻译腔**（约 80 条红线，GB/T 15834 标点）。后三个正向实质轴回应“单边评测导致单边优化”：不能只查“像不像 AI”，还要查“写得好不好”。

完整协议见 [`SKILL.md`](plugins/writing-polish/skills/writing-polish/SKILL.md)。任仲然 12 讲逐项继承审计见 [`renzhongran-coverage-matrix.md`](plugins/writing-polish/skills/writing-polish/references/renzhongran-coverage-matrix.md)。

---

## 安装

```bash
claude plugin marketplace add https://github.com/sinnohzeng/xuan-jiang.git
claude plugin install writing-polish@xuan-jiang
```

调用：`/writing-polish` 或拼音别名 `/runse`。

---

## 使用方式

### 写作辅助（Coach）

```
帮我写一篇关于安全生产的讲话稿
搭个提纲，主题是数字化转型
```

工作流：判体裁，立意 checkpoint（收敛单一主题与小切口）、提纲 checkpoint、材料 checkpoint（标事实三态、缺口向你追问而非编造）、成稿、转 Polish 收尾。

### 审稿润色（Polish）

```
帮我润色这篇文章
审稿 /path/to/speech.docx
```

工作流：L1 `scan-ai-taste.sh` 硬扫红线，spawn clean-context `writing-reviewer` 子代理按焦点给反馈，主对话串行改稿（先大后小），重跑 L1 验证，输出修改稿与按焦点分组的复盘。

### DOCX 修订

```
用修订模式帮我改 /path/to/document.docx
```

经 pandoc 桥接，支持 Track Changes，默认作者“任仲然”。技术路线见 [`docx-editing-guide.md`](plugins/writing-polish/skills/writing-polish/references/docx-editing-guide.md)，依赖 pandoc 与 python-docx。

---

## 文件结构

```
plugins/writing-polish/
├── .claude-plugin/plugin.json        插件元数据
├── agents/
│   └── writing-reviewer.md           clean-context 审稿子代理（NL 反馈 + verdict，只评不改）
└── skills/writing-polish/
    ├── SKILL.md                      主协议（四模式 + 四阶段 + 两世界拆分）
    ├── scripts/
    │   ├── scan-ai-taste.sh          L1 硬扫（约 80 条红线，--json 输出）
    │   ├── check-cn-quotes.py        中文引号专项（scan 子调用）
    │   ├── word-count-check.sh       字数 / 句长方差
    │   ├── check-dependencies.sh     依赖检查 + 单向依赖自检
    │   └── docx-review-workflow.py   DOCX Track Changes
    ├── references/                   按需载入的判依据 / 体裁 / 方法论
    │   ├── constitution.md           五大审查焦点 + 正向实质三焦点 + G1-G8 体裁切片
    │   ├── anti-ai-taste-anchors.md  约 80 条字面红线 SSOT
    │   ├── coach-checkpoints.md      Coach 监督生成弧 checkpoint
    │   ├── renzhongran-coverage-matrix.md  任仲然 12 讲继承审计
    │   ├── reviewer-routing.md       reviewer 焦点分摊决策表
    │   └── …（体裁指南 / 方法论 / 修订清单 / 公文格式 等）
    ├── assets/                       锚本（任仲然 8 范例 + 11 篇真实公文）
    └── evals/                        离线 dev-eval harness（数值评测，不进 per-use 路径）
        ├── offline-harness/          数值判官 / few-shot 选取 / split 工具
        ├── fixtures/                 L1 回归用例
        └── calibration-set.jsonl     历史标注源
```

---

## 方法论与规范来源

写作方法论来自任仲然《怎样写作》（党建读物出版社 2019 年），任仲然曾任中组部研究室主任，40 余年公文写作与审稿经验。

中文标点依据 GB/T 15834-2011《标点符号用法》；党政公文格式依据 GB/T 9704-2012。AI 味约束清单基于 2024-2026 年中英文社区调研，主要信源含 Wikipedia《Signs of AI writing》、Originality.ai、GPTZero，以及国务院办公厅、国家信息中心、国务院发展研究中心、财政部等机关真实文件参考。

完整版本演进见 [`CHANGELOG.md`](CHANGELOG.md)。当前状态一页纸见 [`docs/status.md`](docs/status.md)。

---

## 跨平台移植

原生支持 Claude Code。其他工具复制 `SKILL.md` + `references/`（`agents/` 为 Claude Code 子代理特性，其他平台可把 reviewer 提示作为审稿指令内联）：

| 工具 | 规则目录 | 格式 |
|------|---------|------|
| Claude Code | Plugin 或 `~/.claude/skills/` | Markdown |
| Claude.ai | Skills 上传 zip | Markdown |
| Cursor | `.cursor/rules/` | `.mdc` |
| Windsurf | `.windsurf/rules/` | Markdown（12K 字符限制） |
| Copilot | `.github/instructions/` | Markdown + YAML |

---

## 相关项目

- [workflow-toolkit](https://github.com/sinnohzeng/workflow-toolkit)：开发者日常工作流 Skill 集合（已从本仓库拆分）

## License

MIT。写作方法论版权归原作者任仲然所有。

---

> 任仲然在《怎样写作》中写道：“好文稿好文章无疑是写出来的，但更重要的是改出来的。”
