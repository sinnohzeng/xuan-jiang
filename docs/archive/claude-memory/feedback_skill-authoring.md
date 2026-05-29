---
name: Skill Authoring Best Practices (Anthropic 官方对标)
description: 2026-04 对标 Anthropic 官方 Skill Authoring Best Practices 后沉淀的实操经验
type: feedback
---

## SKILL.md 编写要点

### description 字段
- 必须用**第三人称**（"Commits and pushes..."），不用第二人称（"Use when..."）
- 前 250 字符必须包含所有核心触发词，因为技能列表展示时会截断到 250 字符
- 上限 1024 字符，建议控制在 800 以内留安全余量
- 中文用户项目：末尾追加中文短触发词（如"提交代码并推送到远端。"）提高自动触发匹配率

**Why:** 官方文档明确要求第三人称，因为 description 被注入 system prompt，第二人称会混淆 Claude 的指令理解。

**How to apply:** 每次新建或修改 SKILL.md 时，检查 description 是否以动词第三人称开头。

### effort 字段
- 每个技能都应显式设置 effort，不要依赖默认值
- 参考：`max`=运行测试/迭代调试/复杂分析，`high`=多文件扫描，`medium`=反思类，`low`=纯流程化操作

### 动态上下文注入 `!command`
- 有 git 操作的技能应注入 `!git status` / `!git diff --name-only HEAD` 等
- 有构建系统检测需求的技能应注入 `!ls package.json Makefile pyproject.toml 2>/dev/null`

### 别名技能（alias）
- `disable-model-invocation: true` 是正确的（别名是键盘快捷方式，不应被自动触发）
- body 必须用委派模式（"请调用 /xxx skill"），不复制主技能内容，避免内容漂移
- 完整拼音优于首字母缩写：认知收益（零中英翻译开销）> 击键收益

### paths 字段
- 文件类型相关的技能应设置 paths 限定激活范围
- 示例：`paths: "**/*.docx, **/*.md, **/*.txt"`
