# Changelog

All notable changes to xuan-jiang `writing-polish` skill are documented here. Format follows [Keep a Changelog 1.1](https://keepachangelog.com/en/1.1.0/), versioning follows [Semver 2.0](https://semver.org/).

## [4.3.0] — 2026-05-08

### Added

- **Context-aware whitelists**：scan-ai-taste.sh 新增 `count_with_context_whitelist` 通用函数，命中行 ±2 行扩窗匹配白名单关键词
  - §1.5.1「防火墙」在 IT 实物语境（机房 / 等保 / GB/T 22239 / WAF / NGFW / 入侵检测 / 部署 N 台 等）自动豁免
  - §1.5.2「对标」在党政咨询语境（政府工作报告 / 党中央 / 二十大 / 同级 / 国际先进 / 启示 / 经验 / 案例 等）自动豁免
- **Dynamic density thresholds**（§4 软阈值动态化）：按句子数计算阈值，不再固定 ≤ 3
  - 短文 < 200 句 → 阈值 ≤ 3（保持原阈值）
  - 中文 200-500 句 → 阈值 ≤ 6
  - 长文 500-1000 句 → 阈值 ≤ 9
  - 超长 ≥ 1000 句 → 阈值 ≤ 15
- **§1.8 咨询报告专属约束**（5 条）：第三方咨询机构对甲方交付物专用，含身份边界 / 结论先行 / 不背书厂商 / 「其一/其二」分级 / 多方利益静默
- **§1.4.111 合规括号 7 类白名单**（docs-only）：法条文号 / 施行日期 / 缩写首释 / 表格备注 / 图表内嵌 / 计算说明 / 章节自引
- **6 篇新增锚本**（assets/real-world-anchors/）：
  - `06-cicpa-consulting-template.md` — 第三方咨询机构对甲方交付范本（cicpa 053 治理后）
  - `07-sic-digital-economy-report.md` — 国家数据局《数字中国发展报告（2024）》
  - `08-cyberspace-info-development.md` — 网信办《国家信息化发展报告（2024）》
  - `09-cicpa-info-plan-2021-2025.md` — 中注协五年信息化规划（甲方反向对照）
  - `10-ndrc-high-quality-development.md` — 发改委高质量发展新闻发布会发言
  - `11-gov-work-report-duibiao.md` — 北京 2024 政府工作报告「对标」用法
- **evals 双轨化**（evals/evals.json + test-runner.sh）：
  - 保留 LLM 行为测试（`tests` 数组）
  - 新增 `regression_fixtures` 数组：scan 脚本回归测试，6 条 fixture 入库 evals/fixtures/
  - test-runner.sh 加 regression 跑批分支，自动比对 exit code
- **--llm-judge flag stub**（v5.0 范式播种，本版仅打印 RFC 提示）
- **docs/rfc/v5.0-llm-judge.md** RFC：LLM-as-judge 混合架构设计（rubric 5 dimension + Haiku 4.5 prompt + cicpa calibration set + cost 估算）
- **CHANGELOG.md**（本文件）：补回 v4.0 至 v4.3 演进史
- `.gitignore` for evals/regression-log.md（避免追踪每次运行产物）

### Changed

- references/anti-ai-taste-anchors.md 同步 v4.3 改动（§1.4.111 加白名单说明 / §1.5.1 加防火墙白名单说明 / §1.5.2 加对标白名单说明 / §1.8 新增 / §4 阈值文档同步 / §6 锚本资产清单更新到 11 篇 / 顶部加 v5.0 范式预告）
- suggest_for 文案分语境：drama / jargon 各加 IT / 党政语境提示行
- plugin.json + marketplace.json bump 4.2.0 → 4.3.0，description 加 v4.3 关键词

### Verified

- cicpa 053 实战回归：
  - WS3 完整版（1418 句，9 处 IT 防火墙）→ §1.5.1 0 命中 PASS
  - WS1 完整版（908 句，对标用法）→ §1.5.2 0 命中 PASS
  - 长文密度阈值合理放宽（≤ 15）不再勉强
- 6 条 regression_fixtures 全 PASS（含 2 条反向哨兵防漏检）

---

## [4.2.0] — 2026-04-30

### Added

- 230+ anti-AI-taste rules（156 红线 + 60 橙线 + 17 结构反模式）
- §1.6 元注释 / 客服话术红线（5 类，含元注释开头 / 自我介绍 / 免责声明 / 服务话术段尾 / 拟人化集体代词）
- §1.7 Wikipedia 长尾盲区（Reference markup bugs / Placeholder dates / Inline-header / Thematic breaks）
- §1.4 标点新增 4 条（v4.2）：每段加粗冒号开头 / 数字 list 滥用 / 标题化偏好 / 英文标点穿插
- evals/evals.json + test-runner.sh + regression-log.md 体系
- 8 篇 anchor-essays + 5 篇 real-world-anchors

### Changed

- 句长方差检测 + 分组密度报表（按 §1.1-§1.7 章节累计）
- check-cn-quotes.py 外置中文标点 / 中英混排检测
- scan-ai-taste.sh 新增 --suggest-fix / --json 模式

---

## [4.1.0] — 2026-04-25

### Added

- §1.5 戏剧化 / 互联网大厂黑话 / 网络口语 / 程序员产品经理腔（4 子节）
- GB/T 15834 弯引号强制 + 直角引号禁用
- 14 条标点 / 数学符号 / 半中半英新红线

---

## [4.0.0] — 2026-04-20

### Added

- 大刀阔斧重构：110 条 AI 味硬约束 + 8 范文锚点 + 三层防御机制
- references/anti-ai-taste-anchors.md 主文件
- scripts/scan-ai-taste.sh AI 味自检脚本
- 7 大文体专属审稿标准（公文 / 述职 / 演讲 / 调研报告 / 自媒体 / 散文 / 学术）
