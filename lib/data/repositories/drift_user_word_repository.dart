import 'package:drift/drift.dart';

import '../../domain/models/user_word.dart';
import '../../domain/services/user_word_repository.dart';
import '../local/app_database.dart';

/// 用户学习状态仓储实现（Drift，TECH_DOC §8.1 user_words，FSRS 调度核心）。
///
/// 时间列按 epoch 毫秒存取（§7.5）；state/status 以 storageValue 文本存取；
/// 评分后 upsert 走单写连接（§8.2），同键覆盖整行。
class DriftUserWordRepository implements UserWordRepository {
  DriftUserWordRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<UserWord>> getDueWords({
    required DateTime todayEnd,
    int? limit,
  }) {
    // 只按 due_date <= 今日结束过滤，排序与软上限由队列构建器负责（§6.2）；
    // due_date 为空的词不匹配该条件（SQL NULL 语义），符合"空 due_date 不进
    // 到期列表"（§6.2）。按 (due_date, word_id) 稳定排序便于测试与导出。
    final query = _db.select(_db.userWords)
      ..where(
        (t) => t.dueDate.isSmallerOrEqualValue(todayEnd.millisecondsSinceEpoch),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.dueDate),
        (t) => OrderingTerm(expression: t.wordId),
      ]);
    if (limit != null) {
      query.limit(limit);
    }
    return query.get().then((rows) => [for (final row in rows) _toDomain(row)]);
  }

  @override
  Future<UserWord?> getWord({
    required int userId,
    required int wordbookId,
    required int wordId,
  }) async {
    final row = await (_db.select(_db.userWords)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.wordbookId.equals(wordbookId) &
                t.wordId.equals(wordId),
          ))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> upsert(UserWord word) {
    // insertOnConflictUpdate：主键 (user_id, wordbook_id, word_id) 冲突时覆盖
    // 全部列，等效"评分后更新该词状态"，无需先查后写（§8.2 单写连接）。
    return _db.into(_db.userWords).insertOnConflictUpdate(_toRow(word));
  }

  UserWordsCompanion _toRow(UserWord word) => UserWordsCompanion(
    userId: Value(word.userId),
    wordbookId: Value(word.wordbookId),
    wordId: Value(word.wordId),
    state: Value(word.state.storageValue),
    status: Value(word.status.storageValue),
    dueDate: Value(word.dueDate?.millisecondsSinceEpoch),
    stability: Value(word.stability),
    difficulty: Value(word.difficulty),
    reps: Value(word.reps),
    lapses: Value(word.lapses),
    lastReviewAt: Value(word.lastReviewAt?.millisecondsSinceEpoch),
    lastRating: Value(word.lastRating),
    elapsedDays: Value(word.elapsedDays),
    scheduledDays: Value(word.scheduledDays),
  );

  UserWord _toDomain(UserWordRow row) => UserWord(
    userId: row.userId,
    wordbookId: row.wordbookId,
    wordId: row.wordId,
    state: _stateFrom(row.state),
    status: _statusFrom(row.status),
    dueDate: row.dueDate == null ? null : DateTime.fromMillisecondsSinceEpoch(row.dueDate!),
    stability: row.stability,
    difficulty: row.difficulty,
    reps: row.reps,
    lapses: row.lapses,
    lastReviewAt: row.lastReviewAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.lastReviewAt!),
    lastRating: row.lastRating,
    elapsedDays: row.elapsedDays,
    scheduledDays: row.scheduledDays,
  );

  /// 存储文本 → 枚举；未知值抛错而非静默兜底，与快照仓储损坏口径一致
  /// （数据库写坏时尽早暴露，避免静默改写调度状态）。
  WordLearningState _stateFrom(String value) => switch (value) {
    'new' => WordLearningState.new_,
    'learning' => WordLearningState.learning,
    'review' => WordLearningState.review,
    'relearning' => WordLearningState.relearning,
    _ => throw StateError('user_words 损坏：未知 state=$value'),
  };

  WordStatus _statusFrom(String value) => switch (value) {
    'learning' => WordStatus.learning,
    'review' => WordStatus.review,
    'mature' => WordStatus.mature,
    _ => throw StateError('user_words 损坏：未知 status=$value'),
  };
}
