import 'package:drift/drift.dart';

/// 用户学习状态表（TECH_DOC §8.1）：FSRS 调度核心，每词一行。
///
/// 与词库静态表分离：词库升级整体替换 words 时不影响本表进度。
@TableIndex(name: 'idx_user_words_due', columns: {#status, #dueDate})
@DataClassName('UserWordRow')
class UserWords extends Table {
  IntColumn get userId => integer().withDefault(const Constant(0))();
  IntColumn get wordbookId => integer()();
  IntColumn get wordId => integer()();
  TextColumn get state => text()();
  TextColumn get status => text()();
  IntColumn get dueDate => integer().nullable()();
  RealColumn get stability => real().withDefault(const Constant(0))();
  RealColumn get difficulty => real().withDefault(const Constant(0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  IntColumn get lastReviewAt => integer().nullable()();
  IntColumn get lastRating => integer().nullable()();
  RealColumn get elapsedDays => real().nullable()();
  RealColumn get scheduledDays => real().nullable()();

  @override
  Set<Column> get primaryKey => {userId, wordbookId, wordId};
}
