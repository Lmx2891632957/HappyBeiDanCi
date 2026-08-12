/// Stats 仓储集成测试：daily_stats 按天 upsert 与读取（TECH_DOC §8.1，AGENTS §7）。
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_stats_repository.dart';
import 'package:happy_bei_dan_ci/domain/models/daily_stats.dart';
import 'package:happy_bei_dan_ci/domain/services/stats_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'happy_beidanci_stats_repo',
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  (AppDatabase, StatsRepository) openRepo(String name) {
    final db = AppDatabase.forTesting(
      NativeDatabase(File('${tempDir.path}/$name.db')),
    );
    addTearDown(db.close);
    return (db, DriftStatsRepository(db));
  }

  test('getByDay 无记录返回 null；upsert→getByDay 逐字段往返', () async {
    final (_, repo) = openRepo('roundtrip');
    expect(await repo.getByDay('2026-08-12'), isNull);

    await repo.upsert(
      const DailyStats(
        day: '2026-08-12',
        newCount: 20,
        reviewCount: 45,
        correctCount: 38,
        completed: 1,
      ),
    );
    final loaded = await repo.getByDay('2026-08-12');
    expect(loaded, isNotNull);
    expect(loaded!.day, '2026-08-12');
    expect(loaded.newCount, 20);
    expect(loaded.reviewCount, 45);
    expect(loaded.correctCount, 38);
    expect(loaded.completed, 1);
  });

  test('同一天 upsert 覆盖更新；不同天互不影响', () async {
    final (db, repo) = openRepo('overwrite');
    await repo.upsert(
      const DailyStats(day: '2026-08-12', newCount: 10, completed: 0),
    );
    await repo.upsert(
      const DailyStats(
        day: '2026-08-12',
        newCount: 10,
        reviewCount: 5,
        correctCount: 4,
        completed: 1,
      ),
    );
    await repo.upsert(const DailyStats(day: '2026-08-13', newCount: 20));

    final day1 = await repo.getByDay('2026-08-12');
    expect(day1!.reviewCount, 5);
    expect(day1.completed, 1);
    final day2 = await repo.getByDay('2026-08-13');
    expect(day2!.newCount, 20);
    expect(await db.select(db.dailyStats).get(), hasLength(2));
  });
}
