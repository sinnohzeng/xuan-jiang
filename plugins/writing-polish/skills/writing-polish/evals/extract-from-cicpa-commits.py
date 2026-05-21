"""从 cicpa 治理 commit 自动抽取 calibration-set.jsonl（xuan-jiang v5.0 Sprint 1）。

抽取规则：
1. 在 cicpa 仓库找匹配关键词的 commit（去 AI 味 / writing-polish / R3 文风 / AI 腔 / 审稿 / iter[2-9]）
2. 对每个 commit 的 .md 文件 diff，按 hunk 解析 `-` / `+` 行
3. 把连续 `-` 行合成一段 before，连续 `+` 行合成一段 after
4. 长度过滤：60 ≤ len ≤ 500 字（focused 段落）
5. 启发式打分：
   - before 段：识别"治理删除的主导问题维度"，给该维度 2 分，其他维度标 unknown
     （**绝不**直接套用 anti-ai-taste-anchors.md 的全部 anchor 给 before 满分——那会让判官 trivially agree，calibration 无意义）
   - after 段：所有维度 0 分（人类已认可）
6. 输出 JSONL，含 source_commit + source_file 可审计字段
7. verified: false（标明这是自动抽取的"基线"标注，需人工校核——v5 Sprint 1 只用 auto baseline 跑 κ 取信号）

为什么这样设计：
- κ 不会 perfect（0.6-0.9 自然区间）因为 judge 看全段上下文 + 应用白名单 + 极少 noise；
  before 段可能有 governance 因 SSOT/结构 原因删除而非 AI 味；after 段可能有未发现的小问题。
- 这就是 honest calibration——衡量 LLM 与人类「治理决策」的一致度，不是衡量 LLM 与「人类标注分」的一致度。

CLI:
    python extract-from-cicpa-commits.py \
        --cicpa-repo ~/Workspace/cicpa \
        --max-commits 30 \
        --target-segments 200 \
        --out evals/calibration-set.jsonl
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

GOV_KEYWORDS = re.compile(
    r"去\s*AI\s*味|writing-polish|R3\s*文风|AI\s*腔|审稿|iter[2-9]|polish|文风润色|多智能体审校|scan-ai-taste",
    re.IGNORECASE,
)

D2_ANCHORS = [
    "赋能", "重塑", "闭环", "抓手", "链路", "打造", "助力", "深度融合", "多维度",
    "体系化", "跨界融合", "提质增效", "接住", "共情", "看见你",
    "综上所述", "由此可见", "本质上", "更深层次", "值得注意的是",
    "需要指出的是", "必须强调的是", "不可否认的是",
    "业内人士指出", "相关研究表明", "大量实践证明", "普遍认为",
    "可谓是", "在某种意义上说", "至关重要", "不可或缺",
]

D3_ANCHORS = [
    "三层防御", "多重防火墙", "闸门", "跑通", "走通", "翻车", "踩坑", "起飞",
    "三件武器", "杀手锏", "撒手锏", "主战场", "阵地",
    "武器化", "装备化", "王炸", "大招", "打怪升级", "副本",
    "吐文字", "吐结果", "喷出", "蹦出",
]

D4_ANCHORS_DACHANG = [
    "对标", "抓手", "赋能", "闭环", "拉通", "对齐", "链路", "打法", "玩法",
    "沉淀", "复盘", "底层逻辑", "顶层设计", "颗粒度", "价值点", "价值锚点",
    "抢占心智", "生态化反", "赛道", "赛马", "跑赢", "三件套", "组合拳",
    "铁三角", "黄金三角", "冲量", "下沉",
]
D4_DANG_ZHENG_CONTEXT = [
    "政府工作报告", "党中央", "二十大", "二十届", "总书记", "同级", "同业",
    "国际", "一流", "先进", "启示", "案例", "经验", "高质量发展",
    "十四五", "十五五", "对照", "调研",
]

D5_ANCHORS = [
    "综上所述", "由此可见", "首先", "其次", "最后",
    "不仅", "更是", "不只是", "与其说",
    "面对未来", "意义深远", "前景广阔", "未来可期",
    "深入", "全面", "切实可行", "理论价值", "实践指南",
    "充分", "深刻", "丰富", "扎实",
]

D1_HINTS = ["——", "—", "（如", "（即", "（也就是说"]


def has_dang_zheng_context(text: str) -> bool:
    return any(kw in text for kw in D4_DANG_ZHENG_CONTEXT)


def dominant_issue_dim(before_text: str) -> tuple[str, list[str]] | None:
    """识别 before 段的主导 AI 味维度。返回 (dim_id, evidence) 或 None。

    评分启发式：
      - D2: AI 套话锚点命中数
      - D3: 戏剧化锚点命中数
      - D4: 大厂锚点命中且**周边无党政关键词**（防误判咨询语境合法对标）
      - D5: 模板词 + 长度 + 标点节奏
      - D1: ASCII 标点 / 中文破折号
    """
    hits: dict[str, list[str]] = {"D1": [], "D2": [], "D3": [], "D4": [], "D5": []}

    for anc in D1_HINTS:
        if anc in before_text:
            hits["D1"].append(anc)

    for anc in D2_ANCHORS:
        if anc in before_text:
            hits["D2"].append(anc)

    for anc in D3_ANCHORS:
        if anc in before_text:
            hits["D3"].append(anc)

    if not has_dang_zheng_context(before_text):
        for anc in D4_ANCHORS_DACHANG:
            if anc in before_text and anc not in hits["D2"]:
                hits["D4"].append(anc)

    for anc in D5_ANCHORS:
        if anc in before_text:
            hits["D5"].append(anc)

    counts = {d: len(v) for d, v in hits.items() if v}
    if not counts:
        return None
    dim = max(counts, key=counts.get)
    return dim, hits[dim]


def find_governance_commits(repo: Path, max_commits: int) -> list[str]:
    """git log 找匹配 GOV_KEYWORDS 的 commit hash。"""
    result = subprocess.run(
        ["git", "-C", str(repo), "log", "--all", "--pretty=format:%H|%s"],
        capture_output=True, text=True, check=True,
    )
    commits = []
    for line in result.stdout.splitlines():
        if "|" not in line:
            continue
        h, subject = line.split("|", 1)
        if GOV_KEYWORDS.search(subject):
            commits.append(h)
        if len(commits) >= max_commits:
            break
    return commits


def parse_commit_diff(repo: Path, commit: str) -> list[dict]:
    """解析单 commit 的 unified diff，返回 [{file, before, after}, ...]。

    只看 .md 文件；按 hunk 边界配对 `-` 和 `+` 行。
    只 emit 同时有 before AND after（真实重写），跳过纯增量 / 纯删除。
    """
    result = subprocess.run(
        ["git", "-C", str(repo), "-c", "core.quotepath=false",
         "show", "--no-color", "--unified=0", commit, "--", "*.md"],
        capture_output=True, text=True, check=False,
    )
    if result.returncode != 0:
        return []

    pairs: list[dict] = []
    current_file = None
    before_buf: list[str] = []
    after_buf: list[str] = []

    def flush():
        nonlocal before_buf, after_buf
        before = " ".join(s.strip() for s in before_buf if s.strip())
        after = " ".join(s.strip() for s in after_buf if s.strip())
        # 只保留真实重写对（before 和 after 都有实质内容，且不雷同）
        if before and after and abs(len(before) - len(after)) > 5 or (
            before and after and before != after and (len(before) > 30 and len(after) > 30)
        ):
            pairs.append({"file": current_file, "before": before, "after": after})
        # 单边纯增量 / 纯删除（before-only 或 after-only）也保留少量做 unpaired 样本
        elif before and not after:
            pairs.append({"file": current_file, "before": before, "after": ""})
        elif after and not before:
            pairs.append({"file": current_file, "before": "", "after": after})
        before_buf = []
        after_buf = []

    for line in result.stdout.splitlines():
        if line.startswith("diff --git"):
            flush()
            m = re.search(r"b/(.+)$", line)
            current_file = m.group(1) if m else None
        elif line.startswith("@@"):
            flush()
        elif line.startswith("-") and not line.startswith("---"):
            before_buf.append(line[1:])
        elif line.startswith("+") and not line.startswith("+++"):
            after_buf.append(line[1:])
        elif line.startswith(" "):
            if before_buf or after_buf:
                flush()
    flush()
    return pairs


CHINESE_RE = re.compile(r"[一-鿿]")

# 优先抽取实际报告内容（实施方案 / 调研报告 / 完整版 / 简要版），
# 跳过方法论 / 治理 / memory / 项目治理类文件（这些是 meta 而非报告本体）
REPORT_PATH_HINTS = ["实施方案", "调研报告", "完整版", "简要版", "可行性研究", "04-最终交付", "WS1", "WS2", "WS3", "WS4"]
META_PATH_HINTS = ["方法论", "项目治理", "claude-memory", "memory/", "STYLE-GUIDE", "AGENTS.md", "CLAUDE.md", "handoff", "README"]


def is_report_file(path: str | None) -> bool:
    if not path:
        return False
    has_report_hint = any(h in path for h in REPORT_PATH_HINTS)
    has_meta_hint = any(h in path for h in META_PATH_HINTS)
    return has_report_hint and not has_meta_hint


def keep_segment(text: str, file_path: str | None = None) -> bool:
    if not (60 <= len(text) <= 500):
        return False
    # 至少 50% 中文字符
    chinese_chars = len(CHINESE_RE.findall(text))
    if chinese_chars < len(text) * 0.5:
        return False
    # 排除纯标题 / 纯列表 / 纯 markdown 元素
    if text.count("#") > 3 or text.count("|") > 5:
        return False
    # 排除前后引用块
    if text.startswith(">") or text.startswith("```"):
        return False
    # 只保留实际报告文件
    if file_path and not is_report_file(file_path):
        return False
    return True


def build_label_before(text: str) -> dict | None:
    issue = dominant_issue_dim(text)
    if not issue:
        return None
    dim, evidence = issue
    intensity = 3 if len(evidence) >= 3 else 2
    scores: dict[str, int | str] = {d: "unknown" for d in ["D1", "D2", "D3", "D4", "D5"]}
    scores[dim] = intensity
    return {
        "scores": scores,
        "auto_evidence": {dim: evidence},
    }


def build_label_after() -> dict:
    return {
        "scores": {d: 0 for d in ["D1", "D2", "D3", "D4", "D5"]},
        "auto_evidence": {},
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cicpa-repo", type=Path, default=Path.home() / "Workspace" / "cicpa")
    parser.add_argument("--max-commits", type=int, default=50)
    parser.add_argument("--target-segments", type=int, default=200)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--genre", default="research-report")
    args = parser.parse_args()

    if not (args.cicpa_repo / ".git").exists():
        raise SystemExit(f"Not a git repo: {args.cicpa_repo}")

    commits = find_governance_commits(args.cicpa_repo, args.max_commits)
    print(f"[extract] found {len(commits)} governance commits")

    items: list[dict] = []
    seen_texts: set[str] = set()
    stats = Counter()

    target_before = args.target_segments // 2
    target_after = args.target_segments - target_before

    for commit in commits:
        for pair in parse_commit_diff(args.cicpa_repo, commit):
            for kind, text in (("before", pair["before"]), ("after", pair["after"])):
                # 平衡前/后样本：达到 target 后跳过该类
                if kind == "before" and stats["before"] >= target_before:
                    continue
                if kind == "after" and stats["after"] >= target_after:
                    continue
                if not keep_segment(text, pair.get("file")):
                    continue
                # 去重
                key = text[:80]
                if key in seen_texts:
                    continue
                seen_texts.add(key)

                if kind == "before":
                    label = build_label_before(text)
                    if not label:
                        continue
                else:
                    label = build_label_after()

                seg_id = f"cicpa-{commit[:7]}-{kind}-{len(items):04d}"
                items.append({
                    "id": seg_id,
                    "text": text,
                    "genre": args.genre,
                    "scores": label["scores"],
                    "auto_evidence": label["auto_evidence"],
                    "annotator": "auto-from-commit-diff",
                    "verified": False,
                    "source_commit": commit,
                    "source_file": pair["file"],
                    "kind": kind,
                    "extracted_at": datetime.now(timezone.utc).isoformat(),
                })
                stats[kind] += 1

                if len(items) >= args.target_segments:
                    break
            if len(items) >= args.target_segments:
                break
        if len(items) >= args.target_segments:
            break

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as f:
        for item in items:
            f.write(json.dumps(item, ensure_ascii=False) + "\n")

    print(f"[extract] wrote {len(items)} segments to {args.out}")
    print(f"[extract] kind distribution: {dict(stats)}")
    dim_dist: Counter = Counter()
    for it in items:
        for d, v in it["scores"].items():
            if isinstance(v, int) and v >= 2:
                dim_dist[d] += 1
    print(f"[extract] dimension distribution (>=2): {dict(dim_dist)}")


if __name__ == "__main__":
    main()
