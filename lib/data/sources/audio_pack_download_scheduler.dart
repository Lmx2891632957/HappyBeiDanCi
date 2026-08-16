import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/constants.dart';
import '../../domain/models/audio_pack.dart';
import '../../domain/services/audio_pack_repository.dart';
import '../../domain/services/settings_repository.dart';
import '../../domain/services/wordbook_repository.dart';

/// 离线音频包下载任务调度（TECH_DOC §9.2 触发/约束 / §11.2 WorkManager）。
///
/// 只做"注册/取消"编排：状态判断（未 ready、版本一致）与网络约束来自
/// 仓储与设置；下载本身由后台回调（[audioPackCallbackDispatcher]）执行。
/// 非 Android 平台为 no-op（单测/桌面环境不触碰插件通道）。
/// 内置词书（TD-14，level=gaokao）不触发下载：注册前按词书判定跳过。
class AudioPackDownloadScheduler {
  AudioPackDownloadScheduler({
    required this.settingsRepository,
    required this.audioPackRepository,
    required this.wordbookRepository,
  });

  final SettingsRepository settingsRepository;
  final AudioPackRepository audioPackRepository;
  final WordbookRepository wordbookRepository;

  /// 词库已安装且离线包未 ready（或版本不一致）时注册一次性下载任务；
  /// 内置词书（发音随 APK 预装，TD-14）直接跳过（返回 false 不注册）。
  ///
  /// 返回是否实际注册。通知文案由调用方按当前界面语言解析后传入
  /// （前台服务通知属系统 UI，TECH_DOC §11.2）。
  Future<bool> scheduleIfNeeded({
    required int wordbookId,
    required String version,
    String notificationTitle = '正在下载发音包',
    String notificationText = '正在下载单词发音，完成后可离线播放',
    String notificationChannelName = '发音包下载',
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }
    // TD-14 内容全内置：内置词书发音随 APK 打包，无需也不应下载离线包。
    final book = await wordbookRepository.getWordbookById(wordbookId);
    if (AppConstants.isBuiltInWordbookLevel(book?.level)) {
      return false;
    }
    final pack = await audioPackRepository.get(wordbookId);
    if (pack?.status == AudioPackStatus.ready && pack!.version == version) {
      return false;
    }
    // 版本不一致（词库升级，§9.3）时用 replace 覆盖旧任务；同版本 pending
    // 任务保留（keep），避免重复排队。
    final policy = (pack != null && pack.version != version)
        ? ExistingWorkPolicy.replace
        : ExistingWorkPolicy.keep;
    final settings = await settingsRepository.load();
    await Workmanager().registerOneOffTask(
      AppConstants.audioPackUniqueWorkName(wordbookId),
      AppConstants.audioPackDownloadTaskName,
      inputData: {'wordbookId': wordbookId, 'version': version},
      constraints: Constraints(
        networkType: settings.audioDownloadOnCellular
            ? NetworkType.connected
            : NetworkType.unmetered,
      ),
      existingWorkPolicy: policy,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: AppConstants.audioDownloadBackoff,
      foregroundServiceConfig: ForegroundServiceConfig(
        notificationTitle: notificationTitle,
        notificationText: notificationText,
        notificationChannelId: AppConstants.audioPackNotificationChannelId,
        notificationChannelName: notificationChannelName,
        notificationId: AppConstants.audioPackNotificationId,
        foregroundServiceType: ForegroundServiceType.dataSync,
      ),
    );
    return true;
  }

  /// 取消下载任务（设置页"删除离线包"时调用，§9.2 第 8 条）。
  Future<void> cancel(int wordbookId) async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }
    await Workmanager().cancelByUniqueName(
      AppConstants.audioPackUniqueWorkName(wordbookId),
    );
  }
}
