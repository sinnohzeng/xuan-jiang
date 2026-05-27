# Handoff：v5.0-rc1 Sprint 1 基础已落地，等接力

**生成时间**：2026-05-20
**当前 branch**：`v5.0-rc1`（已 push origin）
**上游 plan**：`~/.claude/plans/d3-sonnet-sonnet-streamed-panda.md`
**沉淀页**：`~/sinnoh-kb/wiki/synthesis/2026-05-20-xuan-jiang-v5-llm-native-upgrade-design.md`
**对应 commit**：`3a510b2 [v5/foundation] feat: Layer 1 hard gate + model adapter + 三 role config`

## 本次完成（Sprint 1 上半段）

### 已落地文件

```
plugins/writing-polish/skills/writing-polish/
├── config/
│   ├── default.yaml                      默认 Sonnet 4.6 1M（judge/reviewer/rewriter）
│   └── examples/
│       ├── qwen.yaml                     BYOM 切 Qwen3.6-Max-Preview
│       └── gemini-gateway.yaml           BYOM 切 Cloudflare 13-key Gemini Gateway
├── scripts/
│   ├── model_adapter.py                  统一 Anthropic + OpenAI-compatible，含 yaml 配置加载、env 兜底、JSON 输出、多数投票
│   └── scan-hard-gate.sh                 Layer 1 硬 Gate，30 条 codepoint 级机械红线
```

### 已通过测试

- `bash scan-hard-gate.sh evals/fixtures/it-firewall.md` → exit 0 PASS
- `python scripts/model_adapter.py judge` → 应能正确加载 default.yaml + 报告 Sonnet 4.6 1M 配置

### 已通过质量门

- 知识库 sediment 页 scan-ai-taste.sh v4.3 红线全过（WARN 仅软阈值密度）
- 两份 commit message 按 cicpa 项目格式（`[v5/foundation]` 前缀 + 详细修改清单）

## Sprint 1 剩余（下半段，2 工作日内完成）

按依赖顺序：

### 1. 写 `constitution.md`（~400 行）

230 条红线按文种切片，每条带：
- 红线 ID（沿用 §1.1 / §1.4.112 / §1.5.1 等编号）
- 字面 anchor（哪些词 / 哪些句式触发）
- 文种归属（公文 / 讲话稿 / 调研报告 / 述职报告 / 汇报发言稿 / 随笔杂文 / 自媒体 / 咨询报告）
- 例外清单（cicpa 6 类高频假阳：政策文号时间线 / 其一其二其三 / 国产化 / 政策原文引用 / 千分位 / 审议确定）
- 1-2 个 anchor 改写示例

**源材料**：复用 `~/.claude/plugins/cache/xuan-jiang/writing-polish/4.3.0/skills/writing-polish/references/anti-ai-taste-anchors.md`（v4.3 原版 230 条）+ cicpa `项目修改原则.md` 7 红线。

### 2. 写 `prompts/llm-judge-research-report.md`（咨询报告 5 维 rubric）

5 维度：
- D1 标点（codepoint 级，0-3，但因为 Layer 1 已扫，这里更多是 0/1 corroboration）
- D2 显式 AI 套话（赋能 / 综上所述 / 让我们一起 / 客服腔）
- D3 隐喻强度（防火墙 IT vs 隐喻战斗、闸门 / 跑过 / 翻车 / 三层防御）
- D4 大厂 vs 党政语境（对标 / 闭环 / 抓手 / 颗粒度）
- D5 整体散文 AI 体（句长方差合格但假大空）

每维 0-3 + Unknown escape。CoT prompt。few-shot 来自 cicpa 053 治理 commit 抽取的正反例。

**关键**：必须在 prompt 内嵌：(a) 项目认可格式白名单（如咨询报告允许末段“其一/其二/其三”） (b) 政策原文引用豁免 (c) 当前日期（防 reviewer 把已发文号判为未来）。

### 3. 写 `scripts/llm-judge-runner.py`（Layer 2 编排器，~250 行）

