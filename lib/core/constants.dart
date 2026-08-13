/// 全局常量：与 TECH_DOC §18「核心常量与默认值」保持一致，业务代码统一引用此处，
/// 避免魔法数字散落各处导致改参时漏改。
abstract final class AppConstants {
  AppConstants._();

  /// 应用显示名（Android launcher / iOS display name）。
  static const String appDisplayName = '我爱背单词';

  /// Android applicationId（TD-13 已确认）。
  static const String androidApplicationId = 'com.woaibeidanci.app';

  /// 每日新词数默认值（PRD F2，可选 10/20/30/50）。
  static const int defaultDailyNewWords = 20;

  /// 每日新词目标可选值（PRD F2）。
  static const List<int> dailyGoalOptions = [10, 20, 30, 50];

  /// 复习软上限默认值（PRD F2，可调整/关闭；关闭时上层传 null）。
  static const int defaultReviewCap = 300;

  /// FSRS 目标记忆保持率（TD-05）。
  static const double defaultDesiredRetention = 0.9;

  /// 学习步骤（分钟）：新词/重学词答错后 +10 分钟（TD-05）。
  static const List<int> learningStepsMinutes = [10];

  /// 重学步骤（分钟），与学习步骤共用 10 分钟。
  static const List<int> relearningStepsMinutes = [10];

  /// 单次会话内每词最大重排次数，防止答错无限循环（PRD §5/TECH_DOC §5.2）。
  static const int maxRequeuePerSession = 2;

  /// 调度日边界默认时区（TECH_DOC §18，可设置）。
  static const String defaultTimezone = 'Asia/Shanghai';

  /// 每日提醒默认时间（HH:mm，PRD F6）。
  static const String defaultReminderTime = '20:00';

  /// 离线音频包发布仓库（TD-11 GitHub Releases；换对象存储只改本组常量，
  /// TECH_DOC §9.2/§18）。
  static const String githubRepoOwner = 'Lmx2891632957';
  static const String githubRepoName = 'HappyBeiDanCi';

  /// M1 词库包发布名（与内容管线 `WORDLIST_NAME` 一致，TECH_DOC §9.2）。
  /// 多词书时需扩展为 wordbook_id → 包名映射。
  static const String defaultWordbookPackBase = 'wordbook-gaokao-3500';

  /// 离线包下载进度上报粒度（字节）：每写完一个分块更新
  /// `audio_packs.downloaded_size`（TECH_DOC §9.2）。
  static const int audioDownloadProgressChunkBytes = 256 * 1024;

  /// 离线包下载任务退避（WorkManager，TECH_DOC §11.2）。
  static const Duration audioDownloadBackoff = Duration(minutes: 5);

  /// 离线包发布基址：`.../releases/download/<包名>-v<版本>/`（TECH_DOC §9.2）。
  static String audioPackReleaseBaseUrl(String packBase, String version) =>
      'https://github.com/$githubRepoOwner/$githubRepoName/releases/download/'
      '$packBase-v$version/';

  /// WorkManager 唯一任务名（TECH_DOC §11.2）。
  static String audioPackUniqueWorkName(int wordbookId) =>
      'audio-pack-$wordbookId';

  /// 离线包下载后台任务名（WorkManager taskName，§11.2）。
  static const String audioPackDownloadTaskName = 'audio_pack_download';

  /// 前台服务通知频道与通知 ID（TECH_DOC §11.2）。
  static const String audioPackNotificationChannelId = 'audio_download';
  static const int audioPackNotificationId = 1001;
}

/// settings 键值表的键名常量（TECH_DOC §8.1 settings）。
///
/// 键名集中定义在本处（core 基础设施），仓储实现与测试统一引用，
/// 禁止在业务代码中散落魔法字符串。
abstract final class AppSettingKeys {
  AppSettingKeys._();

  /// 每日新词数（整数文本）。
  static const String dailyNewWords = 'daily_new_words';

  /// 复习软上限（整数文本；'off' 表示关闭）。
  static const String reviewCap = 'review_cap';

  /// 每日提醒开关（'true'/'false'）。
  static const String reminderEnabled = 'reminder_enabled';

  /// 提醒时间（HH:mm）。
  static const String reminderTime = 'reminder_time';

  /// 高考倒计时考试日期（epoch 毫秒文本；空串表示未设置，M3 功能占位）。
  static const String examDate = 'exam_date';

  /// 调度日边界时区（IANA 名称文本，默认 Asia/Shanghai）。
  static const String timezone = 'timezone';

  /// 首次启动引导是否已完成（'true'/'false'；缺失按默认 false 回填，
  /// TECH_DOC §18，首启路由判定见 §5.1）。
  static const String onboardingDone = 'onboarding_done';

  /// 已安装词库内容版本（TECH_DOC §8.2；空串表示未安装）。
  static const String wordbookVersion = 'wordbook_version';

  /// 发音开关（TECH_DOC §9.4，F7；'true'/'false'）。
  static const String pronunciationEnabled = 'pronunciation_enabled';

  /// 蜂窝网络允许自动下载离线音频包（TECH_DOC §9.4，F5；'true'/'false'）。
  static const String audioDownloadOnCellular = 'audio_download_on_cellular';

  /// 全部键名（用于缺键回填与批量保存）。
  static const List<String> all = [
    dailyNewWords,
    reviewCap,
    reminderEnabled,
    reminderTime,
    examDate,
    timezone,
    onboardingDone,
    wordbookVersion,
    pronunciationEnabled,
    audioDownloadOnCellular,
  ];
}
