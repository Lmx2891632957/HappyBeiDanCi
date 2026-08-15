"""内容管线公共配置与工具函数。

数据源地址、词库版本号、词频阈值、word_id 哈希策略等"看似随意实则有意"的常量
集中在此，与 TECH_DOC §10 一一对应；修改阈值/版本需同步 TECH_DOC。
"""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

# ---------------------------------------------------------------------------
# 目录布局（raw/ 与 work/ 已 .gitignore，不进源码仓库；output/ 亦已忽略）
# ---------------------------------------------------------------------------
ROOT = Path(__file__).resolve().parents[1]  # tools/content_pipeline/
RAW_DIR = ROOT / "raw"
WORK_DIR = ROOT / "work"
OUTPUT_DIR = ROOT / "output"
AUDIO_DIR = WORK_DIR / "audio"

# ---------------------------------------------------------------------------
# 词库发布版本（与 App 代码版本解耦，AGENTS §5.3；tag 形如
# wordbook-gaokao-3500-v1.0）
# ---------------------------------------------------------------------------
WORDLIST_NAME = "wordbook-gaokao-3500"
VERSION = "1.0"
BOOK_ID = 1
BOOK_NAME = "高考大纲词汇 3500"
BOOK_LEVEL = "gaokao"
BOOK_SOURCE = "ECDICT(gk) + ipa-dict + Tatoeba + Edge TTS"

# 打包产物目录名（manifest 与 artifact 统一放在该目录下）
def package_dir(version: str = VERSION) -> Path:
    return OUTPUT_DIR / f"{WORDLIST_NAME}-v{version}"


def artifact_db_name(version: str = VERSION) -> str:
    return f"{WORDLIST_NAME}-v{version}.db"


def artifact_audio_name(version: str = VERSION) -> str:
    return f"audio-{WORDLIST_NAME}-v{version}.zip"


# ---------------------------------------------------------------------------
# 数据源（TECH_DOC §10.4 实测地址；如需换镜像只改这里）
# ---------------------------------------------------------------------------
ECDICT_CSV_URL = (
    "https://raw.githubusercontent.com/skywind3000/ECDICT/master/ecdict.csv"
)
TATOEBA_EN_DETAILED_URL = (
    "https://downloads.tatoeba.org/exports/per_language/eng/"
    "eng_sentences_detailed.tsv.bz2"
)
IPA_EN_US_URL = (
    "https://raw.githubusercontent.com/open-dict-data/ipa-dict/master/data/en_US.txt"
)

ECDICT_CSV = RAW_DIR / "ecdict.csv"
TATOEBA_EN_DETAILED = RAW_DIR / "eng_sentences_detailed.tsv.bz2"
IPA_EN_US = RAW_DIR / "en_US.txt"

WORDS_JSON = WORK_DIR / "words.json"
WORDBOOK_DB = WORK_DIR / "wordbook.db"
QA_CHECKLIST = WORK_DIR / "qa_checklist.md"
TTS_FAILURES = WORK_DIR / "tts_failures.txt"

# ---------------------------------------------------------------------------
# 内容口径（TECH_DOC §10.2）
# ---------------------------------------------------------------------------
# 考频代理：ECDICT frq（当代语料库词频序）分桶阈值；缺失按 medium。
FREQ_HIGH_MAX = 4000
FREQ_MEDIUM_MAX = 12000

# 例句筛选：句长上界与 BNC 词频上界（内容词不在 gk 集内时按此阈值豁免）。
MAX_SENTENCE_WORDS = 18
MIN_SENTENCE_WORDS = 3
BNC_THRESHOLD = 30000
MAX_EXAMPLES_PER_WORD = 2

