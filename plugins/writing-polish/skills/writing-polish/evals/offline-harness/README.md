# offline-harness/：数值评测零件（离线，不进 per-use 路径）

> v7.0：把“数值逐维打分”这套离线打榜零件从 per-use 热路径剥离到这里。per-use 改稿只用 `agents/writing-reviewer.md` 的自然语言反馈，**绝不调用本目录任何脚本/prompt**。
> 入口与隔离铁律见上级 [`../README.md`](../README.md)。

## 文件

| 文件 | 用途 |
|---|---|
| `llm-judge-research-report.md` | G-Eval 式数值判官 prompt（1-5 / 0-3 逐维打分 + rubric + few-shot），离线衡量 polisher 在调研/咨询体裁的评分一致性 |
| `select-fewshot.sh` | 离线实验：从 `../anchor-set.jsonl` 抽 1 易 1 难 verified 样本拼 few-shot（deterministic seed + 同 commit 排除） |
| `split-calibration.sh` | 把 `../calibration-set.jsonl` 按 `verified` 拆 `../anchor-set.jsonl` + `../eval-set.jsonl`；anchor=0 时非零退出（防静默空） |
| CI 硬闸 | v8.0 起单引擎：CI 门改调 `../../scripts/scan-ai-taste.sh --genre base --json`（base profile = 无体裁豁免、保留 context 语境白名单）；独立的 scan-hard-gate.sh 已并入并删除，其唯一独有检查（H2.1 错误文号占位）已端口进 scan §1.7.2 |
| `eval-record.schema.json` | 离线 eval-record jsonl 单行结构契约（数值分字段，仅离线日志用） |

## genre 字段由上层填，scan 侧不落盘（诚实注记）

`eval-record.schema.json` 的 `genre` 枚举用 constitution §0 的精确中文名（规范性公文 / 领导讲话稿 / … / 第三方咨询报告 / 其他）。`scan-ai-taste.sh --genre` 收的是 G1-G8 码（决定豁免档），但 scan 的 `--log-to` **不把 genre 写进日志行**（记录里无 genre 键仍合法，schema 里 genre 非必填）。两侧无 G 码 → 中文名的自动映射，是有意为之：体裁维由跑评测的上层 harness 单独填中文名，避免在 scan 里塞一张易漂移的映射表。要让离线 eval 承接体裁维时，在上层记录环节补 genre 中文名即可，勿在 scan 内造映射。

## 为什么在这里而不在 per-use 路径

数值逐维打分（G-Eval / Prometheus / MT-Bench 流派）的价值是**可聚合、可跨样本比较**：这是离线衡量“polisher 本身好不好”需要的，不是单篇改稿需要的。单篇改稿要的是“指到具体句 + 怎么改”的可执行反馈，一个分数没法直接编辑。详 SKILL.md §0 两世界拆分。

## Backlog（v10.0 记）

- **LLM-as-judge 长度偏差防范**：2026 年中实践（rubric-based evals，来源见 `docs/research/2026-08-03-best-practices.md` 第 8 条）指出数值判官偏好长输出，需显式防范（长度归一或成对比较）；且判词必须可行动。下次迭代 `llm-judge-research-report.md` 的判官 prompt 时补上。
- **腾讯朱雀 AI 检测**（matrix.tencent.com/ai-detect）：仅列为离线打榜的可选外部镜子，不进 per-use 热路径，不作交付判据（constitution 非目标：别优化 AI 检测器）。
