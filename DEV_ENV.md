# DEV_ENV.md（开发环境说明）

> 用途：本机（macOS 开发主机）的工具链、网络与开发循环事实，供 AI 智能体与
> 协作者动手前阅读。本文档**不属于产品/技术设计文档**，随环境变化维护
> （2026-08-15 建立）；涉及产品行为与架构设计仍以 PRD.md / TECH_DOC.md 为准。

## 1. 项目与文档

- 产品：**我爱背单词**（Android 首版，Flutter），仓库
  `/Users/Zhuanz/myVibeProjects/HappyBeiDanCi`（已公开，origin 为 GitHub）。
- 动手前必读：AGENTS.md（仓库守则，本应用会自动加载）、PRD.md（产品需求，
  已定稿）、TECH_DOC.md（技术设计）。改动前对照 AGENTS §2 的对应章节。

## 2. 工具链（2026-08-15 实测）

| 组件 | 路径 / 版本 | 说明 |
|---|---|---|
| Flutter | `/opt/homebrew/bin/flutter`（3.44.9 / Dart 3.12.2） | 稳定版 |
| JDK | `/opt/homebrew/opt/openjdk@17`（17.0.20，keg-only） | 需显式设 `JAVA_HOME` |
| Android SDK | `/opt/homebrew/share/android-commandlinetools` | 含 platform-tools/adb、platforms 35/36、build-tools 35/36、emulator 37.1.11、android-36 google_apis arm64 系统镜像 |

运行任何 Flutter/Android 命令前先设置：

```bash
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export PATH="$ANDROID_HOME/platform-tools:$PATH"
```

## 3. 网络事实（重要，勿重新探索）

- 本机**直连 github.com 超时**；`api.github.com`、`raw.githubusercontent.com`、
  `codeload.github.com`、`uploads.github.com` 等子域可直连。
- 本机 Clash 代理监听 **127.0.0.1:7888**（注意：git 全局配置仍指向已失效的
  7892，**禁止修改全局 git 配置**）。
- git 推送/拉取必须命令级临时指定代理：

  ```bash
  git -c http.proxy=http://127.0.0.1:7888 -c https.proxy=http://127.0.0.1:7888 <push/pull/ls-remote...>
  ```

- GitHub API 认证：环境变量 `GITHUB_TOKEN` 已失效（401）；改用钥匙串凭据
  （`printf 'protocol=https\nhost=github.com\n\n' | git credential fill` 取
  `password` 字段），**不得打印或硬编码任何凭据**。
- 大文件下载（Gradle 发行包、Android 系统镜像等）建议经 7888 代理
  `curl -L -C - --retry 6 --retry-all-errors -x http://127.0.0.1:7888 -o <目标>` 断点续传。

## 4. 模拟器开发循环

- AVD：`pixel10_api36`（Pixel 10 / API 36，arm64）。
- 启动模拟器**必须带代理参数**才有外网（App 的 Dart HttpClient 不走 Android
  系统代理，只能靠模拟器网络层代理）：

  ```bash
  $ANDROID_HOME/emulator/emulator -avd pixel10_api36 -no-snapshot -no-boot-anim \
    -http-proxy http://127.0.0.1:7888 &
  ```

- 开发循环：`flutter run -d emulator-5554`；`r` 热重载 / `R` 热重启 / `q` 退出，
  **不需要重新安装 APK**。
- 调试便利：`adb` 在 `$ANDROID_HOME/platform-tools/`；debug 构建可用
  `adb shell run-as com.woaibeidanci.app` 访问应用私有目录（词库包在
  `files/wordbooks/`，应用数据库在 `app_flutter/happy_bei_dan_ci.sqlite`）。
- **内容全内置（2026-08-16，TD-14）**：词库与发音随 APK assets 预装
  （`assets/wordbooks/`、`assets/audio/`，CI/本地脚本注入，不入 git）；
  清除应用数据/重装后首次启动为**本地 asset 导入**，飞行模式即可完整
  使用，无需外网（模拟器可不再带 `-http-proxy`）。

## 5. 词库与发布状态

- 仓库已公开；GitHub Release `wordbook-gaokao-3500-v1.1` 已发布（词库 DB
  2.8MB + 音频 zip 37MB + manifest，含 SHA-256；例句筛选规则更新见 TECH_DOC
  §10.2）；`wordbook-gaokao-3500-v1.0` 仍可访问。
- **内容全内置（TD-14）**：该 Release 产物同时作为 CI 构建注入源
  （`.github/workflows/ci.yml` 构建 APK 前拉取注入 `assets/`）与本地注入源；
  本机构建前运行 `tools/scripts/inject_assets.sh`（优先复制本地
  `tools/content_pipeline/output/wordbook-gaokao-3500-v1.1/` 产物，缺失时经
  7888 代理 curl 断点续传下载 GitHub Release，并按 manifest SHA-256 校验）。
- 内容管线：`tools/content_pipeline`（Python 解释器
  `/Users/Zhuanz/miniconda3/bin/python3`）；TTS 3677 词已完成；`raw/`、`work/`、
  `output/` 均不入库。
- 已知限制：GitHub 不支持子目录资产名，词条内逐词在线兜底发音 URL
  （`audio/<key>.mp3`）会 404；内容全内置后内置词书不再触发在线兜底，
  该限制对用户不可见，M2 可下载词书时再评估。

## 6. 已修复与遗留

- 已修复：设置页分段控件横排（`f1fe694`）；词库首装数据库双实例锁库 →
  `main.dart` 单实例（`cadaf5a`）。
- 遗留：`work/qa_checklist.md` 的 133 条信号词待人工抽检；内容全内置后在线
  兜底发音 URL 的 404 限制对内置词书不可见（M2 可下载词书时再评估）。

## 7. 收尾要求

- `flutter analyze` 无新增问题、`flutter test` 全绿（当前基线 233 项 + 1 跳过，
  DEV_ENV 随测试数量增长维护）。
- 构建含内置内容的 APK 前先运行 `tools/scripts/inject_assets.sh`（TD-14）。
- Conventional Commits 小步提交（`fix`/`feat`/`docs` 等，一提交一事）。
- 涉及架构/数据/算法改动必须同步 TECH_DOC.md；产品行为改动先与用户确认。
- 完成后推送 main（走 §3 的代理命令）并汇报改动文件、关键决策与遗留项。
