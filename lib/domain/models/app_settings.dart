/// 应用设置领域模型（TECH_DOC §8.1 settings 键值表之上的类型化视图）。
class AppSettings {
  const AppSettings({
    this.dailyNewWords = 20,
    this.reviewCap = 300,
    this.reminderEnabled = true,
    this.reminderTime = '20:00',
    this.examDate,
    this.timezone = 'Asia/Shanghai',
    this.onboardingDone = false,
    this.wordbookVersion,
    this.pronunciationEnabled = true,
    this.audioDownloadOnCellular = false,
  });

  /// 每日新词目标（PRD F2，默认 20）。
  final int dailyNewWords;

  /// 复习软上限；null 表示关闭（PRD F2，默认 300）。
  final int? reviewCap;

  /// 每日提醒开关（PRD F6，默认开启）。
  final bool reminderEnabled;

  /// 提醒时间 HH:mm（默认 20:00）。
  final String reminderTime;

  /// 高考倒计时考试日期（M3 功能，先占位）。
  final DateTime? examDate;

  /// 调度日边界时区（TECH_DOC §18，默认 Asia/Shanghai）。
  final String timezone;

  /// 首次启动引导是否已完成（TECH_DOC §18，默认 false；完成 Onboarding
  /// 后置 true，供首启路由判定，§5.1）。
  final bool onboardingDone;

  /// 已安装词库内容版本（TECH_DOC §8.2；null 表示尚未导入发布版词库）。
  final String? wordbookVersion;

  /// 发音开关（TECH_DOC §9.4，F7；默认开启）。
  final bool pronunciationEnabled;

  /// 蜂窝网络允许自动下载离线音频包（TECH_DOC §9.4，F5；默认关闭，
  /// 仅 Wi-Fi/非计费网络自动下载）。
  final bool audioDownloadOnCellular;
}
