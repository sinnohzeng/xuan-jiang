# DOCX 编辑指南

本指南仅在需要**编辑现有 DOCX 文件并回写**时加载。纯读取分析无需本指南。

## 目录

- [一、技术路线选择](#一技术路线选择)
- [二、环境准备](#二环境准备)
- [三、编辑工作流（使用 docx-editor）](#三编辑工作流使用-docx-editor)
- [四、验证工作流](#四验证工作流)
- [五、DOCX 格式要点（备用知识）](#五docx-格式要点备用知识)
- [六、常见陷阱速查](#六常见陷阱速查)
- [七、手动 OOXML 编辑（高级备用）](#七手动-ooxml-编辑高级备用)
- [八、大文档处理策略](#八大文档处理策略)
- [九、与 Anthropic 官方 DOCX Skill 的关系](#九与-anthropic-官方-docx-skill-的关系)
- [十、创建新 DOCX 文档](#十创建新-docx-文档)

---

## 一、技术路线选择

| 任务 | 推荐工具 |
|------|----------|
| 读取/分析内容 | `pandoc`，转 Markdown 后分析 |
| 浏览文档结构（大文档定位） | `python-docx`，遍历段落/表格 |
| 创建新文档 | `python-docx`；公文格式见主 SKILL.md §7 资源索引中的 gongwen-format.md |
| 编辑现有文档（Track Changes）| `docx-editor` ★推荐 |
| 编辑页眉页脚/嵌入图片等 | 手动 OOXML 操作（见第七节）|

---

## 二、环境准备

```bash
# 必需（docx-editor 需要 Python 3.10+）
pip install docx-editor python-docx

# 读取和验证
brew install pandoc    # macOS
apt install pandoc     # Ubuntu/Debian
```

如果 `docx-editor` 未安装，提示用户执行上述命令后重试。

**Python 版本注意**：docx-editor 需要 Python 3.10 或更高版本。macOS 系统自带的 Python 通常是 3.9，不满足要求。解决方法：

```bash
brew install python@3.12
python3.12 -m venv /tmp/docx_env
source /tmp/docx_env/bin/activate
pip install docx-editor python-docx
```

---

## 三、编辑工作流（使用 docx-editor）

### 3.1 基本用法

```python
from docx_editor import Document

# 默认修订作者为 "任仲然"，用户可指定其他名称
author = "任仲然"

with Document.open("input.docx", author=author) as doc:
    # 所有编辑操作自动生成 Track Changes 标记
    doc.replace("旧文本", "新文本")         # 替换 → <w:del> + <w:ins>
    doc.delete("要删除的文本")              # 删除 → <w:del>
    doc.insert_after("锚点文本", "新增内容")  # 在锚点后插入 → <w:ins>
    doc.insert_before("锚点文本", "前置内容") # 在锚点前插入 → <w:ins>

    doc.save("output.docx")  # 保存到新文件
    # 或 doc.save() 覆盖原文件
```

### 3.2 批注操作

```python
with Document.open("input.docx", author=author) as doc:
    # 添加批注（锚定到指定文本）
    doc.add_comment("需要审查的文本", "请核实此处数据来源")

    # 回复批注
    doc.reply_to_comment(comment_id=1, reply="已核实，数据来自年报")

    # 解决/删除批注
    doc.resolve_comment(comment_id=1)
    doc.delete_comment(comment_id=2)

    # 列出所有批注（支持按作者过滤）
    for c in doc.list_comments():
        print(f"ID:{c.id} 作者:{c.author} 内容:{c.text} 已解决:{c.resolved}")

    doc.save()
```

### 3.3 修订管理

```python
with Document.open("reviewed.docx", author=author) as doc:
    # 列出所有修订
    for r in doc.list_revisions():
        print(f"ID:{r.id} 类型:{r.type} 作者:{r.author} 内容:{r.text}")

    # 接受/拒绝单个修订
    doc.accept_revision(revision_id=1)
    doc.reject_revision(revision_id=2)

    # 批量接受/拒绝（支持按作者过滤）
    doc.accept_all()                    # 接受全部
    doc.reject_all(author="OtherUser")  # 拒绝指定作者的全部修订

    doc.save()
```

### 3.4 精确定位文本

```python
with Document.open("document.docx", author=author) as doc:
    # ★ 编辑前先确认目标文本的唯一性
    count = doc.count_matches("合同期限")
    print(f"找到 {count} 处匹配")

    # 如果有多处匹配，使用 occurrence 参数（0 起始）
    doc.replace("合同期限", "协议期限", occurrence=0)  # 替换第 1 处
    doc.replace("合同期限", "协议期限", occurrence=1)  # 替换第 2 处

    # 或使用更长的上下文确保唯一匹配
    doc.replace("甲方的合同期限为 30 天", "甲方的协议期限为 60 天")

    # 获取全文可见文本（已接受的插入 + 未删除的原文）
    visible = doc.get_visible_text()

    doc.save()
```

### 3.5 跨边界文本操作

Word 经常将连续文本拆分到多个 XML Run 元素中。`docx-editor` 自动处理这种情况：

```python
with Document.open("reviewed.docx", author=author) as doc:
    # 查找文本（即使跨越 Run 或修订边界）
    match = doc.find_text("目标文本")
    if match and match.spans_boundary:
        print("文本跨越了修订边界")

    # replace/delete/insert 均自动处理跨边界情况
    doc.replace("跨边界的目标文本", "替换后的文本")

    doc.save()
```

### 3.6 长段落替换的 Workaround

docx-editor v0.1.x 存在一个已知问题：当段落文本集中在单个 Run（单个 `w:t` 节点包含大量文本）时，`replace()` 方法可能抛出 `TextNotFoundError`，即使 `count_matches()` 能找到目标文本。

原因是 `replace()` 内部的 `_get_nth_match` 方法找到了包含目标文本的 `w:t` 节点，但随后检查 `elem.firstChild.data` 时，直接文本可能只有 1 个字符（Word 内部的 XML 结构导致），从而误判为文本不存在。

**解决方案**：使用内部方法直接操作。

```python
def safe_replace(doc, old_text, new_text, occurrence=0):
    """replace() 的稳健替代，绕过长段落 bug。"""
    rm = doc._revision_manager
    match = rm._find_across_boundaries(old_text, occurrence)
    if match is None:
        return False  # 文本确实不存在
    rm._replace_across_nodes(match, new_text)
    return True
```

建议在所有编辑脚本中用 `safe_replace` 替代 `doc.replace()`，直到 docx-editor 修复此问题。

---

## 四、验证工作流

### 4.1 编辑前：理解原文

```bash
# 提取文本内容（含已有修订标记）
pandoc --track-changes=all input.docx -t markdown --wrap=none -o content.md
```

### 4.2 编辑后：确认修改

```bash
# 查看修改后的文档（含新增修订标记）
pandoc --track-changes=all output.docx -t markdown --wrap=none -o verify.md
```

### 4.3 程序化验证

```python
# 列出本次编辑产生的所有修订
revisions = doc.list_revisions()
for r in revisions:
    print(f"{r.type}: '{r.text[:50]}...'")

# 如果修订出现在错误位置，拒绝并用更精确的上下文重试
doc.reject_revision(revision_id=wrong_id)
doc.replace("更精确的上下文文本", "替换文本")
```

---

## 五、DOCX 格式要点（备用知识）

以下知识在正常使用 `docx-editor` 时无需了解，但有助于排查问题。

### 5.1 核心结构

段落 `<w:p>` → Run `<w:r>` → 文本 `<w:t>`。Run 是格式的最小单位。Word 经常将连续文本拆分成多个 Run。

### 5.2 Track Changes XML 标记

| 操作 | XML 标记 | 说明 |
|------|---------|------|
| 插入 | `<w:ins>` 包裹 `<w:r><w:t>` | 新增文本 |
| 删除 | `<w:del>` 包裹 `<w:r><w:delText>` | 注意用 `delText` 而非 `t` |
| 格式变更 | `<w:rPrChange>` 在 `<w:rPr>` 内 | 记录格式变更前后的属性 |

每个修订标记携带 `w:author`（作者）和 `w:date`（时间戳）属性。

### 5.3 最小化修改原则（★关键）

只标记实际变化的文本，不把未变文本也包在修订标记里：

```xml
<!-- ✅ 正确：只标记变化部分 -->
<w:r><w:t>合同期限为 </w:t></w:r>
<w:del ...><w:r><w:delText>30</w:delText></w:r></w:del>
<w:ins ...><w:r><w:t>60</w:t></w:r></w:ins>
<w:r><w:t> 天。</w:t></w:r>

<!-- ❌ 错误：删除整句再插入整句 -->
<w:del ...><w:r><w:delText>合同期限为 30 天。</w:delText></w:r></w:del>
<w:ins ...><w:r><w:t>合同期限为 60 天。</w:t></w:r></w:ins>
```

> `docx-editor` 已自动遵循此原则，无需手动处理。

### 5.4 格式保留规则

- 永远在 Run `<w:r>` 级别操作，不替换整个段落 `<w:p>`
- 保持未修改文本的原始格式属性 `<w:rPr>` 和 RSID
- 文本含前导/尾随空格时需设置 `xml:space="preserve"`

> `docx-editor` 已自动处理以上所有规则。

---

## 六、常见陷阱速查

| 问题 | 解决方案 |
|------|----------|
| `python-docx` 无法处理 Track Changes | 用 `docx-editor` 替代，python-docx Issue #340 自 2016 年至今未实现 |
| 段落级文本替换导致格式丢失 | `docx-editor` 自动在 Run 级操作，无此问题 |
| 文本跨多个 Run 拆分，找不到 | `docx-editor` 自动处理跨 Run 边界匹配 |
| Track Changes ID 冲突 | `docx-editor` 自动扫描已有最大 ID 并递增 |
| `pandoc` 未安装 | `brew install pandoc`（macOS）/ `apt install pandoc`（Linux）|
| `docx-editor` 未安装 | `pip install docx-editor python-docx` |
| `TextNotFoundError` | 用 `count_matches()` 确认文本存在；用 `get_visible_text()` 查看可见文本 |
| 编辑出现在错误位置 | `reject_revision()` 撤销，用更长的上下文重新定位 |
| `replace()` 在长段落中失败 | 使用 `_find_across_boundaries()` + `_replace_across_nodes()` 绕过（见 3.6 节） |
| Python 版本不满足要求 | docx-editor 需要 Python 3.10+，macOS 默认 3.9 需 `brew install python@3.12` 后用 `python3.12 -m venv` |

---

## 七、手动 OOXML 编辑（高级备用）

当 `docx-editor` 无法满足需求时，比如操作页眉页脚、嵌入图片、修改样式等场景，可回退到手动 OOXML 操作：

```bash
# 1. 解包
unzip document.docx -d unpacked/

# 2. 编辑 XML 文件（使用 Edit 工具直接修改）
#    主文档: unpacked/word/document.xml
#    样式:   unpacked/word/styles.xml
#    设置:   unpacked/word/settings.xml

# 3. 打包（在 unpacked/ 目录内执行）
cd unpacked && zip -r ../output.docx . && cd ..

# 4. 验证
pandoc --track-changes=all output.docx -t markdown --wrap=none -o verify.md
```

---

## 八、大文档处理策略

对于篇幅较长的文档，建议分步处理：

1. **浏览结构**：用 `python-docx` 列出段落和标题，定位目标区域
   ```python
   from docx import Document as PydocxDoc
   doc = PydocxDoc('large-file.docx')
   for i, p in enumerate(doc.paragraphs):
       if p.style.name.startswith('Heading'):
           print(f"[{i}] {p.style.name}: {p.text}")
   ```

2. **确认唯一性**：每次编辑前用 `count_matches()` 确保目标文本唯一

3. **分批编辑**：每批 3-10 处修改，避免一次性修改过多

4. **逐批验证**：每批修改后用 `pandoc --track-changes=all` 验证结果

5. **修订列表检查**：编辑完成后用 `list_revisions()` 确认所有修订正确

---

## 九、与 Anthropic 官方 DOCX Skill 的关系

Anthropic 官方提供两个版本的 DOCX skill：

1. **原始版** `anthropics/skills/docx`：使用 Edit 工具直接修改解包后的 XML
   - 依赖官方自定义脚本 `scripts/office/unpack.py`、`pack.py`、`comment.py`
   - 这些脚本不在公开 pip 包中，第三方 skill 无法使用

2. **docx-editor 版**（`pablospe/docx-editor`）：使用 `docx-editor` Python 库
   - 封装了所有 OOXML 复杂操作，API 语义化
   - 98% 测试覆盖率，跨平台支持

本技能采用方案 2（docx-editor），这是第三方 skill 的最佳选择。
编辑原则（最小化修改、Run 级操作、格式保留）与官方完全一致。

---

## 十、创建新 DOCX 文档

当需要从零创建 DOCX（而非编辑现有文档）时：

- 使用 `python-docx` 库创建（`pip install python-docx`）
- 如果文体为**公文**，遵循 GB/T 9704 排版规范（主 SKILL.md §7 资源索引中的 gongwen-format.md）
- 如果文体为其他类型，使用合理的默认排版格式
