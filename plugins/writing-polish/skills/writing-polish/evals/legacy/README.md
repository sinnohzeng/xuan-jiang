# Legacy Evals（v5.x 归档）

本目录保存 v5.0-rc1 / v5.1.x 时代的 calibration 结果，仅供考古，**不与 v6.x 直接比较**。

## 协议变更（v5 → v6 不可直接比的原因）

| 维度 | v5.0-rc1 / v5.1.x | v6.0+ |
|---|---|---|
| L2 LLM Judge 调用方 | `scripts/llm-judge-runner.py` + 外部 API（dev-only path） | 主对话内联，零外部 API |
| L3 多智能体 orchestration | `prompts/multi-agent/orchestration-guide.md` 决策指南 | SKILL.md §2.2 Polish Protocol step 3 + `prompts/reviewer.md` 模板 |
| 模型路由 | `config/default.yaml` + `scripts/model_adapter.py`（dev-only） | 由调用方 Claude Code session 决定 |
| Calibration runner | `evals/calibration-runner.sh` + `evals/cohen-kappa.py` 自动跑批 | 主对话直跑 + v5 vs v6 同稿对比（`evals/v6.0-baseline/comparison.md`） |
| --llm-judge flag | scan-ai-taste.sh 接受但仅打印 RFC 提示（stub） | 已删除；不存在该 flag |

## 文件来源

- `calibration-results-baseline-v50rc1/` — 2026-05-27 v5.0-rc1 ship 前的 baseline
- `calibration-results/` — v5.1.x 时期的滚动结果

## 何时可以删除整个 legacy/

- v6.x 稳定运行 ≥ 3 个 minor 版本后
- 或用户明确决定不再追溯 v5 历史
