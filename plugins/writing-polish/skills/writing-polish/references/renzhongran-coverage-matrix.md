<!-- scan-skip -->
# 任仲然《怎样写作》12 讲继承覆盖矩阵

> 审计元文档：把原书 12 讲逐讲映射到「SKILL 行为 → reference 落点 → offline eval task」，让继承度可逐原则审计，而非笼统宣称百分比。
> 含历史规则名 / 示例词 / 体裁标签，`scan-ai-taste.sh` 跳过本文件正文。
> 原书 12 讲标题取自仓库根 `《怎样写作》任仲然.md`（逐字核对）。

## 目录

- §1 覆盖矩阵（12 讲 × 4 列）
- §2 覆盖说明（强 / 部分 / 暂不实现）
- §3 项目延伸（非原书）

## §1 覆盖矩阵

| 讲 | 原书主题 | SKILL 行为 | reference 落点 | offline eval / fixture |
|---|---|---|---|---|
| 第一讲 写作其实并不难 | 观察、阅读、摹仿、制造、创造；愿意写大胆写经常写 | Coach「教我写作」技能弧（摹仿→制造→创造）；Coach 生产弧 §0 准备读锚本 | [`writing-coaching-arc.md`](writing-coaching-arc.md) + [`../assets/anchor-essays/`](../assets/anchor-essays/) | —（培养类，难自动评） |
| 第二讲 思维逻辑规律 | 五种思维、哲学悟性、建立关系、逻辑延展、规律再造 | reviewer「结构与论据」焦点（概念一致 / 判断有据 / 推理严密 / 因果不倒置） | [`writing-methodology.md`](writing-methodology.md) 一 + [`logic-and-structure.md`](logic-and-structure.md) + [`constitution.md`](constitution.md) §0.5 焦点二 | fixtures 结构/逻辑类（待补） |
| 第三讲 立意构思提纲 | 立意要高深（反「全而又全」）、构思选小切口、提纲早出手 | reviewer「立意」焦点；Coach 生产弧 §1-§3 立意/构思/提纲 checkpoint | [`writing-methodology.md`](writing-methodology.md) 二三四 + [`coach-checkpoints.md`](coach-checkpoints.md) §1-§3 + [`constitution.md`](constitution.md) §0.5 焦点一 | calibration「立意散/全而又全」类（待标注） |
| 第四讲 材料结构语言 | 货真价实材料、解剖麻雀换白鼠、纵横捭阖结构、朴实睿智语言 | reviewer「材料·事实」（事实敬畏三态）+「结构与论据」+「AI味·标点」（朴实）；Coach §4 素材清单 | [`writing-methodology.md`](writing-methodology.md) 五六 + [`constitution.md`](constitution.md) §0.5 焦点三 + [`anti-ai-taste-anchors.md`](anti-ai-taste-anchors.md) + [`coach-checkpoints.md`](coach-checkpoints.md) §4 | fixtures: long/short-form-density；calibration 模糊副词/编造类 |
| 第五讲 叙述议论说明 | 三种表达方式；五种论证法（归纳/演绎/类比/因果/举例）；比喻形象说理 | reviewer「结构与论据」焦点判论证方法；「材料·事实」判事例支撑 | [`writing-methodology.md`](writing-methodology.md) 七 + [`logic-and-structure.md`](logic-and-structure.md) | —（论证质量，离线人工抽检） |
| 第六讲 规范性公文 | 政治性/规范性/指导性；一事一请示一题一报告 | Polish 体裁 G1 切片；reviewer 注入 G1 追加红线 + 保留项 | [`genre-guide.md`](genre-guide.md) + [`gongwen-format.md`](gongwen-format.md) + [`constitution.md`](constitution.md) §2.1 | fixtures: gov-duibiao；calibration G1 段 |
| 第七讲 领导讲话稿 | 三个吃透 + 五维度（实/深/高/新鲜/气势）；宜短不宜长 | Polish 体裁 G2 切片 | [`genre-guide.md`](genre-guide.md) + [`constitution.md`](constitution.md) §2.2 | calibration G2 段 |
| 第八讲 调研报告 | 真实深高新活六字；数据驱动；点名式归因 | Polish 体裁 G3 切片；reviewer「材料·事实」雷达（§6.1） | [`genre-guide.md`](genre-guide.md) + [`citation-spec.md`](citation-spec.md) + [`constitution.md`](constitution.md) §2.3 + §6.1 | calibration G3 段 |
| 第九讲 述职报告 | 以实/以数/以事和绩三取胜 | Polish 体裁 G4 切片 | [`genre-guide.md`](genre-guide.md) + [`constitution.md`](constitution.md) §2.4 | calibration G4 段 |
| 第十讲 汇报稿和发言稿 | 信息透明 + 重点突出 + 时间精确 | Polish 体裁 G5 切片 | [`genre-guide.md`](genre-guide.md) + [`constitution.md`](constitution.md) §2.5 | calibration G5 段 |
| 第十一讲 随笔、杂文及自媒体 | 留犹豫/偏执/具体/人称；抓眼球 + 信息密度 + 个人视角 | Polish 体裁 G6 / G7 切片（G7 网络口语降软警告，黑话仍硬红线） | [`genre-guide.md`](genre-guide.md) + [`constitution.md`](constitution.md) §2.6 / §2.7 | calibration G6/G7 段 |
| 第十二讲 修改文稿文章经验谈 | 热写冷改、先大后小、先减后加、改自己 vs 改他人（他批） | Polish step 3 修改哲学 + reviewer「他批」礼貌；冷读/念改 | [`peer-vs-self-revision.md`](peer-vs-self-revision.md) + [`revision-checklist.md`](revision-checklist.md) + SKILL.md §6 修改哲学 | —（流程类） |

## §2 覆盖说明

- **强继承**：第三讲（立意，新增 reviewer 焦点 + Coach checkpoint）、第四讲（材料·事实敬畏三态 + 朴实语言）、第六~十一讲（六体裁切片）、第十二讲（他批 + 修改哲学）。
- **部分继承**：第二讲（思维落到「结构与论据」焦点，但五种思维未逐一独立操作化）、第五讲（论证方法在 reviewer 提示里，未做独立检查项）。
- **暂不实现（有意）**：第一讲的「观察日志/阅读积累」属长期习惯培养，工具只在 Coach §1 提示，不强制；这是边界而非遗漏。
- **v7.0 关键补强**：相比 v6（D1-D5 全是防 AI 味负向检测），v7 把第三、四讲的「立意 / 材料·事实 / 结构」升为 reviewer 一等审查焦点（[`constitution.md`](constitution.md) §0.5），并把第一~五讲的生成方法落成 Coach 监督弧（[`coach-checkpoints.md`](coach-checkpoints.md)）——「写作」侧也进入大模型监督，不再只监督「润色」侧。

## §3 项目延伸（非原书）

- **G8 第三方咨询报告**：cicpa 治理沉淀，非《怎样写作》原书体裁，但沿用原书方法论框架。详 [`constitution.md`](constitution.md) §2.8。
- **230 余条 AI 味红线**：对应原书「朴实语言」精神的工程化扩展，信源为 Wikipedia《Signs of AI writing》等当代语料，非原书内容。详 [`anti-ai-taste-anchors.md`](anti-ai-taste-anchors.md)。
<!-- /scan-skip -->
