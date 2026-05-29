# Memory Index

## 当前依据（current）

- [v7.0 两世界拆分](feedback_v7.0-two-world-split.md) — per-use 自然语言反馈 + 离线数值评分；为何删 per-use 评分链；补任仲然立文实质轴（立意/结构/材料）；reviewer 是只读 clean-context 子代理
- [v4.3 上下文白名单设计反思](feedback_v4.3-context-whitelist.md) — 硬词典 → 词典 + ±2 行扩窗白名单、千句密度动态阈值、过度工程边界（仍适用的方法论判断）
- [永远自动 commit+push](feedback_auto-commit-push.md) — 完成任何变更后直接 commit + push 远端，不再询问；force push / 部署敏感分支 / secrets 例外

## 历史经验（historical，不当当前依据）

> 以下记录写作当时为准，架构/字段已被后续版本改写。仅作演进回溯，**禁止当作当前技术依据**。已物理归档至 `docs/archive/claude-memory/`。

- `archive/claude-memory/feedback_v5.1-multi-agent-orchestrator.md` — v5.1 多智能体 orchestrator 设计；提到的 `config/default.yaml`、`docs/rfc`、Opus lead + Sonnet workers 数值评分链均已被 v7.0 两世界拆分取代
- `archive/claude-memory/feedback_skill-authoring.md` — 早期 SKILL 编写要点；其中 `effort` / `paths` frontmatter 字段说法与现行官方口径（name/description/allowed-tools）不一致，以 `CONTRIBUTING.md` 现行版为准
