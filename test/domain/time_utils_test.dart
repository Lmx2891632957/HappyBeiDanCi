/// TimeUtils 单测：Asia/Shanghai 日边界与日键（TECH_DOC §18 时区口径）。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/core/time_utils.dart';

void main() {
  group('Asia/Shanghai 日边界（固定 UTC+8，无夏令时）', () {
    test('今日零点：UTC 时刻 +8h 截断到日期', () {
      // 2026-08-12 00:00 +08 == 2026-08-11 16:00 UTC。
      final now = DateTime.utc(2026, 8, 11, 16, 30);
      final start = TimeUtils.todayStart(now);
      expect(
        start.millisecondsSinceEpoch,
        DateTime.utc(2026, 8, 11, 16).millisecondsSinceEpoch,
      );
    });

    test('今日结束 = 今日零点 + 1 天 − 1ms', () {
      final now = DateTime.utc(2026, 8, 11, 16, 30);
      final end = TimeUtils.todayEnd(now);
      final start = TimeUtils.todayStart(now);
      expect(
        end.millisecondsSinceEpoch,
        start.add(const Duration(days: 1)).millisecondsSinceEpoch - 1,
      );
    });

    test('跨日边界：UTC 15:59 属昨日、16:00 属今日', () {
      final before = TimeUtils.todayStart(DateTime.utc(2026, 8, 11, 15, 59));
      final after = TimeUtils.todayStart(DateTime.utc(2026, 8, 11, 16));
      expect(
        after.millisecondsSinceEpoch - before.millisecondsSinceEpoch,
        const Duration(days: 1).inMilliseconds,
      );
    });
  });

  test('非 Asia/Shanghai 时区暂按设备本地日期近似（M2 前取舍）', () {
    final now = DateTime(2026, 8, 12, 10, 30);
    final start = TimeUtils.todayStart(now, timezone: 'America/New_York');
    expect(start.millisecondsSinceEpoch, DateTime(2026, 8, 12).millisecondsSinceEpoch);
  });

  test('localDayKey：YYYY-MM-DD 补零', () {
    expect(TimeUtils.localDayKey(DateTime(2026, 8, 12)), '2026-08-12');
    expect(TimeUtils.localDayKey(DateTime(2026, 1, 3)), '2026-01-03');
  });
}