# 功能词白名单：例句筛选中免 BNC 校验的高频语法词。
FUNCTION_WORDS = {
    "a", "an", "the", "and", "or", "but", "nor", "so", "for", "yet",
    "of", "to", "in", "on", "at", "by", "with", "from", "into", "about",
    "as", "than", "if", "when", "while", "because", "that", "which",
    "who", "whom", "whose", "what", "where", "how", "why", "this",
    "these", "those", "there", "here", "it", "its", "he", "him", "his",
    "she", "her", "they", "them", "their", "we", "us", "our", "you",
    "your", "i", "me", "my", "be", "am", "is", "are", "was", "were",
    "been", "being", "do", "does", "did", "done", "have", "has", "had",
    "will", "would", "shall", "should", "can", "could", "may", "might",
    "must", "not", "no", "yes", "all", "some", "any", "every", "each",
    "both", "either", "neither", "other", "another", "much", "many",
    "more", "most", "few", "little", "less", "least", "very", "too",
    "also", "just", "only", "even", "still", "already", "again", "ever",
    "never", "always", "often", "sometimes", "usually", "well", "up",
    "down", "out", "off", "over", "under", "before", "after", "between",
    "through", "during", "without", "within", "against", "among", "along",
    "around", "behind", "below", "beside", "beyond", "onto", "upon",
    "toward", "towards", "s", "t", "m", "d", "ll", "re", "ve", "o",
}

# Edge TTS：美音女声；限速间隔与重试策略（微软在线服务无 SLA，见 §10.4）。
EDGE_TTS_VOICE = "en-US-AriaNeural"
TTS_REQUEST_INTERVAL = 0.6  # 秒，隐式限流下的保守间隔
TTS_RETRIES = 4
TTS_BACKOFF_BASE = 3.0  # 秒，指数退避

# 在线兜底 URL 模板（GitHub Releases，asset 名称含 audio/ 子目录）。
# 发布时若 GitHub 拒绝子目录 asset，需切换对象存储并在 manifest 同步。
DEFAULT_AUDIO_URL_TEMPLATE = (
    "https://github.com/Lmx2891632957/HappyBeiDanCi/releases/download/"
    f"{WORDLIST_NAME}-v{VERSION}/audio/{{key}}.mp3"
)

# ---------------------------------------------------------------------------
# 词性识别：ECDICT translation 行内前缀（TECH_DOC §10.2 释义规则）
# ---------------------------------------------------------------------------
POS_RE = re.compile(
    r"^\s*("
    r"vt|vi|adj|adv|prep|pron|conj|num|art|int|aux|modal|suf|abbr|comb|pl|"
    r"n|v|ad|a"
    r")\.?\s*(.*)$"
)

# 释义行内噪声前缀（[经]/[医]/[计] 等来源标注，不进入面向用户的释义）。
BRACKET_NOISE_RE = re.compile(r"^\s*\[[^\]]*\]\s*")

_WORD_TOKEN_RE = re.compile(r"[A-Za-z]+(?:'[A-Za-z]+)?")


def tokenize(text: str) -> list[str]:
    """按单词边界切分句子（保留撇号缩写，忽略大小写）。"""
    return [t.lower() for t in _WORD_TOKEN_RE.findall(text)]


def word_id_hash(word: str) -> int:
    """word_id 稳定映射键：word 文本 SHA-256 截断 48 位。

    为什么用哈希而非序号：词库升级整体替换 words 时（TECH_DOC §8.2），
    同一词跨版本 id 保持不变，用户进度 remap 只依赖文本本身；48 位在
    3677 词规模下碰撞概率约 7.5e-10，构建期仍会做碰撞检测并失败。
    """
    normalized = word.strip().lower()
    return int.from_bytes(
        hashlib.sha256(normalized.encode("utf-8")).digest()[:6], "big"
    )


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def json_dump(path: Path, obj: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding="utf-8")


def json_load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def frequency_from_frq(frq: int) -> str:
    """考频分桶（TECH_DOC §10.2：M1 以 ECDICT frq 为考频代理）。"""
    if frq == 0:
        return "medium"
    if frq <= FREQ_HIGH_MAX:
        return "high"
    if frq <= FREQ_MEDIUM_MAX:
        return "medium"
    return "low"
