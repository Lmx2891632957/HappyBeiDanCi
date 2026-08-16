import 'dart:async';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'app/app.dart';
import 'app/l10n/app_localizations.dart';
import 'app/providers.dart';
import 'core/logger.dart';
import 'data/local/app_database.dart';
import 'data/repositories/drift_audio_pack_repository.dart';
import 'data/repositories/drift_settings_repository.dart';
import 'data/repositories/drift_wordbook_repository.dart';
import 'data/sources/audio_pack_download_scheduler.dart';
import 'data/sources/audio_pack_worker.dart';
import 'data/sources/wordbook_installer.dart';
import 'data/sources/wordbook_importer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isAndroid) {
    // WorkManager 回调注册：离线包下载在后台 isolate 执行（TECH_DOC §11.2）。
    Workmanager().initialize(audioPackCallbackDispatcher);
  }
  // 数据库单实例：providers 与启动后台任务共用同一连接（WAL 单写连接，
  // 避免双实例打开同一文件导致的锁库/竞态，TECH_DOC §8.2 单写连接）。
  final db = AppDatabase();
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const App(),
    ),
  );
  // F5：应用启动即检查"词库已安装且离线包未 ready"，后台注册下载任务。
  // 异步执行不阻塞首帧渲染（T-03 启动到首卡 < 2s）。
  unawaited(_scheduleAudioPackIfNeeded(db));
  // 词库未安装时后台首装（TECH_DOC §8.2 首装流程），同样不阻塞首帧。
  unawaited(_ensureWordbookInstalled(db));
}

/// 词库首装（幂等）：安装成功后按新版本调度发音包下载。
/// 失败仅记录日志，今日页「无词库」状态提供重试入口（§8.2 失败语义）。
Future<void> _ensureWordbookInstalled(AppDatabase db) async {
  if (kIsWeb || !Platform.isAndroid) {
    return;
  }
  try {
    final installer = WordbookInstaller(
      importer: WordbookImporter(db),
      settingsRepository: DriftSettingsRepository(db),
    );
    final version = await installer.ensureInstalled();
    if (version != null) {
      await _scheduleAudioPackIfNeeded(db);
    }
  } catch (error) {
    AppLogger.warning('词库首装失败（今日页可重试）：$error');
  }
}

/// 词库已安装时注册当前词书发音离线包下载任务（幂等：keep + 状态判断）。
/// 失败仅记录日志，不影响启动与学习（在线兜底仍可用，T-02）。
Future<void> _scheduleAudioPackIfNeeded(AppDatabase db) async {
  if (kIsWeb || !Platform.isAndroid) {
    return;
  }
  try {
    final settings = await DriftSettingsRepository(db).load();
    final version = settings.wordbookVersion;
    if (version == null || version.isEmpty) {
      return;
    }
    final wordbooks = await DriftWordbookRepository(db).getWordbooks();
    if (wordbooks.isEmpty) {
      return;
    }
    final scheduler = AudioPackDownloadScheduler(
      settingsRepository: DriftSettingsRepository(db),
      audioPackRepository: DriftAudioPackRepository(db),
      wordbookRepository: DriftWordbookRepository(db),
    );
    // 前台服务通知文案按系统语言解析（TECH_DOC §11.2）。
    final l10n = lookupAppLocalizations(
      PlatformDispatcher.instance.locale,
    );
    await scheduler.scheduleIfNeeded(
      wordbookId: wordbooks.first.id,
      version: version,
      notificationTitle: l10n.audioDownloadNotificationTitle,
      notificationText: l10n.audioDownloadNotificationText,
      notificationChannelName: l10n.audioDownloadNotificationChannelName,
    );
  } catch (error) {
    AppLogger.warning('音频包下载调度失败：$error');
  }
}
