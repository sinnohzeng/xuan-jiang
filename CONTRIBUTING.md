# 贡献指南 Contributing Guide

感谢你对轩匠的关注！本文档说明如何参与贡献。

Thank you for your interest in Xuan-Jiang! This guide explains how to contribute.

---

## 贡献方式 Ways to Contribute

- **报告 Bug** — 使用 [Issue 模板](https://github.com/sinnohzeng/xuan-jiang/issues/new/choose) 提交
- **功能建议** — 同样通过 Issue 提交，描述使用场景
- **贡献 Skill** — 为 writing-polish 添加新技能或方法论补强
- **改进文档** — 修正错误、补充说明

---

## Skill 编写规范 Skill Authoring Guidelines

贡献新 Skill 时，请遵循以下规范（对标 [Anthropic Agent Skills 最佳实践](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)，2026-05 口径）：

### frontmatter 字段

官方 agent-skills frontmatter 只有三个核心字段：`name`、`description`、`allowed-tools`。不要再写 `effort` / `paths`（非官方字段，旧版项目约定已废）。

- **`name`**：小写 + 数字 + 连字符，≤ 64 字符，gerund 式具体命名（如 `writing-polish`）。
- **`description`**：≤ 1024 字符，**第三人称**，含 what + when + 触发词；中文项目末尾追加中文短触发词。
- **`allowed-tools`**：显式列出该 skill 可用工具（如 `Bash, Read, Edit, Write, Task`）。

```yaml
# 正确 ✅
description: >
  Coaches, drafts, polishes, and audits Chinese documents using 《怎样写作》.
  Triggers on 润色 / 审稿 / 改稿 / 帮我写 / polish / review.

# 错误 ❌
description: Use this when you want to polish your text.   # 第二人称
```

### 子代理 Subagents

可复用的 clean-context worker（如审稿人）定义为插件 `agents/*.md`，frontmatter 含 `name` / `description` / `tools`（只读 worker 给 `Read, Bash, Grep` 即可，结构性强制「只评不改」）。主对话用 Task 工具调用。

### 拼音别名 Pinyin Aliases

- 使用完整拼音（`runse`），不用首字母缩写（`rs`）。
- 设置 `disable-model-invocation: true`（别名不应被 AI 自动触发）。
- Body 用委派模式，不复制主技能内容。

### 精简纪律

- SKILL.md body 远低于 500 行（轩匠目标 ~150）；长材料按需载入 `references/`。
- `references/` 单层引用；> 100 行的 reference 顶部加目录（TOC）。
- 先建评测后写文档（evaluation-driven）；评测在 `evals/`，不进 per-use 路径。

---

## Commit 规范 Commit Convention

本项目使用 **Chinese Conventional Commits**（中文语义化提交）：

```
<type>(<scope>): <中文描述>
```

常用 type：

| type | 用途 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档变更 |
| `refactor` | 重构（不改变功能） |
| `chore` | 构建/工具/配置 |

示例：
```
feat(writing-polish): 新增自媒体文体审查标准
fix(commit): 修复 SemVer tag 格式校验
docs: 补充跨平台安装说明
```

---

## 提交流程 Workflow

1. **Fork** 本仓库
2. **创建分支**：`git checkout -b feat/your-feature`
3. **开发并测试**：确保 Skill 在 Claude Code 中可正常触发和执行
4. **提交**：遵循上述 Commit 规范
5. **Push 并创建 PR**：描述改动内容和测试方式

---

## 中文标点规范（GB/T 15834-2011）

- 中文字符之间使用中文标点（，。；：）。
- 中文双引号**必须**用大陆国标弯引号 `"xxx"`（U+201C/U+201D），双层嵌套外双内单 `"x'y'z"`。
- **严禁** ASCII 直引号 `"xxx"`，**也严禁**直角引号 `「」` `『』`（港台/日式，大陆党政公文不用）——这正是本插件 `scan-ai-taste.sh` 会扫的红线。
- 唯一例外：代码块、URL、命令行、纯英文术语保留 ASCII。

---

## 许可 License

贡献的代码将以 [MIT](LICENSE) 许可发布。提交 PR 即表示你同意此许可条款。

Contributions are licensed under [MIT](LICENSE). By submitting a PR you agree to these terms.