调用流程：
```python
1. 加载 default.yaml + 用户/项目 yaml + env 兜底（已由 model_adapter.py 实现）
2. 识别文种（先用 frontmatter `type:` 字段，没有则走简单 prompt classifier）
3. 加载对应 prompts/llm-judge-<genre>.md
4. 段切（每 200 字一段，跨段重叠 30 字）
5. 每段 pass^3 调 ModelAdapter（vote_rounds=3，防 position bias）
6. 多数投票合成最终 score
7. 输出 JSON：{file, genre, segments: [{seg_id, scores: {D1..D5}, evidence, reasoning}], summary}
```

依赖：`model_adapter.py`（已有）+ `tqdm`（progress bar）+ `pyyaml`（已用）。

### 4. 写 `scripts/self-refine-loop.py`（rewrite-judge 闭环，~120 行）

```python
for round_i in range(max_rounds=3):
    score_t = judge(file)
    if score_t > threshold: break
    rewrite_prompt = build_rewrite_prompt(file, score_t.findings)
    new_file = rewriter.call(rewrite_prompt)
    score_t1 = judge(new_file)
    if score_t1 <= score_t - min_delta: break   # 没有提升，停止
    file = new_file
```

### 5. 写 `evals/calibration-set.jsonl`（200 段标注样本）

数据来源：
- `cicpa 053-WS3 完整版治理前 vs 治理后` git diff，自动抽 100 段（before = score 2-3，after = score 0-1）
- `cicpa WS4 简要版 3 轮治理 commit` 抽 50 段
- `xuan-jiang/plugins/writing-polish/skills/writing-polish/evals/fixtures/*` 现有 6 个 + 用户标 14 个边界扩到 50

格式：
```jsonl
{"id": "cicpa-ws3-053-before-001", "text": "...", "genre": "research-report", "scores": {"D1": 0, "D2": 2, "D3": 3, "D4": 1, "D5": 2}, "annotator": "auto-from-commit-diff", "verified": false}
```

抽取脚本：写 `evals/extract-from-cicpa-commits.py`，跑 `git log --diff-filter=M -- 04-最终交付/`，把每个 commit 的 before / after 段对捞出来。

### 6. 写 `evals/calibration-runner.sh`（Cohen's κ 计算，~100 行）

```bash
bash evals/calibration-runner.sh --model claude-sonnet-4-6 --rounds 3 --threshold 0.8

# 输出：
# - cohen_kappa.json：{"D1": 0.92, "D2": 0.85, ..., "overall": 0.87}
# - disagreement.md：模型 vs 人类金标准差异列表（最有学习价值的样本）
# - per_segment.csv
```

依赖：`scikit-learn.metrics.cohen_kappa_score`。

### 7. Sprint 1 gate：跑 calibration → κ ≥ 0.8 → commit + push v5.0.0-rc1 release

```bash
# 跑 200 段
bash evals/calibration-runner.sh

# 若 κ ≥ 0.8：
#   git add -A
#   git commit -m "[v5/sprint1] feat: LLM Judge + Self-Refine + calibration set 200 段 + κ=0.XX"
#   git tag v5.0.0-rc1
#   git push origin v5.0-rc1 --tags

# 若 κ < 0.8：
#   读 disagreement.md → 调 prompts/llm-judge-research-report.md → 重跑
#   不达 0.8 不发版
```

## 接力 SOP

1. 新会话开局先 `cd ~/Workspace/xuan-jiang && git checkout v5.0-rc1 && git pull origin v5.0-rc1`
2. 读本 handoff + 上游 plan 文件 `~/.claude/plans/d3-sonnet-sonnet-streamed-panda.md`
3. 读现有 commit `3a510b2` 改动（`git show 3a510b2`）确认基础设施
4. 按上面 7 个步骤逐项推进，每个步骤 commit 一次

## 注意事项

### Anthropic 最佳实践优先

