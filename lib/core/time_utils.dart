import 'constants.dart';

/// 调度日边界工具（TECH_DOC §6.2/§18：今日零点与今日结束）。
///
/// Asia/Shanghai 固定 UTC+8 且无夏令时：直接以 UTC 时刻 +8h 截断到日期，
/// 不依赖设备时区设置，保证调度日边界稳定；其他时区（设置内可改，§18）
/// 暂按设备本地时间近似，完整时区支持（timezone 包）属后续迭代。
abstract final class TimeUtils {
  TimeUtils._();

  static const Duration _shanghaiOffset = Duration(hours: 8);

  /// 今日零点：[now] 所在调度时区的当日 00:00:00 对应的时刻。
  static DateTime todayStart(
    DateTime now, {
    String timezone = AppConstants.defaultTimezone,
  }) {
    if (timezone == AppConstants.defaultTimezone) {
      final shanghai = now.toUtc().add(_shanghaiOffset);
      final startUtc = DateTime.utc(shanghai.year, shanghai.month, shanghai.day);
      return startUtc.subtract(_shanghaiOffset).toLocal();
    }
    return DateTime(now.year, now.month, now.day);
  }

  /// 今日结束（今日零点 + 1 天 − 1ms），用于 `due_date <= 今日结束` 的闭区间
  /// 过滤（TECH_DOC §6.1）。
  static DateTime todayEnd(
    DateTime now, {
    String timezone = AppConstants.defaultTimezone,
  }) {
    return todayStart(now, timezone: timezone)
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
  }

  /// 本地日键 YYYY-MM-DD（daily_stats.day，§8.1），与 SessionDriver 内部
  /// 日键口径一致（纯字符串补零、不依赖 intl）。
  static String localDayKey(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    return '${time.year}-$month-$day';
  }
}
