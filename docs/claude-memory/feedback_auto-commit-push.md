---
name: auto-commit-push
description: "永远自动 commit + push（用户 2026-05-28 明示）——完成任何代码/文档变更后无需再问\"要不要 commit / push\"，直接 commit + push 远端。"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 18343745-bb57-4b8e-8db3-1722c36861a9
---

完成任何代码 / 文档 / 配置变更后，**直接 commit + push 远端**，不再询问。

**Why：** 用户 2026-05-28 在 writing-polish v6.1 release 时明示「永远自动 Commit+Push」。Cognition / Anthropic 的 commit-push-pr workflow 实践也支持 "trust-but-verify"：commit message + diff 已足够事后审计，不必每次都确认。

**How to apply：**

- 代码 / 文档 / 配置类的变更，commit 后立即 `git push`（不打 `--force` / `--no-verify` 除非用户明示）
- 多个相关改动可以一次性 squash 成单 commit，但不要 amend 已 push 的 commit
- 仅以下情况仍需先确认再推：
  - 推 main/master 分支前涉及 force push（`git push -f` / `git push --force-with-lease` 推共享分支）
  - 推会触发线上部署的分支（如 prod / release）
  - 推到不熟悉的远端（新 origin / fork）
  - 推会发布 release artifact（tag push 到 marketplace 类）
  - commit 涉及 .env / secrets 类敏感文件
- 跨仓 SSOT 同步（如 cicpa 引用 writing-polish 版本号）也是 commit + push，不再问

**与 [[claude-md-discipline]] / [[dialogue-handoff-protocol]] 的关系：** 本规则不改变"文档债零容忍"——commit 后该跨仓同步的依然要跨仓同步，只是不再多问一次"要不要 push"。
