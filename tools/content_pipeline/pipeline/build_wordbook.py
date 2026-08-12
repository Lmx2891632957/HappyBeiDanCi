"""词库构建：释义/音标/例句提取，产出发布版词库 DB。

数据流（TECH_DOC §10.1）：words.json + ipa-dict en_US（美音音标主源）+
ECDICT（释义/兜底音标/bnc）+ Tatoeba Detailed（例句+署名）→ wordbook.db。

内存策略：Tatoeba 2M+ 句先做一轮"含 gk 词"候选过滤（保留句子原文），再按词
建候选索引（array 存句子下标），避免为每个词复制整句文本（TECH_DOC §12 同源
思路：大数据量下用紧凑结构）。
"""

from __future__ import annotations

import argparse
import bz2
import csv
import json
import re
import sqlite3
import time
from array import array
from pathlib import Path

from . import common


# ---------------------------------------------------------------------------
# 音标
# ---------------------------------------------------------------------------
def load_ipa(path: Path) -> dict[str, str]:
    """加载 ipa-dict en_US：词 → 首个 IPA（一词多音取第一个，文档见 §10.4）。"""
    ipa: dict[str, str] = {}
    with path.open(encoding="utf-8") as f:
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) != 2:
                continue
            word = parts[0].strip().lower()
            phonemes = [p.strip() for p in parts[1].split(",") if p.strip()]
            if word and phonemes:
                ipa[word] = phonemes[0]
    return ipa


# ---------------------------------------------------------------------------
# 释义
# ---------------------------------------------------------------------------
def _first_pos(pos_field: str) -> str:
    for token in pos_field.split("/"):
        token = token.strip()
        if token:
            return token if token.endswith(".") else f"{token}."
    return ""


def parse_meanings(translation: str, pos_field: str) -> list[dict]:
    """从 ECDICT translation 提取 1–3 条释义（TECH_DOC §10.2）。

    义项按行序保留（ECDICT 已按词频粗排）；行内 [经]/[医] 等噪声前缀剔除，
    词性优先取行内前缀（n./vt./a. 等），缺失时回退 pos 字段。
    """
    out: list[dict] = []
    # ECDICT CSV 中换行以字面 "\n" 存储（不是真实换行），两种都兼容。
    for raw in re.split(r"\\n|\n", translation.replace("\r", "")):
        line = common.BRACKET_NOISE_RE.sub("", raw).strip()
        if not line:
            continue
        m = common.POS_RE.match(line)
        if m:
            pos = m.group(1).rstrip(".") + "."
            meaning = m.group(2).strip()
        else:
            pos = _first_pos(pos_field)
            meaning = line
        if not meaning:
            continue
        out.append({"pos": pos, "meaning": meaning})
        if len(out) >= 3:
            break
    return out


# ---------------------------------------------------------------------------
# 例句（Tatoeba）
# ---------------------------------------------------------------------------
class SentenceIndex:
    """Tatoeba 英语句子的紧凑倒排索引。

    records: [(sid, text, username)] 仅保留长度达标且含 gk 词的句子；
    per_word: dict[词 -> array('I')] 记录下标，避免为每个词复制整句。
    """

    def __init__(self) -> None:
        self.records: list[tuple[int, str, str]] = []
        self.per_word: dict[str, array] = {}

    def add(self, sid: int, text: str, username: str, tokens: list[str], gk: set[str]) -> None:
        if not (common.MIN_SENTENCE_WORDS <= len(tokens) <= common.MAX_SENTENCE_WORDS):
            return
        present = {t for t in tokens if t in gk}
        if not present:
            return
        idx = len(self.records)
        self.records.append((sid, text, username))
        for w in present:
            self.per_word.setdefault(w, array("I")).append(idx)


def build_sentence_index(
    tatoeba_bz2: Path, gk: set[str]
) -> SentenceIndex:
    print("构建 Tatoeba 倒排索引（仅含 gk 词的句子）…")
    idx = SentenceIndex()
    skipped = 0
    with bz2.open(tatoeba_bz2, "rt", encoding="utf-8", errors="replace") as f:
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 4 or parts[1] != "eng":
                skipped += 1
                continue
            try:
                sid = int(parts[0])
            except ValueError:
                skipped += 1
                continue
            text = parts[2].strip()
            username = parts[3].strip()
            tokens = common.tokenize(text)
            idx.add(sid, text, username, tokens, gk)
    print(f"  候选句 {len(idx.records)}（跳过 {skipped} 非 eng/格式异常行）")
    return idx


