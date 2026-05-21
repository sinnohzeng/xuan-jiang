# Next Dialogue Input：v5.1 Sprint 2（人工金标 + κ ≥ 0.8 gate）

## 目标

把 v5.0.0-rc1 baseline 升级到 v5.0.0 stable：人工标 100-200 段金标 calibration set + 跨模型 κ 回归 + κ ≥ 0.8 真 gate。

## 入口文件

- 主 plan：`~/.claude/plans/d3-sonnet-sonnet-streamed-panda.md`
- Active handoff：[`docs/handoff/20260520-v5-sprint1-shipped.md`](../../handoff/20260520-v5-sprint1-shipped.md)
- 关键 SSOT:
  - `plugins/writing-polish/skills/writing-polish/references/constitution.md`（v5 按文体切片宪法）
  - `plugins/writing-polish/skills/writing-polish/evals/calibration-set.jsonl`（v5.0 auto-baseline，Sprint 2 要新增 gold-standard/）
  - `plugins/writing-polish/skills/writing-polish/evals/calibration-results/cohen_kappa.json`（v5.0 baseline κ）
  - `~/sinnoh-kb/wiki/synthesis/2026-05-20-xuan-jiang-v5-sprint1-implementation.md`（Sprint 1 反方观点段建议 Sprint 2 闭环）

## 必读铁律（top 5）

1. **[[feedback_anthropic_api_policy]]**：永远不通过 Anthropic API 调用 Claude（太贵），脚本默认 BYOM Qwen/DeepSeek；需要 Sonnet 4.6 1M 直接由 Claude Code 主对话执行
2. **[[plan-review-auto SKILL]]**：plan v1 写完自动 5 视角 review + 直接迭代回 plan 不留 TODO
3. **[[inference-vs-verification SKILL]]**：推断 ≠ 事实，calibration κ 数值前必跑 verifier 链路
4. **xuan-jiang v5 calibration 反方观点（Sprint 1 沉淀）**：
   - calibration set leakage 风险（auto-label 与 judge prompt 共用 anchor 池）→ Sprint 2 必须用人工独立金标
   - "after 段全 0 分"过度乐观 → Sprint 2 必须 after 段人工质检
   - 跨模型 κ 不可比 → Sprint 2 同金标准跑 ≥ 2 模型
5. **GB/T 15834-2011 中文标点**：所有 sediment / handoff / SSOT 用弯引号 `"……"`，禁 ASCII 直引号 / 直角引号

## 已知 blocker / 上游依赖

- **DashScope 1500 RMB 资源包剩余 ≤ 3 天**（2026-05-20 起算）：Sprint 2 calibration 必须趁此期间跑完，否则降级 BYOM 到 DeepSeek / Gemini Gateway
- **qwen3.6-max-preview 单次 API call ~3-5 min**：跨模型回归用它太慢，建议主跑 qwen3.6-plus + 抽样 100 段跑 max-preview 验证

## Sprint 2 7 步路标（按依赖）

1. **写 `evals/gold-standard/spec.md`**：定义人工标注 SOP（5 维 0-3 + unknown，2 人独立标注 + 1 仲裁）
2. **抽 200 段候选 segments**：从 cicpa V2/V3/V4 diff + 中央部委公文示例（公开来源）混合，覆盖 G1/G2/G3/G4/G5/G8 6 个文体
3. **2 人独立标注**：猪猪老公 + Claude Code 子智能体（用 clean-context-code-review 模式），每段独立打分
4. **仲裁分歧段**：Cohen's κ 计算后看 disagreement.md，> 2 分差的段进入仲裁（猪猪老公 + 1 额外 reviewer）
5. **跨模型 κ 回归**：qwen3.6-plus + qwen3.6-max-preview + DeepSeek v3.5，看 3 模型 κ 是否一致
6. **judge prompt few-shot 池扩充**：根据 disagreement.md 把高频分歧改成新 few-shot example
7. **决策 v5.0.0 stable 发版条件**：≥ 2 模型 κ ≥ 0.8 → tag v5.0.0 + SKILL.md 接入 `--llm-judge` flag

## 当前对话不要做的事

- ❌ 跑跨 SKILL 的 Multi-Agent Review（那是 Sprint 3）
- ❌ 写 Reader Testing prompt（那是 Sprint 3）
- ❌ 跨 CLI 移植（那是 v6+）
- ❌ 用 Anthropic API 调 Sonnet（用 BYOM 或 Claude Code 主对话）