- SKILL.md 主体 ≤ 300 行 → 重型逻辑外迁到 prompts / scripts / references（progressive disclosure）
- 能 grep 走 grep，不能 grep 走 LLM（hard gate + LLM judge 互补不互斥）
- Reader Testing 范式（Anthropic doc-coauthoring）放 Sprint 4，不在 Sprint 1

### 模型默认

- judge / reviewer / rewriter 三 role 全部默认 Sonnet 4.6 1M（`claude-sonnet-4-6`）
- BYOM 走 OpenAI-compatible（Qwen / Gemini Gateway / GLM / DeepSeek 全部走同一个 endpoint shape）
- env 兜底优先级最高（`XUAN_JIANG_<ROLE>_MODEL` / `_BASE_URL` / `_API_KEY_ENV`）

### 跨 CLI 解耦

低优先级。v4.3 scripts 已经是 standalone bash / python 零运行时依赖，scripts 本身可直接被 Antigravity / TRAE / Cursor / Cline 等 agent CLI 通过 `bash` / `python` 调用。SKILL.md 跨平台移植靠文本复制 + 各平台触发器适配，不需要任何代码改造。这部分留 v6+。

### cicpa 资产内化

Sprint 3 才搬完整 Multi-Agent SOP。Sprint 1 只需要：
- cicpa 7 红线 → constitution.md §"咨询报告子集"
- cicpa 6 类高频假阳 → prompts/llm-judge-research-report.md 内嵌 `{{project_exemptions}}`

## 验收 checklist

完成 Sprint 1 后必跑：

- [ ] `bash scripts/scan-hard-gate.sh evals/fixtures/it-firewall.md` exit 0
- [ ] `python scripts/llm-judge-runner.py --file evals/fixtures/gov-duibiao.md --genre research-report` 返回合法 JSON 5 维 score
- [ ] `XUAN_JIANG_JUDGE_MODEL=qwen3.6-max-preview XUAN_JIANG_JUDGE_BASE_URL=$DASHSCOPE_BASEURL XUAN_JIANG_JUDGE_API_KEY_ENV=DASHSCOPE_API_KEY python scripts/llm-judge-runner.py --file evals/fixtures/gov-duibiao.md --genre research-report` 同一 schema，分数 ±1 浮动
- [ ] `python scripts/self-refine-loop.py --file evals/fixtures/drama-firewall.md --max-rounds 3` 每轮分单调上升或停止
- [ ] `bash evals/calibration-runner.sh --model claude-sonnet-4-6` 输出 Cohen's κ ≥ 0.8
- [ ] git tag v5.0.0-rc1 + push origin v5.0-rc1 --tags
- [ ] sediment 一条 commit message 到 sinnoh-kb：`sediment: xuan-jiang v5.0.0-rc1 calibration κ=0.XX 达 gate`

## 相关文件

- 上游 plan：`~/.claude/plans/d3-sonnet-sonnet-streamed-panda.md`
- 知识库 sediment：`~/sinnoh-kb/wiki/synthesis/2026-05-20-xuan-jiang-v5-llm-native-upgrade-design.md`
- v4.3 RFC 底稿：`~/Workspace/xuan-jiang/docs/rfc/v5.0-llm-judge.md`
- v4.3 anchors（230 条红线源材料）：`~/.claude/plugins/cache/xuan-jiang/writing-polish/4.3.0/skills/writing-polish/references/anti-ai-taste-anchors.md`
- cicpa 项目修改原则：`~/Workspace/cicpa/00-项目治理/04-工作方法论/项目修改原则.md`
- cicpa 多智能体审校工作方法论：`~/Workspace/cicpa/00-项目治理/04-工作方法论/多智能体审校工作方法论.md`
- cicpa 多智能体 SOP 升级版：`~/Workspace/cicpa/.claude/memory/feedback_multi_agent_iteration_sop.md`
- cicpa Qwen review 实践：`~/Workspace/cicpa/.claude/memory/feedback_qwen_review_md_practice.md`
- 子智能体模型 endpoint 记忆：`~/.claude/memory/reference_subagent_model_endpoints.md`
