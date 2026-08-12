import 'package:drift/drift.dart';

/// 复习日志表（TECH_DOC §8.1）：追加式、可导出（T-06）。
@TableIndex(name: 'idx_review_logs_time', columns: {#reviewedAt})
@DataClassName('ReviewLogRow')
class ReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().withDefault(const Constant(0))();
  IntColumn get wordbookId => integer()();
  IntColumn get wordId => integer()();
  IntColumn get rating => integer()();
  IntColumn get reviewedAt => integer()();
  RealColumn get intervalDays => real().nullable()();
  RealColumn get stability => real().nullable()();
  RealColumn get difficulty => real().nullable()();
  TextColumn get sessionId => text().nullable()();
  TextColumn get sessionType => text()();
}
