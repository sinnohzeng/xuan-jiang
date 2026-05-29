# Handoff：v5 Sprint 2 prompt 迭代 1 轮 FAIL，待产品决策

**生成时间**：2026-05-22 北京时间下午（本机 PDT 2026-05-21 22:50）
**当前 branch**：`v5.0-rc1`（push origin 已同步）
**前置 handoff**：[20260520-v5-sprint1-shipped.md](20260520-v5-sprint1-shipped.md)
**当前 HEAD**：`44046e1` [v5/sprint2] feat: judge prompt v5.1 加党政公文对标 + spec.md 简化版

## Done

### Sprint 2 路径调整全过程

| 阶段 | commit | 产物 | 状态 |
|------|--------|------|------|
| v1 spec 200 段金标方案 | `960800d` | `evals/gold-standard/spec.md` 198 行 | 已 archive（被 v5.1 简化版覆盖） |
| cicpa 108 段衍生 | `2aab83f` | `derive-from-calibration.py` + `raw-segments-cicpa.jsonl` | 落盘备用 |
| 外网 87 段切片 | `14a4757` | `slice-web-segments.py` + 3 个 web jsonl + 合并 `raw-segments.jsonl` 194 段 | 落盘备用（v5.1 未用） |
| 产品方向调整：放弃金标改对标范例 | `44046e1` | judge prompt v5.1（+47 行对标段）+ spec.md 简化版重写 | **核心改动**，本次验证对象 |
| v5.1 calibration 重跑 | （未 commit） | `evals/calibration-results/` overwritten | **FAIL**（详 §结果） |
| baseline 备份 | （未 commit） | `evals/calibration-results-baseline-v50rc1/` | 防 v5.1 覆盖 baseline |

### v5.1 prompt 改动内容

`prompts/llm-judge-research-report.md` 行 215-262 新增 §"党政公文对标参考语料"：
- 5 段 G1 公文范例（国务院政务公开实施细则 / 领导机制 / 信息公开推进 / 指导思想 / 门户网站建设）
- 3 段 G2 讲话稿范例（高质量发展 / 二十届三中全会 / 基层治理人民立场）
- 4 条对标使用准则（党政高频词不扣 D2/D4、对标语境豁免延伸、大厂黑话仍扣分、D5 评分参考具体名词主语密度）

### Anti-leakage 验证

9 段对标范例 × Sprint 1 calibration-set 173 段 trigram Jaccard **max 0.019**（远 < 0.3 阈值）。

### Grader 三件套未改动（防 grade-gaming）

`calibration-set.jsonl` / `cohen-kappa.py` / `calibration-runner.sh` git diff 0 改动确认。Sprint 1 baseline 结果备份到 `evals/calibration-results-baseline-v50rc1/` 防覆盖。

### v5.1 calibration 实测结果（同 60 段，qwen3.6-plus）

| 维度 | v5.0-rc1 baseline | v5.1 | Δ acc | Δ κ | 备注 |
|------|---|---|---|---|---|
| D1 标点 | 93.2% κ=0 | 93.0% κ=0 | -0.2% | +0 | 持平 |
| D2 AI 套话 | **100%** κ=1.0 | 97.5% κ=0 | **-2.5%** | **-1.0** | ⚠️ 反退 |
| D3 隐喻 | 100% κ=1.0 | 100% κ=1.0 | 0 | 0 | 持平 |
| D4 党政失配 | 97.6% κ=0 | 97.6% **κ=0.655** | 0 | **+0.655** | 对标段在 D4 起作用（唯一亮点） |
| D5 散文（核心目标） | **74.5%** κ=0 | 74.1% κ=0 | **-0.4%** | 0 | ❌ 几乎无变化 |
| **Overall weighted κ** | **0.368** | **0.307** | — | **-0.061** | ⚠️ 整体退步 |
| Disagreements | 18 | 19 | — | +1 | 多 1 个分歧 |

**v5.1 发版 gate（D5 accuracy ≥ 79.5%）：❌ FAIL**

### 失败诊断

1. **对标段太长**：8 段 × 平均 200 字 ≈ 1500 字注入 prompt，挤压 judge 注意力
2. **对标使用准则偏抽象**：4 条准则没明确"反例驱动"——judge 把对标段当"高质量参考"读了，但**没把它当"低分阈值"内化**
3. **D2/D5 unknown 率上升**：D1/D2 unknown 19→20，说明 judge 在党政语境段上反而更犹豫，宁可弃权也不愿打分
4. **D4 改善是唯一信号**：κ 从 0 跃至 0.655——对标段在"识别党政语境"上确实起作用，问题在于挤压了 D2/D5 的判断空间

