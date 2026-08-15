/// 每日提醒触发时刻计算测试（TECH_DOC §11.1）：当日未到 → 当日；
/// 已过 → 次日；跨日边界与时区换算正确。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/domain/services/reminder_schedule_calculator.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz_data.initializeTimeZones();
  const calculator = ReminderScheduleCalculator();
  final shanghai = tz.getLocation('Asia/Shanghai');
  final newYork = tz.getLocation('America/New_York');

  test('当日未到提醒时刻 → 返回当日（Asia/Shanghai）', () {
    final now = DateTime.utc(2026, 8, 12, 2, 0); // 上海 10:00
    final next = calculator.nextOccurrence(
      now: now,
      location: shanghai,
      hour: 20,
      minute: 0,
    );
    expect(next.year, 2026);
    expect(next.month, 8);
    expect(next.day, 12);
    expect(next.hour, 20);
    expect(next.minute, 0);
  });

  test('当日已过提醒时刻 → 次日', () {
    final now = DateTime.utc(2026, 8, 12, 14, 0); // 上海 22:00
    final next = calculator.nextOccurrence(
      now: now,
      location: shanghai,
      hour: 20,
      minute: 0,
    );
    expect(next.day, 13);
    expect(next.hour, 20);
  });

  test('恰好等于提醒时刻 → 视为已过，顺延到次日', () {
    final now = DateTime.utc(2026, 8, 12, 12, 0); // 上海 20:00 整
    final next = calculator.nextOccurrence(
      now: now,
      location: shanghai,
      hour: 20,
      minute: 0,
    );
    expect(next.day, 13);
  });

  test('跨时区：UTC 时刻按目标时区换算（America/New_York 夏令时）', () {
    // 2026-08-12 UTC 23:30 = 纽约 19:30（EDT UTC-4）。
    final now = DateTime.utc(2026, 8, 12, 23, 30);
    final next = calculator.nextOccurrence(
      now: now,
      location: newYork,
      hour: 20,
      minute: 0,
    );
    expect(next.day, 12);
    expect(next.hour, 20);
    expect(next.minute, 0);
    // 换算回 UTC：2026-08-12 20:00 EDT = 2026-08-13 00:00 UTC。
    expect(next.toUtc().day, 13);
    expect(next.toUtc().hour, 0);
  });
}
