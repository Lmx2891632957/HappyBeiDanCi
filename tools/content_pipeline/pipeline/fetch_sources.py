"""下载原始数据源（ECDICT / Tatoeba Detailed / ipa-dict en_US）。

使用系统 curl 断点续传（-C -），重复执行只补齐缺失部分；下载后打印文件大小
供与 TECH_DOC §10.4 实测值比对。需要网络；原始数据不入库（raw/ 已忽略）。
"""

from __future__ import annotations

import subprocess

from . import common

SOURCES = [
    (common.ECDICT_CSV_URL, common.ECDICT_CSV),
    (common.TATOEBA_EN_DETAILED_URL, common.TATOEBA_EN_DETAILED),
    (common.IPA_EN_US_URL, common.IPA_EN_US),
]


def fetch_one(url: str, dest) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    print(f"== {url}\n   -> {dest}")
    # 断点续传：-L 跟随重定向，-C - 续传已下载部分，--fail 让 HTTP 错误
    # 表现为非零退出而非静默写坏文件。
    subprocess.run(
        ["curl", "-L", "-C", "-", "--fail", "--retry", "3", "-o", str(dest), url],
        check=True,
    )
    print(f"   size={dest.stat().st_size} bytes")


def fetch_all() -> None:
    for url, dest in SOURCES:
        fetch_one(url, dest)


if __name__ == "__main__":
    fetch_all()
