"""打包发布产物：词库 DB + 音频 zip + manifest（版本与 SHA-256）。

输出 output/<name>-v<ver>/ 目录（已 .gitignore，AGENTS §5.3）：
  wordbook-<name>-v<ver>.db    词库 DB（含 meta 版本标记）
  audio-<name>-v<ver>.zip      音频 zip（内含 audio/*.mp3，TECH_DOC §9.2 布局）
  manifest.json                版本、wordbook_id、文件数与逐文件 SHA-256
"""

from __future__ import annotations

import argparse
import datetime
import shutil
import sqlite3
import zipfile
from pathlib import Path

from . import common


def _verify_db(db_path: Path) -> int:
    conn = sqlite3.connect(db_path)
    try:
        ok = conn.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
        count = conn.execute("SELECT COUNT(*) FROM words").fetchone()[0]
        if not ok:
            raise RuntimeError(f"DB 完整性校验失败: {db_path}")
        return count
    finally:
        conn.close()


def _zip_audio(audio_dir: Path, zip_path: Path) -> dict:
    files = sorted(audio_dir.glob("*.mp3"))
    if not files:
        raise RuntimeError(f"音频目录为空: {audio_dir}")
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_STORED) as zf:
        for f in files:
            zf.write(f, f"audio/{f.name}")
    return {
        "file_count": len(files),
        "total_size": sum(f.stat().st_size for f in files),
        "zip_size": zip_path.stat().st_size,
    }


def package(
    db: Path,
    audio_dir: Path,
    out_dir: Path,
    *,
    version: str = common.VERSION,
) -> dict:
    out_dir.mkdir(parents=True, exist_ok=True)
    db_name = common.artifact_db_name(version)
    zip_name = common.artifact_audio_name(version)
    db_dest = out_dir / db_name
    zip_dest = out_dir / zip_name

    word_count = _verify_db(db)
    shutil.copy2(db, db_dest)
    audio_info = _zip_audio(audio_dir, zip_dest)

    audio_files = {
        f.name: common.sha256_file(f) for f in sorted(audio_dir.glob("*.mp3"))
    }
    manifest = {
        "name": common.WORDLIST_NAME,
        "version": version,
        "wordbook_id": common.BOOK_ID,
        "schema_version": 1,
        "word_count": word_count,
        "created_at": datetime.datetime.now(
            datetime.timezone.utc
        ).isoformat(timespec="seconds"),
        "artifacts": {
            "wordbook_db": {
                "file": db_name,
                "size": db_dest.stat().st_size,
                "sha256": common.sha256_file(db_dest),
            },
            "audio_zip": {
                "file": zip_name,
                "size": zip_dest.stat().st_size,
                "sha256": common.sha256_file(zip_dest),
                "file_count": audio_info["file_count"],
                "total_size": audio_info["total_size"],
            },
            "audio_files": audio_files,
        },
        "sources": [
            "ECDICT (MIT)",
            "ipa-dict en_US (MIT, based on CMUdict)",
            "Tatoeba English detailed (CC BY 2.0 FR, attribution in examples)",
            "Microsoft Edge TTS (en-US-AriaNeural)",
        ],
    }
    common.json_dump(out_dir / "manifest.json", manifest)
    print(
        f"打包完成: {out_dir}\n"
        f"  DB: {db_dest.name}（{db_dest.stat().st_size} B, "
        f"{manifest['artifacts']['wordbook_db']['sha256'][:16]}…）\n"
        f"  音频: {zip_name}（{audio_info['file_count']} 文件, "
        f"{audio_info['total_size']} B 解压, {zip_dest.stat().st_size} B 压缩）"
    )
    return manifest


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="打包词库产物")
    parser.add_argument("--db", type=Path, default=common.WORDBOOK_DB)
    parser.add_argument("--audio-dir", type=Path, default=common.AUDIO_DIR)
    parser.add_argument("--version", default=common.VERSION)
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args(argv)
    out_dir = args.out or common.package_dir(args.version)
    package(args.db, args.audio_dir, out_dir, version=args.version)


if __name__ == "__main__":
    main()
