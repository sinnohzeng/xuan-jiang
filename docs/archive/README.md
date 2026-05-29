# docs/archive — 历史归档

这里存放已不代表当前版本的历史文档。**保留而非删除**的理由：记录决策演进、便于回溯「为什么当初这么做、后来为什么改」。

> ⚠️ 归档文档按写作当时的状态记录，**不代表当前文件 / 架构仍然存在**。当前状态以根目录 `README.md`、`docs/status.md`、`SKILL.md` 为准。

## 保留策略

- 归档不删除（除非内容已被完全证伪且无回溯价值）。
- 文件名前缀加日期（`YYYYMMDD-`）便于按时间排序。
- 当前态文档若引用归档内容，必须标注「历史」字样，不得当作当前依据。

## 内容索引

### handoff/ — 历史对话交接

| 文件 | 时期 | 说明 |
|---|---|---|
| `v4.1-review-prompt.md` | v4.1 | 早期 review prompt 草样 |
| `20260520-v5-sprint1-foundation-shipped.md` | v5 sprint1 | 模型解耦三层 hybrid 地基 |
| `20260520-v5-sprint1-shipped.md` | v5 sprint1 | sprint1 发布交接 |
| `20260522-v5-sprint2-prompt-iteration-fail.md` | v5 sprint2 | prompt 迭代失败复盘（已被 v6/v7 路线取代） |
| `20260527-v5.1-multi-agent-implementation.md` | v5.1 | 多智能体实现交接 |

### research/ — 历史调研

| 文件 | 时期 | 说明 |
|---|---|---|
| `20260428-v4.2-cross-skill-benchmark.md` | v4.2 | 跨 skill 基准调研（结论已并入后续版本设计） |

### claude-memory/ — 过期项目记忆

| 文件 | 说明 |
|---|---|
| `20260522-v5-sprint2-next-dialogue-input.md` | v5 sprint2 下一对话输入（早已过期，不再是 active） |
| `feedback_v5.1-multi-agent-orchestrator.md` | v5.1 多智能体 orchestrator 设计（提到的 `config/default.yaml`、`docs/rfc` 已不存在；v7.0 两世界拆分已改写其结论，仅作历史经验保留） |
| `feedback_skill-authoring.md` | 早期 SKILL 编写要点（`effort`/`paths` frontmatter 字段说法与现行官方口径不一致，已被 CONTRIBUTING.md 现行版取代） |
