# Resource Routing：完整资源路由表

> **命中即整读本文件、勿 head 预览**（这是 hub 索引，截断读会漏 load-when 判据）。
> Load when：SKILL.md §5 mode 必读资源不够、需要查“某场景该读哪个 references”时。
> SSOT：本文件；SKILL.md §5 是 mode 级 cached mirror（3 行 × 3 mode）。
> 说明：SKILL.md §5 已把 Polish 每次必用的 `revision-checklist.md` / `logic-and-structure.md` 直链提到一跳，本表为长尾全量索引。

## §1 references/ 按 load-when 查表

| 资源 | scope | load when |
|---|---|---|
| [`anti-ai-taste-anchors.md`](anti-ai-taste-anchors.md) | all | L1 fail 时查规则细则 |
| [`constitution.md`](constitution.md) | polish | reviewer 必读自己分到焦点对应的体裁切片（§0 焦点 + §0.5 正向实质 + §2 体裁 + §3/§4 例外） |
| [`coach-checkpoints.md`](coach-checkpoints.md) | coach | Coach 生产弧全程（立意→构思→提纲→材料→结构 checkpoint） |
| [`revision-checklist.md`](revision-checklist.md) | polish | step 3 修改阶段决策依据 |
| [`genre-guide.md`](genre-guide.md) §<X> | all | 体裁判断后读对应章节 |
| [`writing-methodology.md`](writing-methodology.md) | coach, polish | Coach 准备 + 立意/结构/材料 焦点判依据来源 |
| [`writing-coaching-arc.md`](writing-coaching-arc.md) | coach | “教我写作 / 练笔”技能弧（摹仿→制造→创造） |
| [`peer-vs-self-revision.md`](peer-vs-self-revision.md) | polish, reviewer | “他批”语气，reviewer 子代理与主对话改稿阶段必守 |
| [`logic-and-structure.md`](logic-and-structure.md) | polish | 结构与论据 焦点判依据 |
| [`gongwen-format.md`](gongwen-format.md) | polish 公文 | 体裁 = 规范公文 时读 |
| [`citation-spec.md`](citation-spec.md) | polish 调研 | 体裁 = 调研报告 / 材料·事实焦点判模糊归因 |
| [`docx-editing-guide.md`](docx-editing-guide.md) | docx | DOCX 模式必读 |
| [`ai-taste-examples.md`](ai-taste-examples.md) | reviewer | AI味焦点可选引用反例对照 |
| [`failure-cases.md`](failure-cases.md) | polish | scan 多轮失败时查同类历史 |
| [`reviewer-routing.md`](reviewer-routing.md) | polish | step 2 决定 spawn 几个 reviewer、分哪些焦点 |
| [`renzhongran-coverage-matrix.md`](renzhongran-coverage-matrix.md) | meta | 审计任仲然 12 讲继承度（原书 → SKILL 行为 → reference → eval） |

## §2 agents/ 路由

| 资源 | scope | load when |
|---|---|---|
| [`../../agents/writing-reviewer.md`](../../agents/writing-reviewer.md) | polish | step 2 用 Task spawn 的 clean-context reviewer 子代理（返回 NL 反馈 + verdict，只评不改） |

## §3 scripts/ 路由（per-use）

| 资源 | scope | load when |
|---|---|---|
| [`../scripts/scan-ai-taste.sh`](../scripts/scan-ai-taste.sh) | polish, audit | L1 hard gate 主体（--json 输出供主对话） |
| [`../scripts/word-count-check.sh`](../scripts/word-count-check.sh) | polish | §1.2 字数歧义解析 / 句长方差 |
| [`../scripts/docx-review-workflow.py`](../scripts/docx-review-workflow.py) | docx | Track Changes 自动化 |
| [`../scripts/check-dependencies.sh`](../scripts/check-dependencies.sh) | setup | 首次使用 sanity check + 单向依赖自检 |

## §4 assets/ 路由

| 资源 | scope | load when |
|---|---|---|
| [`../assets/real-world-anchors/`](../assets/real-world-anchors/) | coach, polish | 体裁判断后展示锚本 |
| [`../assets/anchor-essays/`](../assets/anchor-essays/) | coach | 摹仿阶段（《怎样写作》8 篇范例，正向标杆） |

## §5 evals/offline-harness/ 路由（**离线 dev-eval，不进 per-use 路径**）

| 资源 | scope | load when |
|---|---|---|
| [`../evals/README.md`](../evals/README.md) | dev | 改规则后衡量 polisher 本身好不好时入口 |
| [`../evals/offline-harness/`](../evals/offline-harness/) | dev | 数值打分判官 / few-shot 选取 / calibration 拆分（仅离线，禁进 per-use prompt） |
| [`../evals/anchor-set.jsonl`](../evals/anchor-set.jsonl) | dev | 离线 few-shot 校准源（仅 verified 样本）+ before→after 示例来源 |
| [`../evals/eval-set.jsonl`](../evals/eval-set.jsonl) | dev | 离线 κ 一致性 + regression；**禁止注入任何 prompt**（Grader Gaming 红线） |
