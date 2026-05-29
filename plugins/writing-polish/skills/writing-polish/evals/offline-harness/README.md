# offline-harness/ — 数值评测零件（离线，不进 per-use 路径）

> v7.0：把「数值逐维打分」这套离线打榜零件从 per-use 热路径剥离到这里。per-use 改稿只用 `agents/writing-reviewer.md` 的自然语言反馈，**绝不调用本目录任何脚本/prompt**。
> 入口与隔离铁律见上级 [`../README.md`](../README.md)。

## 文件

| 文件 | 用途 |
|---|---|
| `llm-judge-research-report.md` | G-Eval 式数值判官 prompt（1-5 / 0-3 逐维打分 + rubric + few-shot），离线衡量 polisher 在调研/咨询体裁的评分一致性 |
| `select-fewshot.sh` | 离线实验：从 `../anchor-set.jsonl` 抽 1 易 1 难 verified 样本拼 few-shot（deterministic seed + 同 commit 排除） |
| `split-calibration.sh` | 把 `../calibration-set.jsonl` 按 `verified` 拆 `../anchor-set.jsonl` + `../eval-set.jsonl`；anchor=0 时非零退出（防静默空） |
| `scan-hard-gate.sh` | L1 最小集 30 条码点级 CI 门（毫秒级），用于 CI 而非交付前完整扫描（后者用 `../../scripts/scan-ai-taste.sh`） |
| `eval-record.schema.json` | 离线 eval-record jsonl 单行结构契约（数值分字段，仅离线日志用） |

## 为什么在这里而不在 per-use 路径

数值逐维打分（G-Eval / Prometheus / MT-Bench 流派）的价值是**可聚合、可跨样本比较**——这是离线衡量「polisher 本身好不好」需要的，不是单篇改稿需要的。单篇改稿要的是「指到具体句 + 怎么改」的可执行反馈，一个分数没法直接编辑。详 SKILL.md §0 两世界拆分。