### 同步发现：qwen3.7-max 今早已发布且 API 可用

DashScope `qwen3.7-max` 已通：

```python
client.chat.completions.create(model="qwen3.7-max", messages=[...])
# → ✅ 可用
```

这是关键新信号——qwen3.7-max 是阿里今日（2026-05-22）发布的旗舰，能力应明显强于 qwen3.6-plus，纯模型升级可能直接 PASS v5.0.0 gate 而无需 prompt 改动。

## Issues

### 已知踩坑

1. **calibration-runner.sh 在 background 模式下 tee 输出 buffer 直到 EOF 才 flush**：进度可见性差，要看 `judge-results.jsonl wc -l` 才能判断实时进度
2. **schema 字段名 `per_dim` 不是 `dimensions`**：写对比脚本时遇到 KeyError，已修

### 未闭环问题

- **v5.1 prompt 应 git revert 还是保留？** 当前 v5.1 prompt 已 push 到 main——FAIL 后是 revert 回 baseline 还是保留供后续迭代？决策点在下次对话。
- **calibration 结果文件已被 v5.1 覆盖**：baseline 备份在 `evals/calibration-results-baseline-v50rc1/` 完整保留，但当前 `evals/calibration-results/` 是 v5.1 跑的。下次跑前需要清理。
- **未在 173 段全跑**：本次只跑前 60 段（同 Sprint 1 limit）。理论上 173 段全跑可能改善 marginal 平衡，但 v5.1 FAIL 已经判明趋势，全跑 173 段大概率仍 FAIL。

## Next

### v5 Sprint 2 续：v5.0.0 stable 产品决策路径（4 选 1，下次对话决定）

**A. 拼 qwen3.7-max 模型升级，不改 prompt（推荐快速验证）**
- git revert prompt 回 baseline（commit `14a4757`）
- 用 qwen3.7-max + 原 v5.0-rc1 prompt 跑同 60 段
- 对比 D5 是否提升 5%
- 耗时：~30-40 min calibration + 5 min 决策
- 优势：纯模型升级是干净的因变量，今日发布的旗舰能力大概率优于 qwen3.6-plus
- 劣势：若 qwen3.7-max 也不 PASS，相当于证明 prompt 是 ceiling

**B. 接受 baseline，直接 ship v5.0-rc1 为 v5.0.0 stable**
- git revert prompt 改动
- spec.md §6 重写为"v5.0.0 = v5.0-rc1 当前能力，D5 74.5% 是 stable baseline，后续 v5.1+ 再迭代 D5"
- tag v5.0.0 + push tag + SKILL.md 连通 --llm-judge flag
- 耗时：~30 min 收尾
- 优势：今日肯定能 ship，遵守"尽快出 v5.0"原意
- 劣势：放弃"提升 D5"目标，等于承认当前 prompt + 模型已到天花板

**C. 继续迭代 v5.1 prompt（缩短对标段 + 反例驱动准则）**
- 对标段从 8×200 字缩到 4×100 字
- 4 条准则改写为反例驱动："看到 X 就 D_n ≥ Y"明确决策规则
- 重跑 60 段
- 耗时：~50 min（修改 + 跑 + 判定）
- 风险：第 2 轮仍可能不达标

**D. 路径 A + C 组合（最稳但耗时）**
- 同时试模型升级 + prompt 迭代两路径
- 4 路 calibration：原 prompt + qwen3.6-plus / 原 prompt + qwen3.7-max / v5.1 prompt + qwen3.6-plus（已有） / v5.1 prompt + qwen3.7-max
- 选 D5 最高那组作为 v5.0.0
- 耗时：~2-3 h
- 优势：数据全面，决策可解释
- 劣势：超出"尽快"窗口

### 入口 plan 与 SSOT 锚点

- 主 plan：`~/.claude/plans/d3-sonnet-sonnet-streamed-panda.md`（上游设计稿）
- 前置 handoff：[20260520-v5-sprint1-shipped.md](20260520-v5-sprint1-shipped.md)
- 本 handoff：本文件
- 关键 SSOT:
  - `plugins/writing-polish/skills/writing-polish/references/constitution.md`（5 维 rubric）
  - `plugins/writing-polish/skills/writing-polish/prompts/llm-judge-research-report.md`（**当前 v5.1 版含对标段**）
  - `plugins/writing-polish/skills/writing-polish/evals/calibration-set.jsonl`（baseline test set，未改）
  - `plugins/writing-polish/skills/writing-polish/evals/gold-standard/spec.md`（**v5.1 简化版**）
  - `plugins/writing-polish/skills/writing-polish/evals/gold-standard/raw-segments.jsonl`（194 段备用候选池，v5.1 未用）
  - `plugins/writing-polish/skills/writing-polish/evals/calibration-results/`（**当前是 v5.1 结果**）
  - `plugins/writing-polish/skills/writing-polish/evals/calibration-results-baseline-v50rc1/`（**Sprint 1 baseline 备份**）

