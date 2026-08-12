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
}