def select_examples(
    word: str, sentence_idx: SentenceIndex, gk: set[str], bnc: dict[str, int]
) -> list[dict]:
    """按 TECH_DOC §10.2 例句规则筛选：句长达标（构建期已过滤）、内容词不超纲、
    优先短句、每词至多 2 句；返回带署名与句子链接的条目。
    """
    candidates: list[tuple[int, str, str]] = []
    seen_texts: set[str] = set()
    for i in sentence_idx.per_word.get(word, ()):
        sid, text, username = sentence_idx.records[i]
        if text in seen_texts:
            continue
        tokens = common.tokenize(text)
        if word not in tokens:
            continue
        # 内容词覆盖检查：gk 集 / 功能词白名单 / ECDICT bnc ≤ 阈值。
        if any(
            t not in gk
            and t not in common.FUNCTION_WORDS
            and bnc.get(t, 10**9) > common.BNC_THRESHOLD
            for t in tokens
        ):
            continue
        seen_texts.add(text)
        candidates.append((len(tokens), sid, text, username))

    candidates.sort(key=lambda c: (c[0], c[1]))  # 优先短句，其次句子 ID（稳定）
    examples = []
    for _, sid, text, username in candidates[: common.MAX_EXAMPLES_PER_WORD]:
        examples.append(
            {
                "en": text,
                "source": "Tatoeba",
                "attribution": username or "Tatoeba contributor",
                "url": f"https://tatoeba.org/en/sentences/show/{sid}",
            }
        )
    return examples


def load_bnc_map(ecdict_csv: Path) -> dict[str, int]:
    """ECDICT word → bnc 词频序（例句内容词超纲检查用；0 视为无排名）。"""
    bnc: dict[str, int] = {}
    with ecdict_csv.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for r in reader:
            word = (r.get("word") or "").strip().lower()
            if not word:
                continue
            try:
                bnc[word] = int(r.get("bnc") or 0)
            except ValueError:
                bnc[word] = 0
    return bnc


# ---------------------------------------------------------------------------
# 词库 DB
# ---------------------------------------------------------------------------
def build_db(
    words: list[dict],
    examples: dict[str, list[dict]],
    phonetics: dict[str, tuple[str, str]],  # word -> (phonetic, source)
    out: Path,
) -> None:
    """构建发布版词库 DB（表结构与 Drift words/wordbooks/wordbook_items 一致，
    供 App 导入整体复制；多一张 meta 表记录版本，导入端忽略之）。
    """
    if out.exists():
        out.unlink()
    conn = sqlite3.connect(out)
    try:
        conn.executescript(
            """
            CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
            CREATE TABLE wordbooks (
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              level TEXT NOT NULL,
              total_count INTEGER NOT NULL,
              source TEXT NOT NULL,
              sort_order INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL
            );
            CREATE TABLE words (
              id INTEGER PRIMARY KEY,
              word TEXT NOT NULL UNIQUE,
              phonetic TEXT NOT NULL,
              phonetic_uk TEXT,
              meanings TEXT NOT NULL,
              examples TEXT NOT NULL,
              frequency TEXT NOT NULL,
              root_affix TEXT,
              audio_key TEXT NOT NULL,
              audio_url TEXT,
              created_at INTEGER NOT NULL
            );
            CREATE TABLE wordbook_items (
              wordbook_id INTEGER NOT NULL,
              word_id INTEGER NOT NULL,
              seq INTEGER NOT NULL,
              shuffled INTEGER NOT NULL,
              is_skipped INTEGER NOT NULL DEFAULT 0,
              PRIMARY KEY (wordbook_id, word_id)
            );
            """
        )
        now_ms = int(time.time() * 1000)
        conn.execute(
            "INSERT INTO meta (key, value) VALUES (?, ?)",
            ("wordlist_version", common.VERSION),
        )
        conn.execute(
            "INSERT INTO meta (key, value) VALUES (?, ?)",
            ("schema_version", "1"),
        )
        conn.execute(
            "INSERT INTO meta (key, value) VALUES (?, ?)",
            ("created_at", str(now_ms)),
        )
        conn.execute(
            "INSERT INTO wordbooks (id, name, level, total_count, source, "
            "sort_order, created_at) VALUES (?, ?, ?, ?, ?, 0, ?)",
            (
                common.BOOK_ID,
                common.BOOK_NAME,
                common.BOOK_LEVEL,
                len(words),
                common.BOOK_SOURCE,
                now_ms,
            ),
        )
        used_ids: dict[int, str] = {}
        word_rows = []
        item_rows = []
        for w in words:
            wid = common.word_id_hash(w["word"])
            if wid in used_ids:
                raise RuntimeError(
                    f"word_id 哈希碰撞: {used_ids[wid]} / {w['word']} -> {wid}"
                )
            used_ids[wid] = w["word"]
            phonetic, phon_src = phonetics[w["word"]]
            word_rows.append(
                (
                    wid,
                    w["word"],
                    phonetic,
                    None,
                    json.dumps(
                        parse_meanings(w["translation"], w["pos"]),
                        ensure_ascii=False,
                    ),
                    json.dumps(
                        examples.get(w["word"], []), ensure_ascii=False
                    ),
                    common.frequency_from_frq(w["frq"]),
                    None,
                    w["audio_key"],
                    common.DEFAULT_AUDIO_URL_TEMPLATE.format(key=w["audio_key"]),
                    now_ms,
                )
            )
            item_rows.append(
                (common.BOOK_ID, wid, w["seq"], w["seq"], 0)
            )
            _ = phon_src  # 音标来源随 QA 清单输出，DB 不冗余
        conn.executemany(
            "INSERT INTO words (id, word, phonetic, phonetic_uk, meanings, examples, "
            "frequency, root_affix, audio_key, audio_url, created_at) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            word_rows,
        )
        conn.executemany(
            "INSERT INTO wordbook_items (wordbook_id, word_id, seq, shuffled, "
            "is_skipped) VALUES (?, ?, ?, ?, ?)",
            item_rows,
        )
        conn.commit()
        integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
        if integrity != "ok":
            raise RuntimeError(f"词库 DB 完整性校验失败: {integrity}")
    finally:
        conn.close()
    print(f"词库 DB 已生成: {out}（{len(words)} 词，完整性 ok）")


# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
def build(
    words_json: Path,
    ecdict_csv: Path,
    ipa_txt: Path,
    tatoeba_bz2: Path,
    out: Path,
) -> list[dict]:
    words = common.json_load(words_json)
    gk = {w["word"] for w in words}
    print(f"目标词数: {len(gk)}")

    ipa = load_ipa(ipa_txt)
    phonetics: dict[str, tuple[str, str]] = {}
    ipa_cover = 0
    for w in words:
        p = ipa.get(w["word"])
        if p:
            phonetics[w["word"]] = (p, "ipa-dict")
            ipa_cover += 1
        else:
            # 兜底：ECDICT 音标（英式/混合风格，见 PRD §7.2 补充说明）。
            phonetics[w["word"]] = (w["phonetic_ecdict"] or "", "ecdict-fallback")
    print(f"ipa-dict 音标覆盖: {ipa_cover}/{len(words)}")

    print("加载 ECDICT bnc 词频表…")
    bnc = load_bnc_map(ecdict_csv)
    sentence_idx = build_sentence_index(tatoeba_bz2, gk)

    examples: dict[str, list[dict]] = {}
    no_example = 0
    for i, w in enumerate(words):
        ex = select_examples(w["word"], sentence_idx, gk, bnc)
        examples[w["word"]] = ex
        if not ex:
            no_example += 1
        if (i + 1) % 500 == 0:
            print(f"  例句筛选进度: {i + 1}/{len(words)}（无例句 {no_example}）")
    print(f"例句筛选完成，无例句词数: {no_example}")

    build_db(words, examples, phonetics, out)

    # 输出富化 JSON（QA 清单与发布记录用）。
    enriched = []
    for w in words:
        phonetic, phon_src = phonetics[w["word"]]
        enriched.append(
            {
                **w,
                "phonetic": phonetic,
                "phonetic_source": phon_src,
                "frequency": common.frequency_from_frq(w["frq"]),
                "meanings": parse_meanings(w["translation"], w["pos"]),
                "examples": examples[w["word"]],
            }
        )
    common.json_dump(common.WORK_DIR / "words_built.json", enriched)
    return enriched


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="构建发布版词库 DB")
    parser.add_argument("--words", type=Path, default=common.WORDS_JSON)
    parser.add_argument("--ecdict", type=Path, default=common.ECDICT_CSV)
    parser.add_argument("--ipa", type=Path, default=common.IPA_EN_US)
    parser.add_argument("--tatoeba", type=Path, default=common.TATOEBA_EN_DETAILED)
    parser.add_argument("--out", type=Path, default=common.WORDBOOK_DB)
    args = parser.parse_args(argv)
    build(args.words, args.ecdict, args.ipa, args.tatoeba, args.out)


if __name__ == "__main__":
    main()
