# 内容管线（tools/content_pipeline）

离线工具链：把公开数据源加工为发布版词库产物（词库 DB + 音频包 + manifest）。
原始数据与中间产物不入源码仓库（AGENTS §5.3），发布产物在 `output/`。

## 数据源与许可（详见 TECH_DOC §10.4）

| 数据源 | 用途 | 许可 |
|---|---|---|
| ECDICT（`ecdict.csv`） | 词表种子（gk 3677 词）、释义、兜底音标、考频代理 | MIT |
| Tatoeba Detailed（`eng_sentences_detailed.tsv.bz2`） | 例句 + 作者署名 | CC BY 2.0 FR |
| ipa-dict en_US（`en_US.txt`） | 美式 IPA 音标（主源，覆盖 99.1%） | MIT（基于 CMUdict） |
| Edge TTS（`pip install edge-tts`） | 美音单词音频 | 微软在线服务，无 SLA |

## 使用

```bash
cd tools/content_pipeline
python -m pip install -r requirements.txt
python -m pipeline.main fetch    # 下载三个原始源（curl 断点续传，合计约 100 MB）
python -m pipeline.main align    # 词表对齐 → work/words.json
python -m pipeline.main build    # 释义/音标/例句 → work/wordbook.db
python -m pipeline.main tts      # 批量生成音频（约 40–60 分钟，可中断重跑续传）
python -m pipeline.main qa       # 质检抽检清单 → work/qa_checklist.md
python -m pipeline.main package  # 打包 → output/wordbook-gaokao-3500-v1.0/
```

`python -m pipeline.main all --with-tts` 一键全流程；默认 `all` 跳过 TTS
（便于快速验证）。词表对齐可选传入官方词表：`align --official 官方词表.txt`。

## 产物布局（output/wordbook-gaokao-3500-v1.0/）

```text
wordbook-gaokao-3500-v1.0.db   # 词库 DB（words/wordbooks/wordbook_items + meta）
audio-gaokao-3500-v1.0.zip     # 音频 zip（内含 audio/<seq>.mp3）
manifest.json                  # 版本、wordbook_id、逐文件 SHA-256
```

产物版本独立编号（`wordbook-gaokao-3500-v<版本>`，与 App 代码版本解耦）；
发布用 GitHub Releases tag（或对象存储），App 内按 manifest 版本拉取。

## 测试

```bash
python -m unittest discover -s tests -v
```
