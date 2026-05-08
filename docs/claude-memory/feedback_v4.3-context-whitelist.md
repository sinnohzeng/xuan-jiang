---
name: v4.3 上下文白名单设计反思
description: writing-polish v4.3 把硬词典扩展为「词典 + 上下文白名单」的工程经验、过度工程边界、未来 LLM-as-judge 的演化判断
type: feedback
---

# v4.3 上下文白名单设计反思（2026-05-08）

## 触发场景

cicpa 053 轮 4 文件治理（WS1/WS3 完整版 + 简要版）实战暴露 v4.2 在三个语境的过严倾向：

1. WS3 完整版 9 处「防火墙」（机房 / WAF / 等保产品）被 §1.5.1 战斗化叙事词典误判
2. WS1 完整版「对照启示」、WS3 简要版「同级对标充分」等共 4 处「对标」被 §1.5.2 大厂黑话误判
3. WS1/WS3 完整版（千句以上）「核心」勉强压到 4 处，固定阈值 ≤ 3 偏严

## 关键设计判断

### 选 ±2 行扩窗，不选同行 grep

理由：cicpa 实战中"防火墙"同行可能不含 IT 关键词（"防火墙 2 台"独立成行），但前后行有"机房部署"。±2 行扩窗覆盖 95% 真实场景，又不引入复杂句法分析。

```bash
count_with_context_whitelist() {
    # 命中行 ±2 行内含白名单关键词则豁免
    while IFS=: read -r ln _; do
        local start=$((ln > 2 ? ln - 2 : 1))
        local end=$((ln + 2))
        sed -n "${start},${end}p" "$file" | grep -qE "$whitelist" && ...
    done < <(grep -nE "$word" "$file")
}
```

### 选千句密度动态阈值，不选用户配置

理由：用户配置阈值是认知负担。直接按句子数自动算（短文 < 200 ≤ 3 / 中长文 200-1000 ≤ 6-9 / 长文 ≥ 1000 ≤ 15），与"长文容忍少量术语高频"的语料事实对齐。

### 选 docs-only 处理合规括号 7 类，不扩 scan 检测

理由：scan 第 134 行只检测 `（如|（即|（也就是说`三个明确的 AI 起手词，本来就不会误报「（OA）」「（国发〔2022〕14号）」。原 handoff 误判为脚本缺陷，实际是 AI 写作时矫枉过正——读到「禁用括号补充」就回避所有括号。docs 写明 7 类合规括号即可，不动 scan。

## 过度工程边界

| 选项 | 是否做 | 理由 |
|---|---|---|
| 抽出 whitelist 词典到外部 .txt 文件 | ❌ | inline shell 变量足够；外部化只在词典 > 5 处时才合理 |
| 跨平台兼容 Windows | ❌ | 用户在 macOS / Linux，Windows 是过度设计 |
| 把 scan-ai-taste.sh 重写为 Python | ❌ | bash 已可工作，重写收益小风险大 |
| 跨段落语义分析 | ❌ | grep ±2 行已覆盖 95% 场景，剩余 5% docs 提醒 |
| 引入 LLM-as-judge | ❌（推迟 v5.0） | 范式跃迁需独立 release，calibration / cost / latency 需独立验证 |

## 2026 行业范式对照

Firecrawl 调研后确认 2026 mid-year 业界已演化到混合范式：

- Anthropic「Demystifying evals for AI agents」2026-01：tiered grading（code-based → model-based → human）
- Openlayer「LLM as Judge Guide」2026-03：rubric decomposition + few-shot CoT + correlation > 0.85
- arXiv「How Well Do Agentic Skills Work」2026-04：真实场景 skills 性能比理想条件衰减明显

v4.3 维持硬规则范式（fast / 透明 / < 1s），通过上下文白名单消化 95% 实战痛点；v5.0 范式跃迁交给独立 release（详见 `docs/rfc/v5.0-llm-judge.md`）。

## 反向哨兵的重要性

每条上下文白名单都加 1 条「应继续 FAIL」用例（drama-firewall.md / jargon-duibiao.md），防止白名单矫枉过正变成漏检。这是 v4.3 evals 双轨化的关键设计——`tests` 数组负责 LLM 行为测试，`regression_fixtures` 数组负责 scan 脚本回归测试，正反两类用例并存。

## 跨仓 SSOT 同步

v4.3 改了密度阈值口径，cicpa 项目 `STYLE-GUIDE.md` 第八节（四）和 `CLAUDE.md` 第 7 条同步更新——不再人工记忆固定阈值，直接跑 scan 自检。这是「文档债务零容忍铁律」的标准动作。
