import '../sessions/session_snapshot.dart';
import '../scheduling/fsrs_scheduler.dart';

/// 复习日志领域模型（TECH_DOC §8.1 review_logs 表）。
///
/// 追加式写入、可导出（T-06），评分时记录当时的 S/D/间隔，供导出与后续
/// FSRS 参数优化（M3）使用。
class ReviewLog {
  const ReviewLog({
    this.id,
    this.userId = 0,
    required this.wordbookId,
    required this.wordId,
    required this.rating,
    required this.reviewedAt,
    this.intervalDays,
    this.stability,
    this.difficulty,
    this.sessionId,
    required this.sessionType,
  });

  final int? id;
  final int userId;
  final int wordbookId;
  final int wordId;
  final Rating rating;
  final DateTime reviewedAt;
  final double? intervalDays;
  final double? stability;
  final double? difficulty;
  final String? sessionId;
  final SessionType sessionType;
}
