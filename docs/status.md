# 轩匠 writing-polish — 当前状态一页纸

> 单一当前状态入口。想了解「现在是什么样」看这一页；想了解「怎么演进到这」看 `CHANGELOG.md`；想看完整协议看 `SKILL.md`。

## 当前版本

**v7.0.0**（2026-05-28）— 两世界拆分 + 任仲然立文实质轴 + 文档债清零。

## 一句话

让 Claude Code 写出像人写的中文：把任仲然《怎样写作》方法论转成可执行写作 / 润色工作流，配 230 余条 AI 味红线扫描 + clean-context 审稿子代理做反馈式审校。

## 架构：评价分两个世界（v7.0 核心）

| | per-use 热路径（每次改稿） | 离线 dev-eval（改规则时） |
|---|---|---|
| 目的 | 让这一篇变好 | 衡量 polisher 本身好不好 |
| 输出 | 自然语言可执行反馈 + 粗判（够好了/要改/红线未清） | 数值逐维分 |
| 落点 | `scan-ai-taste.sh` + `agents/writing-reviewer.md` | `evals/offline-harness/` |

per-use **不打数值分**——改稿循环要的是「指到句、怎么改」的可执行反馈，数值逐维打分是离线打榜工具。

## 三种模式

- **Coach**（帮我写 / 起草）：监督生成弧 立意→构思→提纲→材料→结构，逐段 checkpoint（含事实敬畏三态）。
- **Polish**（润色 / 审稿，歧义默认）：L1 硬扫 + clean-context reviewer 按焦点给 NL 反馈 + 主对话串行改稿。
- **Audit**（快速过 / 扫一下）：脚本主导，30 秒 pass/fail。

## 四大审查焦点

立意 / 结构与论据 / 材料·事实（含事实敬畏三态）/ AI味·标点。前三个是 v7.0 新补的正向实质轴。

## 已知限制

- per-use reviewer 走 Claude Code Task 子代理特性；其他平台需把 reviewer 提示内联（见 README 跨平台表）。
- 离线 eval anchor 数据目前 9 条人工 gold（`constitution.md §5` 对应记录），覆盖够用但非全量。
- DOCX 修订模式依赖 pandoc + python-docx，需本机安装。
- 戏剧化叙事 / 大厂黑话无法机械替换（v7 刻意无 auto-fix 脚本），需把表达拉回事实陈述。

## 关键文件

- 主协议：[`SKILL.md`](../plugins/writing-polish/skills/writing-polish/SKILL.md)
- 审查判依据 SSOT：`references/constitution.md`
- 任仲然 12 讲继承审计：`references/renzhongran-coverage-matrix.md`
- 红线 SSOT：`references/anti-ai-taste-anchors.md`
- 版本演进：[`CHANGELOG.md`](../CHANGELOG.md)
- 历史归档：[`archive/`](archive/)
