import 'package:drift/drift.dart';

import '../../domain/models/review_log.dart';
import '../../domain/scheduling/fsrs_scheduler.dart';
import '../../domain/sessions/session_snapshot.dart';
import '../../domain/services/review_log_repository.dart';
import '../local/app_database.dart';

/// 复习日志仓储实现（Drift，TECH_DOC §8.1 review_logs，追加式、可导出 T-06）。
///
/// 追加式写入不更新既有行；getLogs 按 reviewed_at 闭区间过滤（跨日导出不漏
/// 边界记录），并按时序升序返回便于导出/调参。
class DriftReviewLogRepository implements ReviewLogRepository {
  DriftReviewLogRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> add(ReviewLog log) {
    return _db.into(_db.reviewLogs).insert(
      ReviewLogsCompanion.insert(
        userId: Value(log.userId),
        wordbookId: log.wordbookId,
        wordId: log.wordId,
        rating: log.rating.value,
        reviewedAt: log.reviewedAt.millisecondsSinceEpoch,
        intervalDays: Value(log.intervalDays),
        stability: Value(log.stability),
        difficulty: Value(log.difficulty),
        sessionId: Value(log.sessionId),
        sessionType: log.sessionType.storageValue,
      ),
    );
  }

  @override
  Future<List<ReviewLog>> getLogs({DateTime? from, DateTime? to}) {
    final fromMs = from?.millisecondsSinceEpoch;
    final toMs = to?.millisecondsSinceEpoch;
    final query = _db.select(_db.reviewLogs)
      ..orderBy([(t) => OrderingTerm(expression: t.reviewedAt)]);
    if (fromMs != null) {
      query.where((t) => t.reviewedAt.isBiggerOrEqualValue(fromMs));
    }
    if (toMs != null) {
      query.where((t) => t.reviewedAt.isSmallerOrEqualValue(toMs));
    }
    return query.get().then((rows) => [for (final row in rows) _toDomain(row)]);
  }

  ReviewLog _toDomain(ReviewLogRow row) => ReviewLog(
    id: row.id,
    userId: row.userId,
    wordbookId: row.wordbookId,
    wordId: row.wordId,
    rating: _ratingFrom(row.rating),
    reviewedAt: DateTime.fromMillisecondsSinceEpoch(row.reviewedAt),
    intervalDays: row.intervalDays,
    stability: row.stability,
    difficulty: row.difficulty,
    sessionId: row.sessionId,
    sessionType: _sessionTypeFrom(row.sessionType),
  );

  Rating _ratingFrom(int value) => switch (value) {
    1 => Rating.again,
    2 => Rating.hard,
    3 => Rating.good,
    4 => Rating.easy,
    _ => throw StateError('review_logs 损坏：未知评分值 $value'),
  };

  SessionType _sessionTypeFrom(String value) => switch (value) {
    'learning' => SessionType.learning,
    'review' => SessionType.review,
    _ => throw StateError('review_logs 损坏：未知 session_type=$value'),
  };
}
