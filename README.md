# 轩匠 Xuan-Jiang

**把专业方法论注入 AI —— 让 Claude Code 不只是写得快，而是写得对、改得准。**

轩匠（Xuan-Jiang）是一个专注于中文写作的 Claude Code 插件 marketplace。其核心插件 **writing-polish** 将任仲然 40 年公文写作方法论（《怎样写作》）转化为 AI 可执行的写作与审稿工作流，并引入 110 条硬核「去 AI 味」约束。

> **2026-04 重大重构**：仓库职责单一化。开发者工作流插件已迁出至独立仓库 [workflow-toolkit](https://github.com/sinnohzeng/workflow-toolkit)，本仓库专注写作。

---

## Quick Start

```bash
# 注册 marketplace（一次性）
claude plugin marketplace add https://github.com/sinnohzeng/xuan-jiang.git

# 安装 writing-polish
claude plugin install writing-polish@xuan-jiang
```

---

## writing-polish · 写作润色审稿

> "好文稿好文章无疑是写出来的，但更重要的是改出来的。"
> ——任仲然《怎样写作》

### 为什么需要这个 Skill

AI 能写出流畅的文字，但缺乏**审稿的专业判断力**和**根除 AI 味的内功**。它不知道什么时候该砍掉一整段「正确的废话」，不知道公文的立意要「以意役法」而非面面俱到，更分不清自己写的「赋能、闭环、抓手、深度融合、首先其次最后」就是 AI 的指纹。

writing-polish 做的事情：
1. 把《怎样写作》中沉淀的完整方法论体系——五种思维方式、立意构思方法论、七大文体专属标准、何其芳十二条修改要则——全部转化为 Claude 可以遵循的结构化工作流；
2. 引入**110 条硬核 AI 味红线 + 60 条橙线 + 15 条结构反模式**，让 Claude 改出来的稿子读起来像人写的，不像机器吐的。

**不是调 prompt 让 AI「写得更好」，而是给 AI 装上一套专业编辑的审稿操作系统 + AI 味免疫系统。**

### 三层防御

```
L1 写作前  →  Preventive：先读核心机制 + 110 红线 + 10 反例对照
L2 写作中  →  In-line：每段写完心理 grep（破折号？接住？不是 X 而是 Y？）
L3 交付前  →  Gate：scripts/scan-ai-taste.sh 自动扫描，违规阻断
```

### 两条核心工作流

```
用户请求
  │
  ├─ "帮我写 / 起草 / 搭提纲"
  │   └─ 写作辅助工作流
  │       明确任务 → 立意构思 → 搭建提纲（参考 anchor-essays 摹仿）→ 充实内容 → 语言定调
  │
  └─ "润色 / 审稿 / 帮我改"
      └─ 审稿润色工作流
          通读识别 → 结构性审查（大处着眼）→ 细节打磨（小处着手）→ AI 味自检 → 输出
```

### 七大文体支持

| 文体 | 核心标准 | 典型场景 |
|------|---------|---------|
| 规范性公文 | 政治性、规范性、操作性 | 通知、意见、报告、决议、纪要 |
| 领导讲话稿 | 「三个吃透」+ 实度/深度/高度/新鲜度/气势 | 会议讲话、动员部署 |
| 调研报告 | 「真实深高新活」六字标准 + 老石 5 项经验 | 专题调研、情况报告 |
| 述职报告 | 「三个取胜」——以事实、数据、实绩取胜 | 年度述职、考核述职 |
| 汇报 / 发言稿 | 四种子类型各有侧重 | 汇报工作、座谈发言、对照检查 |
| 随笔杂文 | 「真情智善理美」+「有料有趣有度」 | 评论、随笔、杂感 |
| 自媒体 | 「短快真实新」+ 标题术 + 开头术 | 公众号、头条、短视频文案 |

### AI 味硬约束清单（节选）

完整 110 红线见 `references/anti-ai-taste-anchors.md`。最严重 10 条：

1. **破折号** — 和 ——（一律禁用）
2. **括号内插入式补充** "xxx（即 yyy）"、"xxx（如 a、b、c）"
3. **客服腔**：接住、共情、看见你
4. **公文黑话**：赋能、重塑、闭环、抓手、链路、打造、助力、切实推动、深度融合
5. **翻译腔**：在某种意义上说、在...的背景下、不可磨灭的
6. **三段式套壳**：首先...其次...最后
7. **套话连接词**：值得注意的是、综上所述、由此可见
8. **情感空话**：令人印象深刻、至关重要、充满活力、蓬勃发展
9. **否定平行三连**：不是 X 而是 Y / 不仅...更是
10. **段尾分词挂总结**：…，体现了 X / 反映了 Y / 彰显了 Z

### 使用方式

调用命令：`/writing-polish` 或拼音别名 `/runse`

```
# 写作辅助
帮我写一篇关于安全生产的讲话稿
搭个提纲，主题是数字化转型

# 审稿润色
帮我润色这篇文章
审稿 /path/to/speech.docx

# DOCX 修订模式
用修订模式帮我改 /path/to/document.docx

# English works too
polish this article for me
```

### 前置依赖（可选）

```bash
# DOCX 读取
brew install pandoc         # macOS
apt install pandoc          # Ubuntu/Debian

# DOCX 编辑（Track Changes 修订模式）
pip install docx-editor python-docx
```

不安装也能用——纯文本和 Markdown 无需任何依赖，DOCX 依赖仅在需要读取或回写 Word 文档时才用到。

---

## 跨平台安装

原生支持 Claude Code。其他 AI 编程工具可直接复制 `SKILL.md` 和 `references/` 目录：

| 工具 | 规则目录 | 格式 |
|------|---------|------|
| Claude Code | Plugin 或 `~/.claude/skills/` | Markdown |
| Claude.ai | Skills 上传 zip | Markdown |
| Cursor | `.cursor/rules/` | `.mdc`（Markdown + YAML frontmatter） |
| Windsurf | `.windsurf/rules/` | Markdown（12K 字符限制） |
| Cline | `.clinerules/` | Markdown |
| Copilot | `.github/instructions/` | Markdown + YAML |

---

## 方法论来源

写作方法论全部来自 **《怎样写作》**（任仲然著，党建读物出版社，2019 年）。任仲然曾任中组部研究室主任，40 余年公文写作与审稿经验凝结为这部方法论体系。

「去 AI 味」约束清单基于 2024-2026 年中英文社区共识整理，主要信源：
- [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)
- [Originality.ai 千万词级语料分析](https://originality.ai/blog/can-humans-detect-chatgpt)
- 国务院办公厅、国家信息中心、国务院发展研究中心、财政部等权威机关真实文件锚本

---

## 相关项目

- [workflow-toolkit](https://github.com/sinnohzeng/workflow-toolkit) — 开发者日常工作流 Skill 集合（已从本仓库拆分）

## License

MIT. 写作方法论版权归原作者任仲然所有。

---

> "写作不是文字的简单排列组合，而是思想的创造和精神的奉献。"——任仲然
