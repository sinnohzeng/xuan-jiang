"""Cohen's κ 计算（xuan-jiang v5.0 calibration）。

输入：
- gold:    JSONL，每行 {id, scores: {D1..D5}}（calibration-set.jsonl）
- predict: JSONL，每行 {id, scores: {D1..D5}}（judge 输出展平）

输出：
- cohen_kappa.json:   {"D1": 0.92, "D2": 0.85, ..., "overall": 0.87, "per_dim_detail": {...}}
- disagreement.md:    模型 vs 人类金标准差异列表（最有学习价值的样本）
- per_segment.csv:    每段每维度的 gold / predict 对照

仅依赖 stdlib（不强依赖 sklearn）：weighted Cohen κ 自实现，
支持 unknown 标签自动排除（不计入分母）。

CLI:
    python cohen-kappa.py \
        --gold evals/calibration-set.jsonl \
        --predict /tmp/judge-results.jsonl \
        --out-dir evals/calibration-results
"""

from __future__ import annotations

import argparse
import csv
import json
from collections import defaultdict
from pathlib import Path
from typing import Any

DIMENSIONS = ["D1", "D2", "D3", "D4", "D5"]
LABELS = [0, 1, 2, 3]


def cohen_kappa(y1: list[int], y2: list[int], labels: list[int]) -> float:
    """二评分者 Cohen's κ（unweighted, nominal categories）。

    κ = (po - pe) / (1 - pe)
    po: 观察一致率 = Σ_i confusion[i][i] / N
    pe: 偶然一致率 = Σ_i (row_sum[i] * col_sum[i]) / N²
    """
    if len(y1) != len(y2) or not y1:
        return float("nan")

    n = len(y1)
    idx = {label: i for i, label in enumerate(labels)}
    cm = [[0] * len(labels) for _ in labels]
    for a, b in zip(y1, y2):
        if a not in idx or b not in idx:
            return float("nan")  # 未知标签，跳过整次计算
        cm[idx[a]][idx[b]] += 1

    po = sum(cm[i][i] for i in range(len(labels))) / n
    row_sums = [sum(row) for row in cm]
    col_sums = [sum(cm[r][c] for r in range(len(labels))) for c in range(len(labels))]
    pe = sum((row_sums[i] / n) * (col_sums[i] / n) for i in range(len(labels)))

    if pe == 1.0:
        return 1.0 if po == 1.0 else float("nan")
    return (po - pe) / (1.0 - pe)


