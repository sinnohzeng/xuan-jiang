# Orchestrator Synthesis（主对话整合 finding）

> Layer 3 收尾：R1 (3-5 视角) + R2 (fresh-eye) 输出齐备后，主对话执行 synthesis。**主对话**是 orchestrator，**不**派 subagent，**不**调脚本。

## P0-P5 优先级序列（cicpa SOP 内化）

| 级 | 标签 | 含义 | 行动 |
|---|---|---|---|
| **P0** | 重大事实错误 | 数据 / 名称 / 法条 / 引用错；放出去会被甲方当场打脸 | 必改，立即 |
| **P1** | 客户敏感 | 暴露内部信息 / 越界批评 / 厂商背书；触发合规风险 | 必改，立即 |
| **P2** | 严重 AI 腔 | 红线词命中 / em-dash / 元注释 / 客服话术 | 必改，本轮内 |
| **P3** | 中度 AI 腔 | 套话密集 / 模板感 / 戏剧化叙事 | 改，本轮内 |
| **P4** | 文风可优化 | 同义改写、句长方差小、过渡词单调 | 视余力改 |
| **P5** | 美学偏好 | subagent 私人偏好但无 SSOT 锚点 | **不采纳**（除非用户主动要） |

## 决策三问（每条 finding 落地前机械化跑）

```
[ ] Q1：这条 finding 违反了 SSOT 吗？
        - 援引 anchors §X / constitution.md §Y / consulting-principles §Z？
        - 是 → 继续 Q2；否 → P5 直接弃

[ ] Q2：这条 finding 颗粒度有增益吗？
        - 改完后表达更具体 / 更准 / 更朴实？
        - 还是只是把"打通业务闭环"换成"打通业务回路"这种同义改写？
        - 有增益 → 继续 Q3；否 → 弃

[ ] Q3：R1 多个 finding 重复加严同一处吗？
        - 同一 line_range + dimension 重复出现？
        - 取 severity 最严的那条，丢弃其他
```

## Edit 落地铁律

- **串行**：一次只 Edit 一处，不并行写文件
- **行号倒序**：从大行号往小行号改，避免行号偏移
- **每 Edit 后**自查改动是否引入新违反（rare 但 cicpa 实战出现过）
- 改完后跑 L1 scan 再 spot-check L2 五维

## 收敛判停（21% 采纳率 + severe = 0）

```
while True:
    finding_pool = R1 + R2 dedup
    accepted_this_round = apply_finding_with_three_questions(finding_pool)
    adoption_rate = len(accepted_this_round) / len(finding_pool)

    if adoption_rate < 0.20:
        # 连续两轮 < 20% 才退出，单轮不算
        if last_round_adoption_rate < 0.20:
            break
        else:
            continue
    if max_severity_in(finding_pool) <= "P3" and adoption_rate < 0.30:
        # severe 已清空，剩下的都是 P4 优化，停手
        break
    if rounds_total >= 5:
        # 硬上限，防 churn
        break
    # 否则重新派 R1+R2 跑下一轮
```

**实战经验**：cicpa 053 治理跑了 3-4 轮，最终采纳率 21%。**不是采纳率越高越好**——L1/L2 已抓走 70% AI 味红线，Layer 3 真正价值是抓 R1/R2 多视角共识下的硬骨头（P0-P2），那些占总 finding 也就 20-25%。

## Synthesis 输出（给用户的最终交付）

```markdown
# 改稿交付报告（v5 三层 hybrid）

## L1 / 硬 Gate
- scan-ai-taste.sh 退出码：[0]
- 红线指标：[全部 PASS / 详情见 log]

## L2 / LLM Judge
- 五维评分：D1=0 D2=1 D3=0 D4=1 D5=2
- Self-Refine 轮数：[1 / 2 / 3]
- 主要剩余问题：[≤ 100 字]

## L3 / Multi-Agent Review
- 视角：[A 事实 / B 文风 / C 咨询身份 / D IA / E a11y]
- finding 总数：[N]
- 采纳：[K]（K/N = 采纳率）
- 收敛轮数：[1-5]
- 终止原因：[< 20% × 2 轮 / severe=0 / 5 轮硬上限]

## 已采纳 finding 清单（按 P0-P5 排序）

| ID | severity | 位置 | 问题 | 改后引文 |
|---|---|---|---|---|
| F12 | P0 | L142 | 数据错（应 23.7% 非 27.3%） | "…较去年下降 23.7%…" |
| F03 | P2 | L88 | em-dash 用作平行连词 | "…的影响。同时，…" |

## 未采纳 finding（供用户复议）

[列出 P4-P5 + 决策三问 Q2/Q3 失败的 finding，附弃用理由]

## 反方观点与盲区

[按 writing-polish CLAUDE.md 项目硬约定，所有 wiki/creations 写完必填此段]
```

## 与用户的最后一公里

- 输出报告 + 改稿全文给用户
- 用户口头"念改"建议在交付前自跑一遍
- 用户提出复议时，针对**特定 finding ID** 解释，不重跑全流程
