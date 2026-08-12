import 'package:drift/drift.dart';

import '../../domain/models/daily_stats.dart';
import '../../domain/services/stats_repository.dart';
import '../local/app_database.dart';

/// 每日统计仓储实现（Drift，TECH_DOC §8.1 daily_stats，按天 upsert）。
///
/// 合并语义由调用方（SessionDriver.finish）负责"先读后合并再 upsert"，
/// 本实现只做单行读写，避免把累加规则写进仓储（AGENTS §3.2 分层纪律）。
class DriftStatsRepository implements StatsRepository {
  DriftStatsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<DailyStats?> getByDay(String day) async {
    final row = await (_db.select(
      _db.dailyStats,
    )..where((t) => t.day.equals(day))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> upsert(DailyStats stats) {
    // day 为主键：冲突时覆盖整行计数（调用方已合并，直接替换即正确语义）。
    return _db
        .into(_db.dailyStats)
        .insertOnConflictUpdate(
          DailyStatsCompanion(
            day: Value(stats.day),
            newCount: Value(stats.newCount),
            reviewCount: Value(stats.reviewCount),
            correctCount: Value(stats.correctCount),
            completed: Value(stats.completed),
          ),
        );
  }

  DailyStats _toDomain(DailyStatRow row) => DailyStats(
    day: row.day,
    newCount: row.newCount,
    reviewCount: row.reviewCount,
    correctCount: row.correctCount,
    completed: row.completed,
  );
}