def load_jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def normalize_score(v: Any) -> int | None:
    """gold + predict 共用：unknown → None（不计入κ），其他归到 0-3 int。"""
    if v == "unknown" or v is None:
        return None
    if isinstance(v, bool):
        return None
    if isinstance(v, int) and 0 <= v <= 3:
        return v
    if isinstance(v, float) and v == int(v) and 0 <= int(v) <= 3:
        return int(v)
    if isinstance(v, str) and v.strip().isdigit():
        x = int(v)
        return x if 0 <= x <= 3 else None
    return None


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--gold", type=Path, required=True)
    parser.add_argument("--predict", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    args = parser.parse_args()

    args.out_dir.mkdir(parents=True, exist_ok=True)

    gold_items = {i["id"]: i for i in load_jsonl(args.gold)}
    pred_items = {i["id"]: i for i in load_jsonl(args.predict)}

    common_ids = sorted(set(gold_items) & set(pred_items))
    print(f"[κ] gold={len(gold_items)} predict={len(pred_items)} common={len(common_ids)}")

    # 每维度独立 κ
    per_dim: dict[str, dict[str, Any]] = {}
    rows: list[dict[str, Any]] = []
    disagreements: list[dict[str, Any]] = []

    for dim in DIMENSIONS:
        y_gold: list[int] = []
        y_pred: list[int] = []
        excluded_unknown = 0
        for sid in common_ids:
            g = normalize_score(gold_items[sid]["scores"].get(dim))
            p = normalize_score(pred_items[sid]["scores"].get(dim))
            if g is None or p is None:
                excluded_unknown += 1
                continue
            y_gold.append(g)
            y_pred.append(p)
            if g != p:
                disagreements.append({
                    "segment_id": sid,
                    "dim": dim,
                    "gold": g,
                    "predict": p,
                    "gold_evidence": gold_items[sid].get("auto_evidence", {}).get(dim, []),
                    "predict_evidence": pred_items[sid].get("evidence", {}).get(dim, []),
                    "predict_reasoning": pred_items[sid].get("reasoning_samples", [""])[0]
                        if pred_items[sid].get("reasoning_samples") else "",
                    "text": gold_items[sid]["text"][:200],
                })

        kappa = cohen_kappa(y_gold, y_pred, LABELS) if y_gold else float("nan")
        accuracy = sum(1 for a, b in zip(y_gold, y_pred) if a == b) / len(y_gold) if y_gold else float("nan")
        per_dim[dim] = {
            "kappa": round(kappa, 3) if kappa == kappa else None,  # NaN guard
            "accuracy": round(accuracy, 3) if accuracy == accuracy else None,
            "n_scored": len(y_gold),
            "n_excluded_unknown": excluded_unknown,
            "agreement_pct": round(accuracy * 100, 1) if accuracy == accuracy else None,
        }
        print(f"[κ] {dim}: κ={per_dim[dim]['kappa']} acc={per_dim[dim]['agreement_pct']}% (n={len(y_gold)}, unk={excluded_unknown})")

    # Overall（按 scored 段数加权的平均 κ）
    weighted_kappa: float = 0.0
    total_n = 0
    for dim in DIMENSIONS:
        if per_dim[dim]["kappa"] is not None and per_dim[dim]["n_scored"] > 0:
            weighted_kappa += per_dim[dim]["kappa"] * per_dim[dim]["n_scored"]
            total_n += per_dim[dim]["n_scored"]
    overall = round(weighted_kappa / total_n, 3) if total_n else None

    result = {
        "overall_weighted_kappa": overall,
        "per_dim": per_dim,
        "n_common_segments": len(common_ids),
        "n_disagreements": len(disagreements),
    }
    (args.out_dir / "cohen_kappa.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"[κ] overall weighted κ = {overall}")

    # disagreement.md
    disagreement_md = ["# Disagreement Report (xuan-jiang v5 calibration)", ""]
    disagreement_md.append(f"Total disagreements: **{len(disagreements)}** out of {len(common_ids)} common segments × 5 dims")
    disagreement_md.append("")
    disagreement_md.append("## Per-dimension summary")
    disagreement_md.append("")
    disagreement_md.append("| Dim | κ | Accuracy | n scored | n excluded (unknown) |")
    disagreement_md.append("|---|---|---|---|---|")
    for dim in DIMENSIONS:
        d = per_dim[dim]
        disagreement_md.append(
            f"| {dim} | {d['kappa']} | {d['agreement_pct']}% | {d['n_scored']} | {d['n_excluded_unknown']} |"
        )
    disagreement_md.append("")
    disagreement_md.append(f"**Overall weighted κ**: `{overall}`")
    disagreement_md.append("")
    disagreement_md.append("## Top disagreements (predict vs gold, sorted by gap)")
    disagreement_md.append("")
    disagreements.sort(key=lambda d: abs(d["gold"] - d["predict"]), reverse=True)
    for i, d in enumerate(disagreements[:30]):
        disagreement_md.append(f"### {i+1}. {d['segment_id']} / {d['dim']}: gold={d['gold']} vs predict={d['predict']}")
        if d["gold_evidence"]:
            disagreement_md.append(f"- **gold (auto-extract) evidence**: {d['gold_evidence']}")
        if d["predict_evidence"]:
            disagreement_md.append(f"- **predict (judge) evidence**: {d['predict_evidence']}")
        if d["predict_reasoning"]:
            disagreement_md.append(f"- **predict reasoning**: {d['predict_reasoning']}")
        disagreement_md.append(f"- text: {d['text']}")
        disagreement_md.append("")
    (args.out_dir / "disagreement.md").write_text("\n".join(disagreement_md), encoding="utf-8")

    # per_segment.csv
    csv_path = args.out_dir / "per_segment.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["segment_id"] + [f"{d}_gold" for d in DIMENSIONS] + [f"{d}_predict" for d in DIMENSIONS])
        for sid in common_ids:
            row = [sid]
            for d in DIMENSIONS:
                row.append(gold_items[sid]["scores"].get(d))
            for d in DIMENSIONS:
                row.append(pred_items[sid]["scores"].get(d))
            writer.writerow(row)

    print(f"[κ] wrote {args.out_dir}/{{cohen_kappa.json, disagreement.md, per_segment.csv}}")


if __name__ == "__main__":
    main()
