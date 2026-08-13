import 'package:timezone/timezone.dart' as tz;

/// 每日提醒首次触发时刻计算（纯函数，TECH_DOC §11.1）。
///
/// flutter_local_notifications 的 `matchDateTimeComponents: time` 负责后续
/// 每日循环，本计算器只求"下一次 hour:minute"的 TZDateTime：优先当日，
/// 已过则次日，跨时区/跨日边界均可单测。
class ReminderScheduleCalculator {
  const ReminderScheduleCalculator();

  tz.TZDateTime nextOccurrence({
    required DateTime now,
    required tz.Location location,
    required int hour,
    required int minute,
  }) {
    var candidate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
