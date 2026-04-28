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

贡献新 Skill 时，请遵循以下规范（对标 [Anthropic 官方最佳实践](https://docs.anthropic.com/en/docs/claude-code/skills)）：

### `description` 字段

- 使用**第三人称**：`"Commits and pushes staged changes..."` 而非 `"Use when you want to commit..."`
- 前 250 字符必须包含所有核心触发词（技能列表展示时会截断）
- 上限 1024 字符，建议控制在 800 以内
- 中文项目：末尾追加中文短触发词以提高自动触发匹配率

```yaml
# 正确 ✅
description: >
  Commits and pushes staged changes with Chinese Conventional Commits.
  提交代码并推送到远端。

# 错误 ❌
description: >
  Use this when you want to commit your code.
```

### `effort` 字段

每个技能必须显式设置，不依赖默认值：

| effort | 适用场景 |
|--------|---------|
| `max` | 运行测试、迭代调试、复杂分析 |
| `high` | 多文件扫描 |
| `medium` | 反思类、分析类 |
| `low` | 纯流程化操作、别名委派 |

### 拼音别名 Pinyin Aliases

- 使用完整拼音（`tijiao`），不用首字母缩写（`tj`）
- 设置 `disable-model-invocation: true`（别名不应被 AI 自动触发）
- Body 用委派模式，不复制主技能内容：

```markdown
请调用 /workflow-toolkit:commit skill 来完成提交。
```

### 其他字段

- **`paths`** — 文件类型相关的技能应限定激活范围（如 `"**/*.docx, **/*.md"`）
- **动态上下文** — 有 git 操作的技能应注入 `!git status` 等命令

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

## 中文标点规范

- 中文字符之间使用中文标点（，。；：""）
- 严禁在中文之间使用英文直引号 `""`
- 中文双引号使用 `"xxx"` 或 `「xxx」`

---

## 许可 License

贡献的代码将以 [MIT](LICENSE) 许可发布。提交 PR 即表示你同意此许可条款。

Contributions are licensed under [MIT](LICENSE). By submitting a PR you agree to these terms.
