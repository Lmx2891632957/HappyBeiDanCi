"""内容管线单元测试（stdlib unittest，无网络依赖）。

覆盖：词表对齐、词频分桶、释义解析、word_id 稳定性、例句筛选、
词库 DB 构建（真实 sqlite3）与打包（manifest SHA-256）。
"""

from __future__ import annotations

import bz2
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from pipeline import align_words, build_wordbook, common, package as package_mod  # noqa: E402


def write_ecdict_csv(path: Path) -> None:
    path.write_text(
        "word,phonetic,definition,translation,pos,collins,oxford,tag,bnc,frq,"
        "exchange,detail,audio\n"
        '"abandon","\'x","","n. 放弃\\nvt. 抛弃, 遗弃","n","","","gk","100","50","","",""\n'
        '"ability","\'y","","n. 能力","a","","","gk cet4","200","80","","",""\n'
        '"zebra","\'z","","n. 斑马","n","","","gk","5000","20000","","",""\n'
        '"apple","","","n. 苹果","n","","","cet4","300","90","","",""\n'
        '"book","\'b","","vt. 预定; n. 书","n","","","gk","20","10","","",""\n'
        '"qwerty","","","n. 测试词","n","","","gk","999999","999999","","",""\n'
        '"like","","","v. 喜欢","v","","","","500","300","","",""\n'
        '"read","","","v. 阅读","v","","","","600","400","","",""\n'
        '"books","","","n. 书(复数)","n","","","","610","410","","",""\n'
        '"table","","","n. 桌子","n","","","","1000","800","","",""\n'
        '"plan","","","n. 计划","n","","","","700","450","","",""\n'
        '"completely","","","adv. 完全地","adv","","","","900","700","","",""\n',
        encoding="utf-8",
    )


def write_ipa(path: Path) -> None:
    path.write_text(
        "abandon\t/əˈbændən/\nability\t/əˈbɪɫəti/\nzebra\t/ˈzɛbɹə/\n"
        "book\t/bʊk/\nqwerty\t/ˈkwɜːrti/\n",
        encoding="utf-8",
    )


def write_tatoeba(path: Path, lines: list[str]) -> None:
    with bz2.open(path, "wt", encoding="utf-8") as f:
        for line in lines:
            f.write(line + "\n")


def make_env(tmp: Path) -> dict:
    ecdict = tmp / "ecdict.csv"
    ipa = tmp / "en_US.txt"
    tatoeba = tmp / "eng.tsv.bz2"
    write_ecdict_csv(ecdict)
    write_ipa(ipa)
    write_tatoeba(
        tatoeba,
        [
            "1\teng\tI read a book.\talice\t\\N\t2020-01-01 00:00:00",
            "2\teng\tAbandon the plan completely.\tbob\t\\N\t2020-01-01 00:00:00",
            "3\teng\tThis is a very long sentence that contains many words and "
            "pushes the limit beyond what is allowed here.\tcarol\t\\N\t2020-01-01 00:00:00",
            "4\teng\tThe zebra eats grass.\tcarol\t\\N\t2020-01-01 00:00:00",
            "5\teng\tA book on the table.\tdave\t\\N\t2020-01-01 00:00:00",
            "6\test\t非英语句\tbob\t\\N\t2020-01-01 00:00:00",
            "7\teng\tQwerty appears in this sentence.\terin\t\\N\t2020-01-01 00:00:00",
        ],
    )
    return {"ecdict": ecdict, "ipa": ipa, "tatoeba": tatoeba}


