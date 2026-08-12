# 内容构建管线（离线工具链）

本目录是**离线工具链**（TECH_DOC §10），不随 App 分发。M1 阶段先搭目录，脚本在词库内容开发时实现。

## 阶段（TECH_DOC §10.2）

| 阶段 | 说明 |
|---|---|
| 词表对齐 | 考纲词表 ∩ ECDICT `gk` 标签，去重、规范大小写，产出词表 JSON |
| 释义/音标 | 从 ECDICT 取最常用 1–3 个义项，标注词性 |
| 例句筛选 | Tatoeba 全库过滤（句长 ≤ 18 词、覆盖目标词、词频阈值），保留署名 |
| 音频生成 | Edge TTS 美音批量生成，命名 `audio_key = 词表序号`（TD-08） |
| 质检 | 每 1000 词人工抽检 |
| 打包 | 词库 DB（words/wordbooks/wordbook_items）+ 音频 zip + manifest（版本 + SHA-256） |

## 产物与版本

- 发布产物输出到 `output/`（已在 .gitignore 忽略，AGENTS §5.3）。
- 产物版本独立编号（如 `wordbook-gaokao-3500-v1.2`），与代码 tag 不混用。
- 词库升级不得破坏用户进度：`word_id` 以“word 文本 + 版本”映射（TECH_DOC §8.2）。

## 合规

- ECDICT（MIT）、Tatoeba（CC BY 2.0 FR，保留例句署名）、教育部考纲词表。
- 应用内“关于/数据来源”页固定展示以上署名（TECH_DOC §10.3）。
