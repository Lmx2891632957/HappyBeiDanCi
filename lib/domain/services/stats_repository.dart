import '../models/daily_stats.dart';

/// 每日统计仓储契约（打卡/统计页数据，TECH_DOC §8.1 daily_stats）。
abstract interface class StatsRepository {
  Future<DailyStats?> getByDay(String day);

  Future<void> upsert(DailyStats stats);
}