class AlignWordsTest(unittest.TestCase):
    def test_gk_selection_and_official_intersection(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            ecdict = tmp / "ecdict.csv"
            write_ecdict_csv(ecdict)
            words = align_words.align(ecdict, None, tmp / "words.json")
            self.assertEqual(
                [w["word"] for w in words],
                ["abandon", "ability", "book", "qwerty", "zebra"],
            )
            self.assertEqual(words[0]["seq"], 0)
            self.assertEqual(words[-1]["audio_key"], "000004")

            official = tmp / "official.txt"
            official.write_text("abandon\nbook\nzebra\nnot_in_gk\n", encoding="utf-8")
            words2 = align_words.align(ecdict, official, tmp / "words2.json")
            self.assertEqual([w["word"] for w in words2], ["abandon", "book", "zebra"])


class WordIdTest(unittest.TestCase):
    def test_hash_stable_and_distinct(self) -> None:
        a1 = common.word_id_hash("abandon")
        a2 = common.word_id_hash("Abandon")
        self.assertEqual(a1, a2)  # 大小写不敏感（ECDICT 口径）
        self.assertNotEqual(a1, common.word_id_hash("ability"))
        self.assertLess(a1, 1 << 48)

    def test_frequency_buckets(self) -> None:
        self.assertEqual(common.frequency_from_frq(100), "high")
        self.assertEqual(common.frequency_from_frq(4000), "high")
        self.assertEqual(common.frequency_from_frq(4001), "medium")
        self.assertEqual(common.frequency_from_frq(12000), "medium")
        self.assertEqual(common.frequency_from_frq(12001), "low")
        self.assertEqual(common.frequency_from_frq(0), "medium")


class MeaningsTest(unittest.TestCase):
    def test_parse_meanings(self) -> None:
        parsed = build_wordbook.parse_meanings(
            "vt. 放弃, 抛弃\\nn. 放任\\n[经] 废除\\n额外行", "n"
        )
        self.assertEqual(len(parsed), 3)
        self.assertEqual(parsed[0]["pos"], "vt.")
        self.assertEqual(parsed[0]["meaning"], "放弃, 抛弃")
        self.assertFalse(parsed[2]["meaning"].startswith("[经]"))

    def test_pos_fallback(self) -> None:
        parsed = build_wordbook.parse_meanings("能力, 才干", "n")
        self.assertEqual(parsed[0]["pos"], "n.")


class IpaNormalizeTest(unittest.TestCase):
    """音标展示与入库归一化（TECH_DOC §10.2，与 App 显示层口径一致）。"""

    def test_turned_r_to_plain_r(self) -> None:
        self.assertEqual(build_wordbook.normalize_ipa("ˈɹɛd"), "ˈrɛd")
        self.assertEqual(build_wordbook.normalize_ipa("ˈmɪɹɝ"), "ˈmɪrɝ")

    def test_dark_l_to_plain_l(self) -> None:
        self.assertEqual(build_wordbook.normalize_ipa("ˈæpəɫ"), "ˈæpəl")
        self.assertEqual(build_wordbook.normalize_ipa("ˈɫɛvəɫ"), "ˈlɛvəl")
        self.assertEqual(build_wordbook.normalize_ipa("/əˈbɪɫəˌti/"), "əˈbɪləˌti")

    def test_cyrillic_confusables_cleaned(self) -> None:
        self.assertEqual(
            build_wordbook.normalize_ipa("'seilzg\u04d9:l"), "'seilzgə:l"
        )
        self.assertEqual(
            build_wordbook.normalize_ipa("'\u0454\u04d9r\u04d9plein"),
            "'eərəplein",
        )

    def test_surrounding_slashes_stripped(self) -> None:
        self.assertEqual(build_wordbook.normalize_ipa("/ˈstɹeɪndʒ/"), "ˈstreɪndʒ")
        self.assertEqual(build_wordbook.normalize_ipa("/ˈɹɛd/"), "ˈrɛd")

    def test_empty_and_regular_ipa_unchanged(self) -> None:
        self.assertEqual(build_wordbook.normalize_ipa(""), "")
        # 学习者惯例保留集：ɡ/ɝ/ɚ 等严格 IPA 符号不做归一化。
        self.assertEqual(
            build_wordbook.normalize_ipa("ˈæpəl θɛŋk ʃɪp ɑː ɔː ʊ ɪ ɛ ŋ ʒ ð ɡ ɝ"),
            "ˈæpəl θɛŋk ʃɪp ɑː ɔː ʊ ɪ ɛ ŋ ʒ ð ɡ ɝ",
        )

    def test_idempotent(self) -> None:
        src = "ˈɹɛd /ˈstɹeɪndʒ/ ˈæpəɫ 'seilzg\u04d9:l '\u0454\u04d9r\u04d9plein"
        once = build_wordbook.normalize_ipa(src)
        self.assertEqual(build_wordbook.normalize_ipa(once), once)


class BuildWordbookTest(unittest.TestCase):
    def test_build_db_end_to_end(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            env = make_env(tmp)
            words = align_words.align(env["ecdict"], None, tmp / "words.json")
            enriched = build_wordbook.build(
                tmp / "words.json",
                env["ecdict"],
                env["ipa"],
                env["tatoeba"],
                tmp / "wordbook.db",
            )
            conn = sqlite3.connect(tmp / "wordbook.db")
            try:
                self.assertEqual(
                    conn.execute("SELECT value FROM meta WHERE key='wordlist_version'")
                    .fetchone()[0],
                    common.VERSION,
                )
                self.assertEqual(
                    conn.execute("SELECT COUNT(*) FROM words").fetchone()[0], 5
                )
                self.assertEqual(
                    conn.execute("SELECT COUNT(*) FROM wordbook_items").fetchone()[0], 5
                )
                # 音标优先 ipa-dict
                self.assertEqual(
                    conn.execute(
                        "SELECT phonetic FROM words WHERE word='abandon'"
                    ).fetchone()[0],
                    "əˈbændən",
                )
                # ipa-dict 音标同样归一化：ɫ（暗 l）→ l。
                self.assertEqual(
                    conn.execute(
                        "SELECT phonetic FROM words WHERE word='ability'"
                    ).fetchone()[0],
                    "əˈbɪləti",
                )
                # ipa-dict 音标同样归一化：ɹ（turned r）→ r。
                self.assertEqual(
                    conn.execute(
                        "SELECT phonetic FROM words WHERE word='zebra'"
                    ).fetchone()[0],
                    "ˈzɛbrə",
                )
                # 例句署名与筛选（长句被剔除，book 取 2 条短句）
                ex = conn.execute(
                    "SELECT examples FROM words WHERE word='book'"
                ).fetchone()[0]
                examples = json.loads(ex)
                self.assertEqual(len(examples), 2)
                self.assertEqual(examples[0]["attribution"], "alice")
                self.assertTrue(examples[0]["url"].endswith("/1"))
                # qwerty：内容词超纲（bnc 999999）→ 无例句
                ex_q = conn.execute(
                    "SELECT examples FROM words WHERE word='qwerty'"
                ).fetchone()[0]
                self.assertEqual(json.loads(ex_q), [])
            finally:
                conn.close()
            self.assertEqual(len(enriched), 5)


class PackageTest(unittest.TestCase):
    def test_package_manifest_and_zip(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            env = make_env(tmp)
            align_words.align(env["ecdict"], None, tmp / "words.json")
            build_wordbook.build(
                tmp / "words.json",
                env["ecdict"],
                env["ipa"],
                env["tatoeba"],
                tmp / "wordbook.db",
            )
            audio = tmp / "audio"
            audio.mkdir()
            (audio / "000000.mp3").write_bytes(b"fake-mp3-a")
            (audio / "000001.mp3").write_bytes(b"fake-mp3-b")
            out = tmp / "out"
            manifest = package_mod.package(
                tmp / "wordbook.db", audio, out, version="9.9"
            )
            self.assertEqual(manifest["version"], "9.9")
            self.assertEqual(manifest["word_count"], 5)
            db_art = manifest["artifacts"]["wordbook_db"]
            self.assertEqual(db_art["sha256"], common.sha256_file(out / db_art["file"]))
            zip_art = manifest["artifacts"]["audio_zip"]
            self.assertEqual(zip_art["file_count"], 2)
            self.assertEqual(len(manifest["artifacts"]["audio_files"]), 2)
            import zipfile

            with zipfile.ZipFile(out / zip_art["file"]) as zf:
                names = sorted(zf.namelist())
                self.assertEqual(names, ["audio/000000.mp3", "audio/000001.mp3"])


if __name__ == "__main__":
    unittest.main()
