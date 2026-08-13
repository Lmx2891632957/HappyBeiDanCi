"""词表对齐：以 ECDICT gk 标签为基准种子，可选与官方词表取交集。

输出 work/words.json（每词含 ECDICT 释义/音标/bnc/frq 原始字段与 seq），
供 build_wordbook 阶段消费。未提供官方词表时以 gk 全集为准（TECH_DOC §10.2）。
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

from . import common


def load_ecdict_gk(path: Path) -> list[dict]:
    """读取 ECDICT CSV，返回 tag 含 gk 的词条（小写规范、按词去重）。"""
    rows: dict[str, dict] = {}
    with path.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for r in reader:
            tags = (r.get("tag") or "").split()
            if "gk" not in tags:
                continue
            word = (r.get("word") or "").strip().lower()
            if not word:
                continue
            # 同词多行（罕见）保留首行；大小写不敏感（ECDICT 官方口径）。
            rows.setdefault(word, r)
    return [rows[w] for w in sorted(rows)]


def load_official_words(path: Path) -> set[str]:
    """读取官方/第三方考纲词表纯文本（每行一词，忽略空行与注释行）。"""
    words = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        words.add(line.lower())
    return words


def align(
    ecdict_csv: Path,
    official: Path | None,
    out: Path,
) -> list[dict]:
    gk_rows = load_ecdict_gk(ecdict_csv)
    report = [f"ECDICT gk 种子数: {len(gk_rows)}"]
    if official is not None:
        official_words = load_official_words(official)
        report.append(f"官方词表词数: {len(official_words)}")
        kept = []
        dropped = []
        for row in gk_rows:
            word = (row["word"] or "").strip().lower()
            if word in official_words:
                kept.append(row)
            else:
                dropped.append(word)
        # 官方词表中存在但 ECDICT gk 未标注的词：无释义数据，不能入词库，
        # 仅记录供人工核对（M1 不扩表）。
        gk_words = {r["word"].strip().lower() for r in gk_rows}
        official_missing = sorted(official_words - gk_words)
        report.append(f"交集后词数: {len(kept)}")
        report.append(f"gk 有而官方无（剔除）: {len(dropped)}")
        report.append(f"官方有而 gk 无（无释义，不入库）: {len(official_missing)}")
        gk_rows = kept

    words = []
    for seq, row in enumerate(gk_rows):
        word = (row["word"] or "").strip().lower()
        frq = _int_or_zero(row.get("frq"))
        bnc = _int_or_zero(row.get("bnc"))
        words.append(
            {
                "word": word,
                "seq": seq,
                "phonetic_ecdict": (row.get("phonetic") or "").strip(),
                "translation": (row.get("translation") or "").strip(),
                "pos": (row.get("pos") or "").strip(),
                "bnc": bnc,
                "frq": frq,
                "audio_key": f"{seq:06d}",
            }
        )

    common.json_dump(out, words)
    report.append(f"最终词数: {len(words)}")
    report_text = "\n".join(report)
    print(report_text)
    common.WORK_DIR.mkdir(parents=True, exist_ok=True)
    (common.WORK_DIR / "wordlist_report.txt").write_text(
        report_text + "\n", encoding="utf-8"
    )
    return words


def _int_or_zero(value: str | None) -> int:
    try:
        return int(value or 0)
    except ValueError:
        return 0


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="词表对齐（ECDICT gk 基准）")
    parser.add_argument(
        "--ecdict", type=Path, default=common.ECDICT_CSV, help="ECDICT CSV 路径"
    )
    parser.add_argument(
        "--official",
        type=Path,
        default=None,
        help="官方考纲词表纯文本（可选，每行一词），传入时做交集对齐",
    )
    parser.add_argument("--out", type=Path, default=common.WORDS_JSON)
    args = parser.parse_args(argv)
    align(args.ecdict, args.official, args.out)


if __name__ == "__main__":
    main()
