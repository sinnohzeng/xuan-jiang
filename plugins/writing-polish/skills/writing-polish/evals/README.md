# Evals — writing-polish v4.0 测试用例

## 目的

写作类 skill 是**主观输出**，evals 不做严格 pass/fail 评分。本目录的作用：

1. **Regression test**：每次 SKILL 改动后跑一次，确保没有退化
2. **客观可验证部分**：通过 `scripts/scan-ai-taste.sh` 验证 AI 味红线（这部分是确定性的）
3. **主观部分**：用 spawn 2 个 subagent 对比（with-skill vs baseline），人工审阅输出

## 5 条测试用例

详见 `evals.json`。覆盖：

| ID | 场景 | 用户硬点 |
|---|---|---|
| test-01 | 公文黑话 + 翻译腔润色 | "赋能/重塑/打造"消除 |
| test-02 | 述职报告深度修改 | 三取胜结构应用 |
| test-03 | 写作辅助 + 范文锚点摹仿 | assets/anchor-essays/ 复用 |
| test-04 | 破折号硬约束 | 破折号 = 0 |
| test-05 | 客服腔"接住"硬约束 | 接住/共情/看见你 = 0 |

## 跑法

### A. 客观验证（自动）

```bash
# 拿到 skill 改写后的输出，跑 scan
bash scripts/scan-ai-taste.sh /path/to/revised-output.md

# 期望：exit code = 0（全部红线 = 0）
```

### B. 主观对比（半自动）

```bash
# 1. spawn baseline subagent（不加载 writing-polish skill）执行 test-01 input
# 2. spawn with-skill subagent（加载 v4.0）执行同样 input
# 3. 用 generate_review.py（或人工）对比两份输出的 AI 味密度
```

可参考 Anthropic 官方 [skill-creator](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md) 的 evaluation loop。

## 通过标准

- **客观红线**（test-04 / test-05）：scan-ai-taste.sh exit 0 = 通过
- **结构性改造**（test-01 / test-02 / test-03）：审查报告含明确的方法论引用 + 红线检测通过
- **退化判定**：with-skill 输出在 AI 味密度上**显著优于**baseline = 通过

## 维护

每次 SKILL.md 或 references/anti-ai-taste-anchors.md 重大变更后，跑全部 5 条 test，记录通过率。
