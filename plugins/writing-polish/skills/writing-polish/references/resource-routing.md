# Resource Routing — 完整资源路由表

> Load when：SKILL.md §5 mode 必读资源不够、需要查"某场景该读哪个 references"时。
> SSOT：本文件；SKILL.md §5 是 mode 级 cached mirror（3 行 × 3 mode）。

## §1 按 load-when 查表

| 资源 | scope | load when |
|---|---|---|
| [`anti-ai-taste-anchors.md`](anti-ai-taste-anchors.md) | all | L1 fail 时查规则细则 |
| [`constitution.md`](constitution.md) | polish | L2 self-judge 不确信某维时读详细 rubric；L3 reviewer 必读自己分到的那一维 §D{X} |
| [`revision-checklist.md`](revision-checklist.md) | polish | step 4 修改阶段决策依据 |
| [`genre-guide.md`](genre-guide.md) §<X> | all | 体裁判断后读对应章节 |
| [`writing-methodology.md`](writing-methodology.md) | coach | Coach step 1 |
| [`writing-coaching-arc.md`](writing-coaching-arc.md) | coach | Coach 全程（摹仿→制造→创造） |
| [`peer-vs-self-revision.md`](peer-vs-self-revision.md) | polish, L3 | reviewer 必读（"他批"语气） |
| [`logic-and-structure.md`](logic-and-structure.md) | polish D3 | L2 D3 评分时读 |
| [`gongwen-format.md`](gongwen-format.md) | polish 公文 | 体裁 = 规范公文 时读 |
| [`citation-spec.md`](citation-spec.md) | polish 调研 | 体裁 = 调研报告 时读 |
| [`docx-editing-guide.md`](docx-editing-guide.md) | docx | DOCX 模式必读 |
| [`ai-taste-examples.md`](ai-taste-examples.md) | L2, L3 | 评分时可选引用反例对照 |
| [`failure-cases.md`](failure-cases.md) | polish | scan 多轮失败时查同类历史 |
| [`reviewer-routing.md`](reviewer-routing.md) | polish | step 3 决定 spawn 哪几个 reviewer 时 |

## §2 prompts/ 路由

| 资源 | scope | load when |
|---|---|---|
| [`../prompts/reviewer.md`](../prompts/reviewer.md) | polish L3 | L3 spawn 正式 reviewer 模板（D1-D5 任一维度全评） |
| [`../prompts/spot-check.md`](../prompts/spot-check.md) | polish L3 | 默认 spawn 1 + step 5 验证回路（仅 D5 速判） |
| [`../prompts/llm-judge-research-report.md`](../prompts/llm-judge-research-report.md) | polish 咨询 | 体裁 = 调研 / 咨询报告 时附加到 reviewer prompt 的 `{{CONSTITUTION_SECTION}}` |

## §3 scripts/ 路由

| 资源 | scope | load when |
|---|---|---|
| [`../scripts/scan-ai-taste.sh`](../scripts/scan-ai-taste.sh) | polish, audit | L1 hard gate 主体（--json 输出供主对话） |
| [`../scripts/scan-hard-gate.sh`](../scripts/scan-hard-gate.sh) | CI | 最小集 30 条码点级（毫秒级） |
| [`../scripts/select-fewshot.sh`](../scripts/select-fewshot.sh) | polish L3 | spawn reviewer 前拼 §4 校准锚（deterministic + 易难分层 + 同 commit 排除） |
| [`../scripts/auto-fix-loop.sh`](../scripts/auto-fix-loop.sh) | polish | 自动修复 1-2 轮（可选） |
| [`../scripts/docx-review-workflow.py`](../scripts/docx-review-workflow.py) | docx | Track Changes 自动化 |
| [`../scripts/check-dependencies.sh`](../scripts/check-dependencies.sh) | setup | 首次使用 sanity check + `--check-cycles` 单向依赖自检 |
| [`../scripts/split-calibration.sh`](../scripts/split-calibration.sh) | setup | 一次性把 calibration-set.jsonl 拆 anchor-set / eval-set 两视图 |
| [`../scripts/word-count-check.sh`](../scripts/word-count-check.sh) | polish | 句长方差 / 段同质化 |
| [`../scripts/check-cn-quotes.py`](../scripts/check-cn-quotes.py) | polish | 中文引号专项验证 |

## §4 assets/ + evals/ 路由

| 资源 | scope | load when |
|---|---|---|
| [`../assets/real-world-anchors/`](../assets/real-world-anchors/) | coach, polish | 体裁判断后展示锚本 |
| [`../assets/anchor-essays/`](../assets/anchor-essays/) | coach | 摹仿阶段（《怎样写作》8 篇范例） |
| [`../evals/anchor-set.jsonl`](../evals/anchor-set.jsonl) | polish L3 | select-fewshot.sh 输入源（仅 verified 样本） |
| [`../evals/eval-set.jsonl`](../evals/eval-set.jsonl) | CI / regression | κ 一致性 + regression 测试；**禁止注入任何 prompt**（Grader Gaming 红线） |
| [`../evals/README.md`](../evals/README.md) | all | anchor / eval 物理隔离铁律 |
