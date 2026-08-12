"""质检抽检清单：每 1000 词抽检 + 全量信号词（无例句/兜底音标/缺失词频）。

输出 work/qa_checklist.md，供内容运营人工抽检（TECH_DOC §10.2 质检规则）：
释义顺序、例句难度、音频清晰度、音标与美音一致性。
"""

from __future__ import annotations

import argparse
from pathlib import Path

from . import common


def _audio_size(audio_dir: Path, key: str) -> str:
    f = audio_dir / f"{key}.mp3"
    return f"{f.stat().st_size} B" if f.exists() else "缺失"


def render(words: list[dict], audio_dir: Path, out: Path) -> None:
    lines = [
        "# 词库质检抽检清单",
        "",
        f"- 词库版本：{common.WORDLIST_NAME}-v{common.VERSION}",
        f"- 总词数：{len(words)}",
        f"- 抽检频率：每 1000 词 + 首词",
        "",
        "## 抽检要点",
        "",
        "1. 释义：顺序是否最常用在前、词性标注是否正确、无词典噪声（[经]/[医] 等）。",
        "2. 例句：难度是否不超高中阅读、句式是否简单自然、署名是否完整。",
        "3. 音频：是否清晰无吞音、与美音发音一致（对照音标）。",
        "4. 音标：是否美式 IPA（兜底 ECDICT 的词需人工复核）。",
        "",
        "## 系统抽检样本",
        "",
        "| 序号 | 单词 | 音标（来源） | 释义 | 例句（署名） | 音频 |",
        "|---|---|---|---|---|---|",
    ]
    step = 1000
    sample_indices = {0} | set(range(0, len(words), step))
    for i in sorted(sample_indices):
        w = words[i]
        meanings = "；".join(
            f"{m['pos']} {m['meaning'][:40]}" for m in w.get("meanings", [])
        )
        ex = w.get("examples", [])
        ex_text = (
            ex[0]["en"][:60] + f"（@{ex[0]['attribution']}）" if ex else "无"
        )
        lines.append(
            f"| {i + 1} | {w['word']} | {w.get('phonetic', '')} "
            f"({w.get('phonetic_source', '')}) | {meanings[:80]} | "
            f"{ex_text[:80]} | {_audio_size(audio_dir, w['audio_key'])} |"
        )

    lines += ["", "## 全量信号词（需人工关注）", ""]
    signals: list[str] = []
    for w in words:
        reasons = []
        if not w.get("examples"):
            reasons.append("无例句")
        if w.get("phonetic_source") == "ecdict-fallback":
            reasons.append("兜底音标")
        if w.get("frq", 0) == 0:
            reasons.append("frq 缺失")
        if reasons:
            signals.append(f"- {w['word']}：{'、'.join(reasons)}")
    lines.append(f"共 {len(signals)} 条信号词：")
    lines += signals
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"质检清单已生成: {out}（抽检 {len(sample_indices)} 词，信号 {len(signals)} 词）")


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="生成质检抽检清单")
    parser.add_argument(
        "--words", type=Path, default=common.WORK_DIR / "words_built.json"
    )
    parser.add_argument("--audio-dir", type=Path, default=common.AUDIO_DIR)
    parser.add_argument("--out", type=Path, default=common.QA_CHECKLIST)
    args = parser.parse_args(argv)
    render(common.json_load(args.words), args.audio_dir, args.out)


if __name__ == "__main__":
    main()
