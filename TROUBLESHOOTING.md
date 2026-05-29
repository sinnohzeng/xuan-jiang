# 常见问题指引（writing-polish v7.0）

> 本文件按「症状 / 原因 / 解决」三段组织。先跑 `bash plugins/writing-polish/skills/writing-polish/scripts/check-dependencies.sh` 排查依赖。
>
> 本文件为元论述（讲解规则使用），列举违规词作教学示例，scan-ai-taste.sh 跳过整文扫描。

<!-- scan-skip -->

## 1. scan 一直 FAIL，怎么办？

**症状**：跑 `scan-ai-taste.sh draft.md` 反复 FAIL。

**原因**（按频率）：① 戏剧化叙事词（三层防御 / 闸门 / 翻车 / 跑通）；② 大厂黑话（抓手 / 闭环 / 对标 / 复盘）；③ 客服段尾（希望对您有帮助）；④ 标点（破折号 / ASCII 直引号 / 直角引号）；⑤ 元注释开头（作为一个 AI 助手）。

**解决**：

```bash
bash plugins/writing-polish/skills/writing-polish/scripts/scan-ai-taste.sh draft.md --suggest-fix
```

每条违规附改写建议。戏剧化与大厂黑话**不能机械替换**（v7 已无 auto-fix 脚本，刻意如此——机械替换会留生硬痕迹），要把表达拉回事实陈述；查 `references/failure-cases.md` 看历史同类 case 的重写过程。

## 2. DOCX 打不开 / 转换失败

**原因**：依赖未装。**解决**：

```bash
bash plugins/writing-polish/skills/writing-polish/scripts/check-dependencies.sh
```

- macOS：`brew install pandoc`；Ubuntu/Debian：`apt install pandoc`
- 修订模式还需：`pip install python-docx docx-editor`

## 3. 不知道自己属于哪个文体

按「主要场合 + 主要受众」二维定位：

| 用户身份 | 主要功能 | 文体 |
|---|---|---|
| 党政机关单位 | 印发命令 / 通知 / 决议 | 规范性公文 (G1) |
| 党政领导个人 | 大会讲话 / 会议讲话 | 领导讲话稿 (G2) |
| 调研课题组 | 现状诊断 / 政策建议 | 调研报告 (G3) |
| 个人 / 单位领导 | 年度 / 考核述职 | 述职报告 (G4) |
| 单位向上汇报 | 工作汇报 / 座谈 | 汇报发言稿 (G5) |
| 个人发表观点 | 评论 / 杂感 / 散文 | 随笔杂文 (G6) |
| 公众号 / 头条 / 短视频 | 公开传播 | 自媒体 (G7) |
| 第三方咨询机构 | 对甲方实施方案 / 对照启示 | 咨询报告 (G8) |

详细标准见 `references/genre-guide.md`，体裁判定锚点见 `references/reviewer-routing.md` §2。

## 4. 修订模式（Track Changes）每段都改了，看着乱

**原因**：修订 / 重写 / 简要版三种场景未区分。修订模式应「定点精修」。

**解决**：明确告知 SKILL——「用修订模式定点精修」（开 track changes）/「重写这份文档」（不开）/「起草 5 页简要版」（不开）。判定见 `SKILL.md` §2.4 DOCX 桥接。

## 5. 写作辅助生成的文稿空洞，全是套话

**原因**：prompt 没给素材，AI 缺米下锅反射性堆套话。

**解决**：走 Coach mode 会在**材料 checkpoint** 主动向你追问事实缺口（不替你编造）。也可直接给具体素材，例如不说「帮我起草数字化转型讲话」，改说「市级会议讲话，8-10 分钟，背景是过去三年 X 领域试点成果 A/B/C，受众 18 个区县分管领导，重点讲：试点成效 / 推广路径 / 配套政策」。材料越具体，输出越实在。

## 6. scan 报「句长标准差 < 8」

**原因**：句长过于均匀（每句 18-22 字）是 AI 指纹。

**解决**：长句拆短、短句合并扩展、加一两句极短句（「这是问题。」「得改。」）做节奏。目标标准差 ≥ 8、平均 25-35 字。

## 7. 中文里出现 ASCII 直引号 / 直角引号

**症状**：scan 报「§1.4.111 ASCII 直引号」或直角引号违规。

**解决**：中文双引号必须用大陆国标弯引号 `"" ''`。手动改，或：

- macOS：「系统设置 → 键盘 → 文本输入」勾「使用智能引号」
- Word：「自动更正 → 智能引号」
- 注意：直角引号 `「」` 是港台/日式，大陆党政公文不用，同样会被扫。

## 8. per-use 改稿为什么不给我打分了？（v7.0 变更）

**这是有意设计**。v7.0 起每次改稿走「自然语言反馈 + 粗判（够好了/要改/红线未清）」，不再输出 `D1-D5 0-3` 分数矩阵。原因：全行业改稿循环（Self-Refine / Anthropic evaluator-optimizer）都用可执行反馈——「这句把主张埋在从句下，提到句首」能直接改，而「立意 2/3」不能。数值逐维打分是**离线衡量 polisher 本身**的工具，在 `evals/offline-harness/`，不进每篇改稿。详 `SKILL.md` §0。

## 9. reviewer 子代理报错 / 没返回

**症状**：Polish 时 `[spawn writing-reviewer ...]` 后无 verdict。

**解决**：主对话会 retry 1 次（2s 退避），2 次失败记 `missing-review` 并继续（不静默降级）。若持续失败，检查 `agents/writing-reviewer.md` 是否被插件正确发现（`.claude-plugin/plugin.json` 含 `"agents": "./agents/"`）。

## 10. 反向用例：我想翻译 / 写代码 / 分析数据

本 SKILL 不处理这三类（见 SKILL.md frontmatter `Does NOT trigger`）。翻译用通用翻译工具；代码 review 用 `code-review` skill；数据分析用 pandas / Excel。

## 11. SKILL.md / references 自身跑 scan 也 FAIL

**预期行为**。规则文档含元论述段（列举禁用词作教学），`anti-ai-taste-anchors.md` / `constitution.md` / 本文件等用 `<!-- scan-skip -->` 包裹。scan 针对用户 draft，不针对教学 reference。

## 12. 想看 SKILL 历史变更

- 完整版本演进见根目录 `CHANGELOG.md`（v3.0 → v7.0）。
- 当前状态一页纸见 `docs/status.md`。
- 历史失败案例见 `references/failure-cases.md`。

<!-- /scan-skip -->