## SLI Commands（下次对话冷启动可跑）

### 验证当前状态

```bash
cd ~/Workspace/xuan-jiang/plugins/writing-polish/skills/writing-polish

# 1. 看 v5.1 vs baseline 对比
python3 -c "
import json
v51 = json.load(open('evals/calibration-results/cohen_kappa.json'))
v50 = json.load(open('evals/calibration-results-baseline-v50rc1/cohen_kappa.json'))
print('D5: baseline', v50['per_dim']['D5']['accuracy']*100, '% vs v5.1', v51['per_dim']['D5']['accuracy']*100, '%')
"

# 2. 验 qwen3.7-max 仍可用
python3 -c "
import os
from openai import OpenAI
c = OpenAI(api_key=os.environ['DASHSCOPE_API_KEY'], base_url='https://dashscope.aliyuncs.com/compatible-mode/v1')
print(c.chat.completions.create(model='qwen3.7-max', messages=[{'role':'user','content':'回答仅一个字：是'}], max_tokens=10).choices[0].message.content)
"
```

### 路径 A（推荐快速验证）启动命令

```bash
cd ~/Workspace/xuan-jiang/plugins/writing-polish/skills/writing-polish

# 1. revert v5.1 prompt 回 baseline
git show 14a4757:plugins/writing-polish/skills/writing-polish/prompts/llm-judge-research-report.md > prompts/llm-judge-research-report.md

# 2. 改 BYOM 切到 qwen3.7-max
export XUAN_JIANG_JUDGE_MODEL=qwen3.7-max
export XUAN_JIANG_JUDGE_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
export XUAN_JIANG_JUDGE_API_KEY_ENV=DASHSCOPE_API_KEY

# 3. 清掉 v5.1 跑出的结果，避免混淆
mv evals/calibration-results evals/calibration-results-v51-qwen36
mkdir -p evals/calibration-results

# 4. 跑 60 段 baseline prompt + qwen3.7-max
bash evals/calibration-runner.sh --rounds 1 --threshold 0.5 --limit 60
```

## 注意事项 / 风险

### 当前 prompt 状态混乱风险

`prompts/llm-judge-research-report.md` 当前是 v5.1 版（含对标段，306 行），已 push origin。如果下次对话冷启动直接跑 calibration，跑的是 v5.1 prompt——必须先 revert 或注明。

### Anti-grade-gaming 检查表（下次对话必须执行）

- [x] 本次未改 grader 三件套（git diff 0 改动）
- [x] baseline 已备份到 `calibration-results-baseline-v50rc1/`
- [ ] 下次跑前清理 `calibration-results/` 防与本次 v5.1 结果混淆
- [ ] 若路径 A，必须先 revert prompt 不能拿 v5.1 prompt + qwen3.7-max 跑（变量不纯）
- [ ] D5 发版 gate **不可降低**（spec.md §6 SSOT）

### Token budget

本次对话 token 估计在 65-75% 区间结尾。handoff + next-dialogue-input 写完后 commit + push，本对话即收。下次对话冷启动加载本 handoff + spec.md + cohen_kappa.json 即可。

### 沉淀已落

- [ ] wiki/synthesis 页待下次对话出结果后写（路径 A/B/C 决策完成后沉淀一篇）

## 相关文件

- 主 plan：`~/.claude/plans/d3-sonnet-sonnet-streamed-panda.md`
- 前置 handoff：[20260520-v5-sprint1-shipped.md](20260520-v5-sprint1-shipped.md)
- 当前 spec.md：[`plugins/writing-polish/skills/writing-polish/evals/gold-standard/spec.md`](../../plugins/writing-polish/skills/writing-polish/evals/gold-standard/spec.md)
- 当前 prompt：[`plugins/writing-polish/skills/writing-polish/prompts/llm-judge-research-report.md`](../../plugins/writing-polish/skills/writing-polish/prompts/llm-judge-research-report.md)
- baseline 备份：`plugins/writing-polish/skills/writing-polish/evals/calibration-results-baseline-v50rc1/`
- 子智能体 endpoint 记忆：`~/.claude/memory/reference_subagent_model_endpoints.md`
