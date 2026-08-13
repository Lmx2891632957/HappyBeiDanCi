"""内容管线 CLI 入口：fetch / align / build / tts / qa / package。

示例：
  python -m pipeline.main fetch
  python -m pipeline.main align
  python -m pipeline.main build
  python -m pipeline.main tts            # 3500 词约 40–60 分钟，可断点续跑
  python -m pipeline.main qa
  python -m pipeline.main package
  python -m pipeline.main all --skip-tts # 除 TTS 外全流程（CI/演示用）
"""

from __future__ import annotations

import argparse

from . import align_words, build_wordbook, common, fetch_sources
from . import generate_tts, package as package_mod, qa_checklist


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="我爱背单词内容管线")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("fetch", help="下载原始数据源（curl 断点续传）")

    p_align = sub.add_parser("align", help="词表对齐（ECDICT gk 基准）")
    p_align.add_argument("--official", default=None, help="官方词表纯文本路径（可选）")

    p_build = sub.add_parser("build", help="构建词库 DB（释义/音标/例句）")

    p_tts = sub.add_parser("tts", help="Edge TTS 批量生成美音（可断点续跑）")
    p_tts.add_argument("--interval", type=float, default=common.TTS_REQUEST_INTERVAL)

    sub.add_parser("qa", help="生成质检抽检清单")

    p_pkg = sub.add_parser("package", help="打包 DB + 音频 zip + manifest")
    p_pkg.add_argument("--version", default=common.VERSION)

    p_all = sub.add_parser("all", help="全流程（默认跳过 TTS 以便快速验证）")
    p_all.add_argument("--with-tts", action="store_true", help="包含 TTS 生成")

    args = parser.parse_args(argv)
    cmd = args.cmd
    if cmd == "fetch":
        fetch_sources.fetch_all()
    elif cmd == "align":
        align_words.main(["--official", args.official] if args.official else [])
    elif cmd == "build":
        build_wordbook.main([])
    elif cmd == "tts":
        generate_tts.main(["--interval", str(args.interval)])
    elif cmd == "qa":
        qa_checklist.main([])
    elif cmd == "package":
        package_mod.main(["--version", args.version])
    elif cmd == "all":
        fetch_sources.fetch_all()
        align_words.main([])
        build_wordbook.main([])
        if args.with_tts:
            generate_tts.main([])
        qa_checklist.main([])
        package_mod.main([])


if __name__ == "__main__":
    main()
