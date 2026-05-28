# evals/ — anchor / eval 物理隔离铁律

> v6.1 起，writing-polish 严格遵循 2026 行业最佳实践（LangChain Eval Best Practice 2026 / Anthropic Building Effective Agents 修订版）：
> **训练 / 校准用数据 与 评测 / 一致性测试用数据 物理隔离**。

## §1 文件用途

| 文件 | 用途 | 注入 prompt？ |
|---|---|---|
| `calibration-set.jsonl` | 历史标注源（cicpa 实战切片，自动 + 人工） | ❌ 直接使用已废，必先经 split |
| `anchor-set.jsonl` | reviewer few-shot 校准锚（`select-fewshot.sh` 消费） | ✅ 仅注入 `verified: true` 样本 |
| `eval-set.jsonl` | κ 一致性测试 + regression（未来 CI 消费） | ❌ **禁止注入任何 prompt** |
| `fixtures/*.md` | L1 scan-ai-taste.sh 输入稿（6 个 anchor 用例） | n/a |
| `v6.0-baseline/` | v5.1 vs v6.0 release gate 对比快照 | n/a |
| `legacy/v5.x/` | v5.x dev-only 资产（归档，不维护） | n/a |

## §2 隔离铁律

1. **禁止把 `eval-set.jsonl` 任何一行注入到任何 prompt 中**——这是 Grader Gaming 红线，会让评测信号失真
2. **`anchor-set.jsonl` 仅注入 `verified: true` 样本**——unverified 样本可能本身评分错误
3. **`select-fewshot.sh` 排除与当前 draft 同 `source_commit` 的 anchor**——防"自己的稿被自己的 anchor 引用"循环
4. **拆分由 `split-calibration.sh` 一次性生成**，不动 `calibration-set.jsonl` 内容（保留单一历史 SSOT）
5. **新增标注**应直接写入 `calibration-set.jsonl` 然后重跑 split——避免双写不一致

## §3 拆分流程

```bash
bash ../scripts/split-calibration.sh           # 默认不覆盖
bash ../scripts/split-calibration.sh --force   # 覆盖已存在的 anchor / eval
```

输出报告：

```
✓ split done: 5 total → anchor=2 (verified) + eval=3 (others)
```

如 `anchor=0`，主对话 spawn reviewer 时 `select-fewshot.sh` fallback 到 zero-shot（warn）。

## §4 跑 reviewer few-shot 调用链

```
SKILL.md §2.2 step 3
   ↓
bash scripts/select-fewshot.sh <draft> <D{X}>
   ↓ stdout: 2 行 jsonl
prompts/reviewer.md §4 {{FEWSHOT_ANCHORS}} 拼接
   ↓
Agent(subagent_type=general-purpose, prompt=拼好的) × N
   ↓
返回 JSON → schema 校验 → max() 汇总
```

## §5 维护守则

- `calibration-set.jsonl` 内容修改后必须重跑 `split-calibration.sh --force`
- 不要手动编辑 `anchor-set.jsonl` / `eval-set.jsonl`（会被下次 split 覆盖）
- 标注新样本时优先标 `verified: true`（直接进 anchor 池）
- 若要把某条从 anchor 池移到 eval 池，把 `verified` 改成 `false` 然后重跑 split
