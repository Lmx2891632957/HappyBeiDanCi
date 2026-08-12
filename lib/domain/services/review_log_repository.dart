import '../models/review_log.dart';

/// 复习日志仓储契约（追加式、可导出，T-06）。
abstract interface class ReviewLogRepository {
  Future<void> add(ReviewLog log);

  /// 按时间范围导出评分记录（数据导出功能，TECH_DOC §8.2）。
  Future<List<ReviewLog>> getLogs({DateTime? from, DateTime? to});
}
