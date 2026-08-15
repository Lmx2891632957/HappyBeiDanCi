"""Edge TTS 批量生成美音单词音频（断点续跑、限速、指数退避重试）。

微软在线服务无 SLA（TECH_DOC §10.4）：默认每词间隔 0.6s，失败退避重试，
持续失败写入 tts_failures.txt 不中断批次；已存在且非空的 mp3 自动跳过，
因此中断后重跑即可续传。输出 work/audio/<seq:06d>.mp3。
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import time
from pathlib import Path

from . import common


def synthesize_one(word: str, out_file: Path, voice: str) -> bool:
    """单词合成；返回是否成功。失败由调用方决定重试策略。"""
    tmp = out_file.with_suffix(".mp3.tmp")
    proc = subprocess.run(
        [
            sys.executable,
            "-m",
            "edge_tts",
            "--voice",
            voice,
            "--text",
            word,
            "--write-media",
            str(tmp),
        ],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0 or not tmp.exists() or tmp.stat().st_size == 0:
        tmp.unlink(missing_ok=True)
        return False
    tmp.replace(out_file)
    return True


def generate(
    words_json: Path,
    audio_dir: Path,
    *,
    voice: str = common.EDGE_TTS_VOICE,
    interval: float = common.TTS_REQUEST_INTERVAL,
    retries: int = common.TTS_RETRIES,
) -> None:
    words = common.json_load(words_json)
    audio_dir.mkdir(parents=True, exist_ok=True)
    failures: list[str] = []
    start = time.monotonic()
    done = 0
    skipped = 0
    for i, w in enumerate(words):
        out_file = audio_dir / f"{w['audio_key']}.mp3"
        if out_file.exists() and out_file.stat().st_size > 0:
            skipped += 1
            continue
        ok = False
        delay = common.TTS_BACKOFF_BASE
        for attempt in range(retries):
            if synthesize_one(w["word"], out_file, voice):
                ok = True
                break
            print(
                f"  重试 {w['word']} ({attempt + 1}/{retries})，"
                f"退避 {delay:.1f}s",
                flush=True,
            )
            time.sleep(delay)
            delay *= 2
        if not ok:
            failures.append(w["word"])
            print(f"  失败（已记录）: {w['word']}", flush=True)
        done += 1
        if i + 1 < len(words):
            time.sleep(interval)
        if (i + 1) % 100 == 0:
            elapsed = time.monotonic() - start
            remaining = (len(words) - i - 1) * (elapsed / (i + 1))
            print(
                f"  进度 {i + 1}/{len(words)}，失败 {len(failures)}，"
                f"预计剩余 {remaining / 60:.1f} 分钟",
                flush=True,
            )
    common.TTS_FAILURES.write_text("\n".join(failures) + "\n", encoding="utf-8")
    print(
        f"TTS 完成：新生成 {done - skipped}，跳过 {skipped}，"
        f"失败 {len(failures)}（见 {common.TTS_FAILURES.name}）"
    )


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Edge TTS 批量生成美音")
    parser.add_argument("--words", type=Path, default=common.WORDS_JSON)
    parser.add_argument("--audio-dir", type=Path, default=common.AUDIO_DIR)
    parser.add_argument("--voice", default=common.EDGE_TTS_VOICE)
    parser.add_argument("--interval", type=float, default=common.TTS_REQUEST_INTERVAL)
    args = parser.parse_args(argv)
    generate(args.words, args.audio_dir, voice=args.voice, interval=args.interval)


if __name__ == "__main__":
    main()
