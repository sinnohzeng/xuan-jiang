# 触发 / 路由校准 harness（离线，人在环手动跑）

> **这是校准用例清单 + 结果模板，不是 CI 自动测**。技能能否被正确唤起、歧义词能否路由到正确 mode，取决于 `SKILL.md` 的 `description` 与 §1 触发表，只能靠开新会话逐条贴、看实际行为记录。改了 description 或 §1 触发表后跑一遍，把结果连同日期与被测 description 版本号追加到文末结果区。

## 目录

- [为什么手动跑](#为什么手动跑)
- [轴 A：技能调用轴（should-fire / should-not-fire）](#轴-a技能调用轴should-fire--should-not-fire)
- [轴 B：mode 路由轴](#轴-bmode-路由轴)
- [reviewer 判词稳定性抽检（承接 WS-1 的 L3 下沉）](#reviewer-判词稳定性抽检承接-ws-1-的-l3-下沉)
- [跑法](#跑法)
- [结果区（每次校准追加一节）](#结果区每次校准追加一节)

## 为什么手动跑

技能唤起是 Claude 读 `description` 后的非确定性决策，没有确定性闸可断。硬写一个“自动测触发”的脚本只会 bit-rot（它测不到真实唤起，只会给人“已覆盖”的假象）。所以本轴诚实地靠人跑，宁可慢、不可假。轴 B 的 mode 路由是 SKILL body 内的逻辑判断，相对可复现，但同样以人贴用例为准。

## 轴 A：技能调用轴（should-fire / should-not-fire）

方法：官方“开 vs 停 skill”全新会话法。开一个新会话贴输入，看 writing-polish 是否被唤起。should-fire 期望唤起，should-not-fire 期望**不**唤起（防过度触发）。

| # | 输入（用户原话样例） | 期望 | 依据 |
|---|---|---|---|
| A1 | 帮我润色这段年终总结 | fire | 润色 |
| A2 | 审一下这份调研报告 | fire | 审稿 |
| A3 | 这段读着像 AI 写的，帮我去味 | fire | 去 AI 味热词（v8 新增） |
| A4 | 帮我把这段的 AI 感去掉 | fire | AI 感热词（v8 新增） |
| A5 | 帮我写一篇述职报告 | fire | 帮我写 → Coach |
| A6 | 起草一份会议通知 | fire | 起草 → Coach |
| A7 | 快速过一下有没有 AI 味 | fire | 快速过 → Audit |
| A8 | 把这份 Word 里的公文改一改 | fire | DOCX 修订 + 改稿 |
| A9 | 把这段中文翻译成英文 | **no-fire** | description 排除：translation |
| A10 | review 一下我这段 Python 代码 | **no-fire** | description 排除：code review |
| A11 | Help me polish this English essay | **no-fire** | description 排除：English-only writing |
| A12 | 今天天气怎么样 | **no-fire** | 无关，防泛触发 |

## 轴 B：mode 路由轴

前提：技能已触发。固定输入 → 断言落到哪个 mode。歧义词（帮我看看 / 改一改）走 §1.2 字数分档。此轴测 SKILL body 逻辑，不需开 / 停技能。

| # | 输入 + 稿件条件 | 期望 mode | 依据 |
|---|---|---|---|
| B1 | 润色这段（800 字） | Polish | 明示触发词 |
| B2 | 帮我写这篇（无稿） | Coach | 生成弧 |
| B3 | 快速过一下（1200 字） | Audit | 明示 checkpoint |
| B4 | 帮我看看（400 字） | Audit | 歧义词 + 短稿档（< 500） |
| B5 | 帮我看看（1500 字） | Polish | 歧义词 + 标准档（500-3000） |
| B6 | 改一改（6000 字） | Polish（分段） | 歧义词 + 长稿档（> 3000） |
| B7 | 帮我润色这篇随笔（G6，且说“写得像我”） | Polish + 声音匹配层 | §2.5 门控 G6/G7 开 |
| B8 | 帮我润色这份公文（G1，说“写得像我”） | Polish，**声音匹配跳过** | §2.5 门控 G1-G5 关 |

> B7/B8 注意：其判定前置是把稿件分类为 G6 还是 G1，而**体裁分类是非确定性 LLM 判断**（与轴 A 同类，非可推演的 body 逻辑）。跑这两条时须**先固定 / 预标体裁**再测路由，否则复现性等同轴 A，不属“当前会话可稳定推演”那部分。

## reviewer 判词稳定性抽检（承接 WS-1 的 L3 下沉）

WS-1 把 G8 咨询报告的单次否定平行（`不仅 X 更是 Y`）从 L1 硬判下沉到 L3 reviewer 语义判断。**此项属判断轴、非机器可断**，只作稳定性跟踪，不设硬门。

| # | 输入切片 | 期望 reviewer verdict | 性质 |
|---|---|---|---|
| R1 | G8 咨询报告里一句“该方案不仅提升效率，更是重塑治理逻辑” | L3 判为**要改**（否定平行在咨询体裁串味） | 非确定性 LLM 判断，抽检不作硬闸 |

跑法：按 Polish Protocol spawn 一个 `writing-reviewer`（focus = AI味·标点 + 材料·事实），注入该切片 + G8 体裁切片，看 verdict 是否稳定命中“要改”。连续 3 次同输入至少 2 次命中即视为稳定；低于则回看 constitution G8 切片是否需补语境，而非改本用例。

## 跑法

1. 开全新会话（轴 A / R1）或直接在当前会话按 SKILL 逻辑推演（轴 B）。
2. 逐条贴输入，记录实际行为（fired / mode / verdict）。
3. 与期望比对，标 ✅ / ❌。
4. 把整轮结果连同**当日日期**与**被测 `description` 版本**（取 plugin.json version）追加到下方结果区。
5. 出现 ❌ 时：轴 A 回看 description 触发词 / 排除项是否需补；轴 B 回看 §1.2 字数档；R1 回看 constitution G8 切片。改完重跑，不改用例迁就实现。

## 结果区（每次校准追加一节）

> 模板（复制一节填写）：
>
> ### 校准 YYYY-MM-DD · description v<plugin.json version>
> - 轴 A：A1-A12 通过 X/12，未过项：<列 # + 实际行为>
> - 轴 B：B1-B8 通过 X/8，未过项：<列 #>
> - R1 稳定性：3 次命中 X 次
> - 处置：<改了什么 / 无需改>

（v8.0 首版尚未跑人工校准，落此 harness 待首轮记录。）
