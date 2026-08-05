# Memory Index

## 当前依据（current）

- [v10.1 机械层收缩与文档—脚本一致契约](feedback_v10.1-contraction-consistency.md) — 硬红线只保留无歧义集，语境判断交 reviewer；anchors §1.1 唯一 SSOT + check-rule-consistency.sh 校验；密度提示仅报不令改（防 Goodhart）
- [v10.0 站位四问前置与场景包](feedback_v10.0-stance-first-scenarios.md) — 站位四问为全模式第一环节；读者谱系扩非工作场景；G2 听众反应预演与稿件血统溯源闸门；scenarios 场景包 progressive disclosure
- [v7.0 两世界拆分](feedback_v7.0-two-world-split.md) — per-use 自然语言反馈 + 离线数值评分；为何删 per-use 评分链；补任仲然立文实质轴（立意/结构/材料）；reviewer 是只读 clean-context 子代理
- [v4.3 上下文白名单设计反思](feedback_v4.3-context-whitelist.md) — 硬词典 → 词典 + ±2 行扩窗白名单、千句密度动态阈值、过度工程边界（仍适用的方法论判断）
- [永远自动 commit+push](feedback_auto-commit-push.md) — 完成任何变更后直接 commit + push 远端，不再询问；force push / 部署敏感分支 / secrets 例外

## 历史经验（historical，不当当前依据）

> 以下记录写作当时为准，架构/字段已被后续版本改写。仅作演进回溯，**禁止当作当前技术依据**。已物理归档至 `docs/archive/claude-memory/`。

- `archive/claude-memory/feedback_v5.1-multi-agent-orchestrator.md` — v5.1 多智能体 orchestrator 设计；提到的 `config/default.yaml`、`docs/rfc`、Opus lead + Sonnet workers 数值评分链均已被 v7.0 两世界拆分取代
- `archive/claude-memory/feedback_skill-authoring.md` — 早期 SKILL 编写要点；其中 `effort` / `paths` frontmatter 字段说法与现行官方口径（name/description/allowed-tools）不一致，以 `CONTRIBUTING.md` 现行版为准
