# 党政公文排版格式规范

依据：GB/T 9704-2012《党政机关公文格式》国家标准。
适用：从零创建 DOCX 公文时遵循此规范。仅在文体为公文时按需加载。

## 目录

- [一、页面设置](#一页面设置)
- [二、正文格式](#二正文格式)
- [三、标题层级](#三标题层级)
- [四、页码](#四页码)
- [五、python-docx 实现代码](#五python-docx-实现代码)
- [六、字号对照表](#六字号对照表)
- [七、日期时间写法规范](#七日期时间写法规范)
- [八、数字使用规范](#八数字使用规范)

---

## 一、页面设置

| 参数 | 值 |
|------|-----|
| 纸张 | A4（210mm × 297mm）|
| 上边距 | 37mm ± 1mm |
| 下边距 | 35mm ± 1mm |
| 左边距 | 28mm ± 1mm |
| 右边距 | 26mm ± 1mm |
| 版心尺寸 | 156mm × 225mm |
| 每页行数 | 22 行 |
| 每行字数 | 28 个字 |

---

## 二、正文格式

- **字体**：仿宋
- **字号**：三号（16pt）
- **加粗**：否
- **首行缩进**：2 字符（= 32pt，即 2 × 16pt）
- **行距**：28 磅（固定值）
- **对齐**：两端对齐

---

## 三、标题层级

| 层级 | 字体 | 字号 | 加粗 | 编号格式 | 示例 |
|------|------|------|------|---------|------|
| 文件标题 | 方正小标宋简体（未安装时用宋体）| 二号（22pt）| 否 | — | 居中排列 |
| 一级标题 | 黑体 | 三号（16pt）| 否 | 一、二、三、 | 一、总体要求 |
| 二级标题 | 楷体 | 三号（16pt）| 否 | （一）（二）（三）| （一）指导思想 |
| 三级标题 | 仿宋 | 三号（16pt）| **是** | 1. 2. 3. | 1. 加强组织领导 |
| 四级标题 | 仿宋 | 三号（16pt）| 否 | （1）（2）（3）| （1）明确责任分工 |

### 编号规则

- **不使用 Word 自动编号/列表功能**，直接用普通文本写编号
- 一级标题编号后用顿号“、”：一、
- 二级标题编号用中文圆括号：（一）
- 三级标题编号后用下脚点“.”：1.
- 四级标题编号用中文圆括号：（1）

### 标题排列

- 文件标题：居中，可分一行或多行排列，回行时词意完整
- 一级标题：左起顶格，单独占行，标题后不加标点（除问号、省略号外）
- 二级标题：左空二字，单独占行或与正文接排
- 三级标题：左空二字，与正文接排或单独占行
- 四级标题：左空二字，与正文接排

---

## 四、页码

- **字体**：宋体
- **字号**：四号（14pt）
- **格式**：`-1-`（阿拉伯数字外加一字线）
- **位置**：页面底端外侧（奇数页右侧，偶数页左侧；单面印刷时居中亦可）

---

## 五、python-docx 实现代码

### 5.1 页面设置

```python
from docx import Document
from docx.shared import Mm, Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn

doc = Document()
section = doc.sections[0]
section.page_width = Mm(210)
section.page_height = Mm(297)
section.top_margin = Mm(37)
section.bottom_margin = Mm(35)
section.left_margin = Mm(28)
section.right_margin = Mm(26)
```

### 5.2 设置中文字体的辅助函数

```python
def set_run_font(run, font_name, size_pt, bold=False):
    """设置 Run 的中文和西文字体。"""
    run.font.name = font_name
    run.font.size = Pt(size_pt)
    run.bold = bold
    # 关键：必须同时设置 w:eastAsia 属性，否则中文字体不生效
    r_elem = run._element
    rPr = r_elem.get_or_add_rPr()
    rFonts = rPr.get_or_add_rFonts()
    rFonts.set(qn('w:eastAsia'), font_name)
```

### 5.3 正文段落

```python
def add_body_paragraph(doc, text):
    """添加公文正文段落：仿宋三号，首行缩进2字符，行距28磅。"""
    para = doc.add_paragraph()
    para.paragraph_format.first_line_indent = Pt(32)  # 2字符 = 2 × 16pt
    para.paragraph_format.line_spacing = Pt(28)
    para.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    run = para.add_run(text)
    set_run_font(run, "仿宋", 16)
    return para
```

### 5.4 各级标题

```python
def add_doc_title(doc, text):
    """文件标题：方正小标宋简体（或宋体）二号，居中。"""
    para = doc.add_paragraph()
    para.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
    para.paragraph_format.line_spacing = Pt(28)
    run = para.add_run(text)
    # 方正小标宋简体系统可能未安装，用宋体作为备选
    try:
        set_run_font(run, "方正小标宋简体", 22)
    except Exception:
        set_run_font(run, "宋体", 22)
    return para

def add_heading_level1(doc, number, text):
    """一级标题：黑体三号，顶格。如 add_heading_level1(doc, '一', '总体要求')"""
    para = doc.add_paragraph()
    para.paragraph_format.line_spacing = Pt(28)
    run = para.add_run(f"{number}、{text}")
    set_run_font(run, "黑体", 16)
    return para

def add_heading_level2(doc, number, text):
    """二级标题：楷体三号，左空二字。如 add_heading_level2(doc, '一', '指导思想')"""
    para = doc.add_paragraph()
    para.paragraph_format.first_line_indent = Pt(32)
    para.paragraph_format.line_spacing = Pt(28)
    run = para.add_run(f"（{number}）{text}")
    set_run_font(run, "楷体", 16)
    return para

def add_heading_level3(doc, number, text):
    """三级标题：仿宋三号加粗，左空二字。如 add_heading_level3(doc, 1, '加强组织领导')"""
    para = doc.add_paragraph()
    para.paragraph_format.first_line_indent = Pt(32)
    para.paragraph_format.line_spacing = Pt(28)
    run = para.add_run(f"{number}. {text}")
    set_run_font(run, "仿宋", 16, bold=True)
    return para

def add_heading_level4(doc, number, text):
    """四级标题：仿宋三号，左空二字。如 add_heading_level4(doc, 1, '明确责任分工')"""
    para = doc.add_paragraph()
    para.paragraph_format.first_line_indent = Pt(32)
    para.paragraph_format.line_spacing = Pt(28)
    run = para.add_run(f"（{number}）{text}")
    set_run_font(run, "仿宋", 16)
    return para
```

### 5.5 页码

```python
from docx.oxml import OxmlElement

def add_page_number(doc):
    """添加页码：宋体四号，居中，格式 -1-。"""
    section = doc.sections[0]
    footer = section.footer
    footer.is_linked_to_previous = False
    para = footer.paragraphs[0]
    para.alignment = WD_ALIGN_PARAGRAPH.CENTER

    # 前缀 "-"
    run_prefix = para.add_run("-")
    set_run_font(run_prefix, "宋体", 14)

    # 页码域代码
    fldChar_begin = OxmlElement('w:fldChar')
    fldChar_begin.set(qn('w:fldCharType'), 'begin')
    run_field = para.add_run()
    run_field._element.append(fldChar_begin)

    instrText = OxmlElement('w:instrText')
    instrText.set(qn('xml:space'), 'preserve')
    instrText.text = ' PAGE '
    run_instr = para.add_run()
    run_instr._element.append(instrText)

    fldChar_end = OxmlElement('w:fldChar')
    fldChar_end.set(qn('w:fldCharType'), 'end')
    run_end = para.add_run()
    run_end._element.append(fldChar_end)

    # 后缀 "-"
    run_suffix = para.add_run("-")
    set_run_font(run_suffix, "宋体", 14)
```

---

## 六、字号对照表

| 字号名称 | 磅值 (pt) | 用途 |
|---------|----------|------|
| 初号 | 42 | |
| 小初 | 36 | |
| 一号 | 26 | |
| 小一 | 24 | |
| 二号 | 22 | 文件标题 |
| 小二 | 18 | |
| **三号** | **16** | **★ 正文及各级标题** |
| 小三 | 15 | |
| 四号 | 14 | 页码 |
| 小四 | 12 | |
| 五号 | 10.5 | |

---

## 七、日期时间写法规范

公文中的时间节点必须具体明确，避免模糊表述。

| 正确写法 | 错误写法 | 说明 |
|---------|---------|------|
| 2024 年 6 月 30 日前 | 6 月底前 | 时间要具体到日 |
| 2024 年 12 月 31 日前完成 | 年底前完成 | 避免“年底”“月底”等模糊表述 |
| 自 2024 年 1 月 1 日起施行 | 自发布之日起施行 | 尽量明确具体日期 |
| 每季度末月 15 日前报送 | 按时报送 | 涉及周期性要求时写明具体日期 |

**原书依据**：会议纪要中，会上领导说的“6月底、4月底”，纪要应当细化到“6月30日前”“4月30日前”，有利于避免因时间要求模糊影响贯彻落实。

---

## 八、数字使用规范

### 使用中文数字的场合

- 公文标题层级编号：一、二、三，（一）（二）（三）
- 成语和惯用语：三令五申、五湖四海、三个吃透
- 概数和约数：几十个、三五天、七八成
- 星期：星期一、星期五

### 使用阿拉伯数字的场合

- 统计数据和精确数值：530 万亩、27.2%、3.5 亿元
- 公历日期：2024 年 3 月 16 日
- 时间：14:30
- 编号和序号：第 1 批、第 2 条
- 千分位使用英文逗号：1,000,000

### 混合使用原则

- 同一段落中，同类数字的写法应保持一致
- 当中文数字和阿拉伯数字混排时，以所在语境为准
- 标题层级用中文数字，正文中的统计数据用阿拉伯数字
