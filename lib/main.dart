import 'dart:async';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'app/app.dart';
import 'app/l10n/app_localizations.dart';
import 'core/logger.dart';
import 'data/local/app_database.dart';
import 'data/repositories/drift_audio_pack_repository.dart';
import 'data/repositories/drift_settings_repository.dart';
import 'data/repositories/drift_wordbook_repository.dart';
import 'data/sources/audio_pack_download_scheduler.dart';
import 'data/sources/audio_pack_worker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isAndroid) {
    // WorkManager 回调注册：离线包下载在后台 isolate 执行（TECH_DOC §11.2）。
    Workmanager().initialize(audioPackCallbackDispatcher);
  }
  runApp(const ProviderScope(child: App()));
  // F5：应用启动即检查"词库已安装且离线包未 ready"，后台注册下载任务。
  // 异步执行不阻塞首帧渲染（T-03 启动到首卡 < 2s）。
  unawaited(_scheduleAudioPackIfNeeded());
}

/// 词库已安装时注册当前词书发音离线包下载任务（幂等：keep + 状态判断）。
/// 失败仅记录日志，不影响启动与学习（在线兜底仍可用，T-02）。
Future<void> _scheduleAudioPackIfNeeded() async {
  if (kIsWeb || !Platform.isAndroid) {
    return;
  }
  try {
    final db = AppDatabase();
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
    } finally {
      await db.close();
    }
  } catch (error) {
    AppLogger.warning('音频包下载调度失败：$error');
  }
}
