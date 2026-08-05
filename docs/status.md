# 轩匠 writing-polish：当前状态一页纸

> 单一当前状态入口。想了解“现在是什么样”看这一页；想了解“怎么演进到这”看 `CHANGELOG.md`；想看完整协议看 `SKILL.md`。

## 当前版本

**v10.1.0**（2026-08-04）。本次四件事：机械层收缩（硬红线只保留无歧义集，8 个公文合法词 / 破折号 / 三段式降级为软 WARN）、四源词表漂移修复（anchors §1.1 成唯一 SSOT + 一致性哨兵脚本）、吸收 human-writing（MIT）理念层（七遍改稿补强 + 材料门槛量化）、清理 1.1MB legacy 死重。

## 一句话

让 Claude Code 写出像人写的中文：把任仲然《怎样写作》方法论转成可执行写作 / 润色工作流，配无歧义硬红线 + 软信号的 AI 味扫描（语境判断交 clean-context 审稿子代理），动笔之前先核实读者是谁、我方是谁、经由什么媒介接收。

## 架构：评价分两个世界

| | per-use 热路径（每次改稿） | 离线 dev-eval（改规则时） |
|---|---|---|
| 目的 | 让这一篇变好 | 衡量 polisher 本身好不好 |
| 输出 | 自然语言可执行反馈与粗判（够好了/要改/红线未清） | 数值逐维分 |
| 落点 | `scan-ai-taste.sh` 与 `agents/writing-reviewer.md` | `evals/offline-harness/` |

per-use **不打数值分**。改稿循环要的是“指到句、怎么改”的可执行反馈，数值逐维打分是离线打榜工具。

## 四阶段流水线（全模式）

| 阶段 | 内容 |
|---|---|
| **P0 定站位** | 站位四问：读者是谁 / 我是谁 / 媒介与文体 / 第二受众；命中特定场景加载 `references/scenarios/` 场景包 |
| **P1 预处理** | L1 硬扫（红线脚本）与体裁判定 |
| **P2 润色** | 按五焦点改稿 |
| **P3 评审** | clean-context reviewer 按焦点给 NL 反馈，主对话串行落地 |

## 四种模式

- **Coach**（帮我写 / 起草）：监督生成弧，依次过立意、构思、提纲、材料、结构，逐段 checkpoint（含事实敬畏三态）。
- **Polish**（润色 / 审稿，歧义默认）：L1 硬扫后由 clean-context reviewer 按焦点给 NL 反馈，主对话串行改稿。
- **Audit**（快速过 / 扫一下）：脚本主导，30 秒 pass/fail，一行式站位确认。
- **Express**（短稿 / 消息 / 邮件）：轻量模式，站位一行确认与字面红线快扫。

## 五大审查焦点

口吻与站位（第一顺位）/ 立意 / 结构与论据 / 材料·事实（含事实敬畏三态）/ AI味·标点·翻译腔。

## v10.1 新增要点

- **机械层收缩**：硬红线只保留无歧义集（CN_HARD 15→7 词）；切实推动/提质增效/深度融合/打造/助力/多维度/体系化/重塑 8 个公文合法词、破折号、首先/其次/最后三段式降为软 WARN 交 reviewer 语境判断；密度提示仅报不令改（防 Goodhart）。
- **词表唯一 SSOT**：`anti-ai-taste-anchors.md` §1.1 是硬禁词唯一权威源；SKILL.md / reviewer 内嵌词表改指针；`scripts/check-rule-consistency.sh` 机械校验文档—脚本一致（吸收 human-writing（MIT）revision.md 契约）。
- **判据层吸收**：`revision-checklist.md` 七遍改稿补强、`coach-checkpoints.md` 材料门槛量化，均注明 human-writing（GitHub，MIT）出处；形状检测族脚本不吸收（形状判断交 reviewer）。
- **删除**：fix_word 逐词替换建议表、GENRE=auto 占位分支、anchors §6 阈值双写表、evals/legacy/。

## v10.0 新增要点

- **站位四问**：任何写作或润色前先核实读者是谁、我是谁、媒介与文体（会场口播 / 纸面印发 / 屏幕扫读 / 微信即时通讯 / 机器解析）、有无第二受众。方法论出处：任仲然《怎样写作》第七讲受众三问。
- **读者谱系扩非工作场景**：站位矩阵补部门内熟人、跨部门、家人朋友、自媒体读者、面向软件系统五类。
- **听众反应预演**（G2 党课 / 领导讲话门控）：逐句问“台下的人听了会怎么想、会不会多想”，含稿件血统溯源闸门。
- **场景包**：`references/scenarios/`（party-lecture.md、familiar.md），新增场景即新增一个文件并在矩阵加一行。

## 已知限制

- per-use reviewer 走 Claude Code Task 子代理特性；其他平台需把 reviewer 提示内联（见 README 跨平台表）。
- 离线 eval anchor 数据目前为人工 gold（`constitution.md §5` 对应记录），覆盖够用但非全量。
- DOCX 修订模式依赖 pandoc 与 python-docx，需本机安装。
- 戏剧化叙事 / 大厂黑话无法机械替换（刻意无 auto-fix 脚本），需把表达拉回事实陈述。

## 关键文件

- 主协议：[`SKILL.md`](../plugins/writing-polish/skills/writing-polish/SKILL.md)
- 审查判依据 SSOT：`references/constitution.md`
- 站位与口吻 SSOT：`references/stance-and-register.md` 与 `references/scenarios/`
- 任仲然 12 讲继承审计：`references/renzhongran-coverage-matrix.md`
- 红线 SSOT：`references/anti-ai-taste-anchors.md`
- 版本演进：[`CHANGELOG.md`](../CHANGELOG.md)
- 历史归档：[`archive/`](archive/)
