# 跨工具对照记录（v4.2 立项调研）

> 本文档沉淀 2026-04-28 v4.2 立项前用 Firecrawl 抓取的 6 份对照资料的关键摘要与 v4.2 维度比较，以及季度续抓办法。
>
> 本文件含元论述（列举规则名、信源链接、外部工具名），scan-ai-taste.sh 会跳过整文扫描。

<!-- scan-skip -->

## 调研动机

v4.1 完成后做独立第三方核验，发现规则覆盖度领先但 frontmatter 标准件、闭环工程化、Wikipedia 长尾词典三个维度未与官方 BP 对齐。需要明确 v4.1 的真实定位与 v4.2 改进方向。

## 信源清单

| 来源 | 类型 | 用途 |
|---|---|---|
| https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices | Anthropic 官方文档 | Skill authoring 标准件、progressive disclosure、evals 三模型矩阵 |
| https://github.com/anthropics/skills | Anthropic 官方仓库 | 范例 skill 写法、文件组织 |
| https://github.com/obra/superpowers/blob/main/skills/writing-skills/anthropic-best-practices.md | obra/superpowers | 第三方实现 best practices |
| https://github.com/yaoleifly/wechat-writing-style | 同类中文 SKILL | 微信公众号写作 |
| https://github.com/PenglongHuang/chinese-novelist-skill | 同类中文 SKILL | 中文小说创作（含 Phase 0 / Phase 4 自动补救机制） |
| https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing | Wikipedia 完整版 | AI 味识别清单、Reference markup bugs、Placeholder dates 等长尾 |

## 维度对比（v4.2 落地后）

| 维度 | v4.1 | v4.2 | 官方 / 同类 | v4.2 状态 |
|---|---|---|---|---|
| 规则总数 | 199（124+60+15） | 233（156+60+17） | 多数 20 至 80 | 领先 |
| 自动 scan 闸门 | 双脚本 | 双脚本 + auto-fix-loop + suggest-fix | 几乎无 | 领先 |
| 真实文件参考库 | 8 范例 + 5 真实文件 | 同（v4.2 计划单独抓取扩到 10 至 12，留作下一批) | 极少 | 领先 |
| Frontmatter 含 effort 字段 | ✓ | ✓ | ✓ | 持平 |
| Progressive disclosure 分离 reference | ✓ | ✓ | ✓ | 持平 |
| SKILL.md 顶部快速导航 | 无 | ✓ §0 快速导航表 | 官方 BP 推荐 | 已对齐 |
| Reference 文件 TOC | ✓ | ✓ | 要求 | 持平 |
| 失败 case 库 | 无 | ✓ failure-cases.md 5 case | chinese-novelist 有 | 已对齐 |
| 自动补救循环 | 无 | ✓ auto-fix-loop.sh 1 至 2 轮 | chinese-novelist Phase 4 | 已对齐 |
| 依赖检查脚本 | 无 | ✓ check-dependencies.sh | 官方 BP 推荐 | 已对齐 |
| evals 含反向用例 | 无 | ✓ test-13 至 15 三条反向 | 官方 BP 要求 | 已对齐 |
| evals 颗粒度 | 5 条 | 20 条含 tags / version | 官方 BP 推荐 | 已对齐 |
| Wikipedia 长尾覆盖 | 头部 | ✓ §1.7 八类（oaicite / xx-xx / elegant variation 等） | 完整词表 | 已对齐 |
| 英文红线词数量 | 30 红 + 25 橙 | 50 红 + 25 橙 | originality.ai 200+ | 仍落后但已显著扩 |
| 客服话术 / 元注释 | 无 | ✓ §1.6 五类 20 条 | Wikipedia 间接覆盖 | 已对齐 |
| 中文国标引用 | GB/T 15834 + GB/T 9704 | 同 | 几乎无同行 | 领先 |
| dogfooding | SKILL.md 部分自违规 | ✓ 主体清零，仅元论述段豁免 | 罕见 | 显著改进 |

## 综合定位

v4.2 完成后，v4.2 在中文写作 Claude Skill 头部位置进一步巩固，与 Anthropic 官方 BP 在标准件层面已基本对齐。剩余差距：

1. **英文红线长尾**：originality.ai 1000+ 词级的覆盖暂时不补（与中文场景关联度低）
2. **真实文件参考库扩到 10 至 12 个**：留作下一批用 Firecrawl 单独抓取，保留 v4.1 的 5 个不变
3. **工作流图示**：朴实文风原则下不补
4. **跨会话偏好系统**：用户全局 CLAUDE.md 已含 auto memory，不重复造轮子
5. **并行写作模式**：用户全局 CLAUDE.md 明禁，不采纳

## 季度续抓办法

v4.2 之后每季度（4 月、7 月、10 月、1 月）跑一次以下命令复查信源是否更新：

```bash
# 1. Wikipedia AI 写作识别清单（看是否新增章节）
firecrawl scrape "https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing" \
    -o /tmp/fc-wp-aiwriting-q$(date +%Y-Q%q).md --format markdown

# 2. Anthropic 官方 Skill BP 文档（看是否更新规范）
firecrawl scrape "https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices" \
    -o /tmp/fc-anthropic-bp-q$(date +%Y-Q%q).md --format markdown

# 3. anthropics/skills 官方仓库（看是否新增写作类范例）
firecrawl scrape "https://github.com/anthropics/skills" \
    -o /tmp/fc-anthropics-q$(date +%Y-Q%q).md --format markdown

# 4. 中文 SKILL 生态（看是否有新对手出现）
firecrawl search "claude skills 中文 写作" --limit 10 \
    -o /tmp/fc-cn-skills-q$(date +%Y-Q%q).json --json
```

发现新条目或新对手时，把摘要追加到本文档的"维度对比"表，启动 v4.X 立项。

## 备份位置

本次抓取的 6 份原始材料：

- /tmp/fc-anthropic-bp-doc.md
- /tmp/fc-best-practices.md
- /tmp/fc-anthropics-skills-repo.md
- /tmp/fc-wechat-writing.md
- /tmp/fc-novelist.md
- /tmp/fc-wp-aiwriting.md

属本机临时文件，仅用于本次调研。后续季度复查时重新抓取最新版即可。

<!-- /scan-skip -->
