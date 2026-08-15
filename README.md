# 我爱背单词（HappyBeiDanCi）

> 一款"打开就能背、每天几分钟"的英语单词记忆应用：**间隔重复复习 + 高质量词条内容 + 低门槛的每日习惯**，面向高中生，覆盖高考大纲词汇，完全免费。

[![CI](https://github.com/Lmx1632892957/HappyBeiDanCi/actions/workflows/ci.yml/badge.svg)](https://github.com/Lmx1632892957/HappyBeiDanCi/actions/workflows/ci.yml)

- **平台**：Android（Flutter 实现，架构预留 iOS 移植）
- **定位**：本地优先、离线可用、无账号体系、无广告/统计/支付 SDK
- **目标人群**：高中生（高考英语），课间/通勤/睡前 5–10 分钟碎片化学习
- **当前状态**：M1 MVP 核心闭环已实现（学习 → 复习 → 完成页），词库 v1.1 已发布

---

## 功能特性

### ✅ 已实现（M1 MVP）

| 功能 | 说明 |
|---|---|
| 首次引导 | 选词书 → 设每日目标 → 熟词跳过，3 步进入学习 |
| 今日任务页 | 展示待学新词（今日剩余）、待复习词、今日已学；新词目标完成后可"再学一组" |
| 学习会话 | 卡片式浏览：单词 + 音标 + 发音 → 释义/例句 → 认识 / 模糊 / 不认识 |
| 复习会话 | 按 FSRS-5 调度到期词，逾期严重度排序；答错的词本次会话内重排再现 |
| 复习软上限 | 每日复习量超限自动顺延次日（默认 300 词，可调整/关闭），防止积压 |
| 会话续学 | 中途退出/中断不丢进度，再次进入从快照恢复 |
| 发音 | 在线优先播放 + 后台下载离线包（WorkManager 前台服务、断点续传、SHA-256 校验、Wi-Fi 策略） |
| 每日提醒 | 本地通知每日提醒学习（默认 20:00，可自定义） |
| 词库乱序 | 确定性种子乱序学习顺序，词库升级后同种子重排，不漂移 |
| 词库升级 | 检测已装版本落后时自动下载导入新词库，保留用户进度 |
| 界面语言 | 简体中文 / English 切换，学习卡片中英对照 |
| 深色模式 | 跟随系统 / 浅色 / 深色 |
| 数据导出 | 学习记录导出 CSV/JSON，经系统分享面板分享 |
| 数据来源署名 | 应用内"关于"页展示词库数据源与协议 |

### 🚧 规划中（M2 / M3）

新课标词书、例句/词根增强、生词本、高考倒计时模式、统计页与学习周报、英音、云同步（可选）。

---

## 技术架构

### 分层架构

```
┌───────────────────────────────────────────────────────┐
│ Presentation（features/）                              │
│   onboarding · home · learn · review · results ·       │
│   settings · about                                     │
├───────────────────────────────────────────────────────┤
│ Domain（纯逻辑，零 Flutter 依赖，可单测、可跨端复用）      │
│   FSRS-5 调度引擎 · 会话状态机 · 每日计划计算 ·          │
│   队列排序 · 打卡统计 · 仓储接口契约                     │
├───────────────────────────────────────────────────────┤
│ Data                                                  │
│   Drift/SQLite（WAL）· 词库导入 · 离线包管理 ·           │
│   音频播放 · 通知调度 · 数据导出                        │
└───────────────────────────────────────────────────────┘
```

分层依赖只允许向下：`features → domain/data → core`；Domain 层不依赖 Flutter/Android API，保证可单测并在未来 iOS 端复用。

### 技术栈

| 领域 | 选型 |
|---|---|
| 框架 | Flutter 3.x / Dart 3 + Material 3 |
| 状态管理 | Riverpod 2.x |
| 本地存储 | Drift（SQLite + WAL，类型安全、迁移友好） |
| 复习算法 | **FSRS-5**（Dart 移植自官方 Python 参考实现，golden 测试精度 1e-6） |
| 路由 | go_router |
| 音频 | just_audio（在线流 + 本地文件统一接口） |
| 后台下载 | workmanager（前台服务 + 断点续传） |
| 通知 | flutter_local_notifications + timezone |
| 国际化 | Flutter 官方 l10n（ARB） |

### 词库内容管线

`tools/content_pipeline/`（Python 离线工具链，不随 App 分发）：

```
词表对齐 → 释义/音标提取 → 例句筛选 → Edge TTS 生成美音 → 质检抽检 → 打包发布
```

- **词库**：高考大纲 3500 词（实收 3677 词，含课标扩充），当前发布版 `wordbook-gaokao-3500-v1.1`（词库 DB 2.8 MB + 美音音频包 37 MB，托管于 GitHub Releases，含 SHA-256 manifest）
- **数据来源**：教育部《高考英语考试大纲》词表、[ECDICT](https://github.com/skywind3000/ECDICT)（MIT）、[ipa-dict](https://github.com/open-dict-data/ipa-dict)（MIT，基于 CMUdict）、[Tatoeba](https://tatoeba.org) 例句（CC BY 2.0 FR）、Edge TTS 美音

---

## 快速开始

### 环境要求

- Flutter 3.x（开发机实测 3.44.9 / Dart 3.12.2）
- Android SDK（platform-tools、platforms 35/36、build-tools 35/36）
- JDK 17

> 本机详细工具链、网络代理、模拟器与词库预装状态见 [DEV_ENV.md](./DEV_ENV.md)。

### 运行

```bash
flutter pub get
flutter run            # 连接 Android 设备/模拟器
```

### 测试与质量检查

```bash
flutter analyze        # 无新增问题
flutter test           # 222 项用例（FSRS golden / 会话续学 / 数据库迁移 / 集成 / Widget）
```

CI（GitHub Actions）自动执行 analyze + test + release APK 构建；词库产物发布走独立 workflow（`publish-wordbook.yml`，tag 触发）。

---

## 目录结构

```text
lib/
  app/            # 应用装配：主题、路由、国际化、依赖注入（providers）
  core/           # 基础设施：日志、时间工具、常量、哈希
  data/
    local/        # Drift 表定义、迁移脚本
    repositories/ # 仓储实现（domain 接口的具体实现）
    sources/      # 词库导入、离线包下载、音频、提醒、导出
  domain/
    models/       # 领域模型
    scheduling/   # FSRS-5 引擎、复习队列构建与软上限
    sessions/     # 学习/复习会话状态机与驱动
    services/     # 仓储接口契约 + 每日计划/打卡/导出等纯逻辑
  features/       # 各功能页（页面、组件、状态）
tools/
  content_pipeline/  # 词库构建、例句筛选、TTS、打包（Python）
test/
  domain/         # 纯逻辑单测
  integration/    # 数据库/仓储集成测试
  widget/         # 页面组件测试
```

---

## 文档

| 文档 | 内容 |
|---|---|
| [PRD.md](./PRD.md) | 产品需求文档（已定稿，含全部已确认决策） |
| [TECH_DOC.md](./TECH_DOC.md) | 技术设计（架构、算法、数据模型、内容管线、发布） |
| [AGENTS.md](./AGENTS.md) | 仓库协作守则（目录纪律、提交规范、红线） |
| [DEV_ENV.md](./DEV_ENV.md) | 本机开发环境事实（工具链、代理、模拟器） |

---

## 隐私与合规

- **本地优先**：学习数据全部存储在本地 SQLite，不上传、不共享、无账号体系
- **最小化采集**：目标用户含未成年人，不收集与学习无关的数据，无广告/统计/支付 SDK
- **内容合规**：非商业免费工具，应用内保留 ECDICT / Tatoeba / 考纲词表的来源署名

---

## 里程碑

| 阶段 | 范围 | 状态 |
|---|---|---|
| **M1 MVP** | Android 端 + 高考 3500 词书、学习/复习闭环、FSRS-5、发音（在线+离线包）、每日目标、复习软上限、熟词跳过、深色模式、会话续学、数据导出 | ✅ 已实现 |
| **M2** | 新课标词书、例句/词根增强、生词本、高考倒计时、统计页、学习周报、英音 | 🚧 规划中 |
| **M3** | 云同步（可选）、自定义词书导入、分享打卡、FSRS 参数优化 | 🚧 规划中 |
