# evals/ — 离线 dev-eval harness

> **v7.0 定位**：本目录是**离线开发评测工具**，衡量「writing-polish 这个 polisher 本身好不好」，**只在改规则时跑**，**不进 per-use 改稿热路径**。
>
> 写作评价分两个世界（详 SKILL.md §0）：**每篇改稿**用自然语言反馈 + 粗判（reviewer 子代理，不打分）；**离线打榜**用数值逐维分（本目录）。数值评分 / few-shot / κ 一致性只活在这里。
>
> 对齐 Anthropic「Demystifying evals for AI agents」(2026-01)：grader 抗 gaming、给「拿不准」逃生舱、读 transcript、capability vs regression 分层。

## §1 文件用途

| 文件 | 用途 | 注入 per-use prompt？ |
|---|---|---|
| `calibration-set.jsonl` | 历史标注源（cicpa 实战切片，自动 + 人工 gold，173 条） | ❌ 离线源，必先经 split |
| `anchor-set.jsonl` | 离线 few-shot 校准锚（`offline-harness/select-fewshot.sh` 消费）+ before→after 来源 | ❌ per-use 不注入（reviewer 直接读 constitution §5） |
| `eval-set.jsonl` | 离线一致性 + regression 测试 | ❌ **禁止注入任何 prompt**（Grader Gaming 红线） |
| `fixtures/*.md` | L1 `scan-ai-taste.sh` 输入回归稿（6 个含正反哨兵） | n/a |
| `offline-harness/` | 数值判官 prompt + few-shot 选取 + split 工具 + scan 最小集 + eval-record schema | ❌ 仅离线 |
| `v6.0-baseline/` | 历史 release gate 对比快照（v5.1 vs v6.0） | n/a（archive） |
| `legacy/v5.x/` | v5.x dev-only 资产（归档，不维护） | n/a（archive） |

## §2 隔离铁律（防 Grader Gaming）

1. **禁止把 `eval-set.jsonl` 任何一行注入到任何 prompt 中**——会让评测信号失真。
2. **`anchor-set.jsonl` 仅含 `verified: true` 样本**——unverified 样本可能本身评分错误。当前 9 条来自 constitution §5 Example G-N 的人工 gold。
3. **`select-fewshot.sh` 排除与当前 draft 同 `source_commit` 的 anchor**——防「自己的稿被自己的 anchor 引用」循环。
4. **拆分由 `offline-harness/split-calibration.sh` 一次性生成**，不动 `calibration-set.jsonl` 内容（单一历史 SSOT）。
5. **新增标注**直接写 `calibration-set.jsonl` 再重跑 split——避免双写不一致。

## §3 拆分流程

```bash
bash offline-harness/split-calibration.sh           # 默认不覆盖
bash offline-harness/split-calibration.sh --force   # 覆盖已存在的 anchor / eval
```

输出报告：`✓ split done: 173 total → anchor=9 (verified) + eval=164 (others)`。

**非空 guard（v7.0 新增）**：若 `anchor=0`（calibration 内无 verified 样本），脚本**非零退出（code 4）并报错**——杜绝 v6 那次「anchor 静默为空半年没人发现」重演。要新增 anchor，把对应 `calibration-set.jsonl` 记录的 `verified` 改 `true` 再重跑。

## §4 离线一致性实验调用链（dev-time）

```
改了红线 / constitution / reviewer 子代理后，想知道有没有变差：
   ↓
bash offline-harness/split-calibration.sh --force      # 刷新 anchor / eval
   ↓
（可选）bash offline-harness/select-fewshot.sh <draft> <D{X}>   # 离线实验拼 few-shot
   ↓
用 offline-harness/llm-judge-research-report.md 的数值判官跑 eval-set
   ↓
读 transcript + 看一致性是否回归（capability 任务低基线爬坡 / regression 任务保 ~100%）
```

> per-use 改稿**不走这条链**——per-use 是 `scan-ai-taste.sh`（L1）+ `agents/writing-reviewer.md`（NL 反馈），不打数值分。

## §5 维护守则

- `calibration-set.jsonl` 内容修改后必须重跑 `split-calibration.sh --force`。
- 不要手动编辑 `anchor-set.jsonl` / `eval-set.jsonl`（会被下次 split 覆盖）。
- 新样本若已人工核验，标 `verified: true`（进 anchor 池）；否则默认进 eval 池。
- κ / inter-rater 一致性是离线衡量手段，不是 per-use 产物；不要在改稿输出里出现分数。
