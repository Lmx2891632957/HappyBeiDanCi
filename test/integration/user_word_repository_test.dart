/// UserWord 仓储集成测试：字段映射（storageValue / epoch 毫秒）、主键 upsert、
/// getDueWords 到期过滤（TECH_DOC §7.2/§8.1，AGENTS §7）。
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_user_word_repository.dart';
import 'package:happy_bei_dan_ci/domain/models/user_word.dart';
import 'package:happy_bei_dan_ci/domain/services/user_word_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'happy_beidanci_user_word_repo',
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  (AppDatabase, UserWordRepository) openRepo(String name) {
    final db = AppDatabase.forTesting(
      NativeDatabase(File('${tempDir.path}/$name.db')),
    );
    addTearDown(db.close);
    return (db, DriftUserWordRepository(db));
  }

  test('upsert→getWord 往返：枚举与时间列逐字段一致（storageValue/epoch 毫秒）', () async {
    final (db, repo) = openRepo('roundtrip');
    final due = DateTime(2026, 8, 13, 10);
    final lastReview = DateTime(2026, 8, 12, 9, 30);
    await repo.upsert(
      UserWord(
        userId: 0,
        wordbookId: 5,
        wordId: 11,
        state: WordLearningState.relearning,
        status: WordStatus.learning,
        dueDate: due,
        stability: 2.5,
        difficulty: 4.25,
        reps: 3,
        lapses: 1,
        lastReviewAt: lastReview,
        lastRating: 2,
        elapsedDays: 0.02,
        scheduledDays: 0.5,
      ),
    );

    final loaded = await repo.getWord(userId: 0, wordbookId: 5, wordId: 11);
    expect(loaded, isNotNull);
    expect(loaded!.userId, 0);
    expect(loaded.wordbookId, 5);
    expect(loaded.wordId, 11);
    expect(loaded.state, WordLearningState.relearning);
    expect(loaded.status, WordStatus.learning);
    expect(loaded.dueDate, due);
    expect(loaded.stability, 2.5);
    expect(loaded.difficulty, 4.25);
    expect(loaded.reps, 3);
    expect(loaded.lapses, 1);
    expect(loaded.lastReviewAt, lastReview);
    expect(loaded.lastRating, 2);
    expect(loaded.elapsedDays, 0.02);
    expect(loaded.scheduledDays, 0.5);

    // 存储层校验：文本枚举与 epoch 毫秒（TECH_DOC §8.1/§7.5）。
    final row = await (db.select(
      db.userWords,
    )..where((t) => t.wordId.equals(11))).getSingle();
    expect(row.state, 'relearning');
    expect(row.status, 'learning');
    expect(row.dueDate, due.millisecondsSinceEpoch);
    expect(row.lastReviewAt, lastReview.millisecondsSinceEpoch);
  });

  test('同主键 upsert 覆盖更新整行，不产生重复行', () async {
    final (db, repo) = openRepo('overwrite');
    await repo.upsert(
      UserWord(
        wordbookId: 1,
        wordId: 1,
        state: WordLearningState.learning,
        status: WordStatus.learning,
        reps: 1,
      ),
    );
    await repo.upsert(
      UserWord(
        wordbookId: 1,
        wordId: 1,
        state: WordLearningState.review,
        status: WordStatus.review,
        stability: 9.9,
        reps: 2,
      ),
    );

    final loaded = await repo.getWord(userId: 0, wordbookId: 1, wordId: 1);
    expect(loaded!.state, WordLearningState.review);
    expect(loaded.status, WordStatus.review);
    expect(loaded.stability, 9.9);
    expect(loaded.reps, 2);
    expect(await db.select(db.userWords).get(), hasLength(1));
  });

  test('getWord 不存在返回 null', () async {
    final (_, repo) = openRepo('missing');
    expect(await repo.getWord(userId: 0, wordbookId: 1, wordId: 99), isNull);
  });

  test('getAll：全量返回并按 wordbook_id/word_id 稳定排序（数据导出，§8.2）', () async {
    final (_, repo) = openRepo('get_all');
    for (final (bookId, wordId) in const [(2, 3), (1, 2), (1, 1), (2, 1)]) {
      await repo.upsert(
        UserWord(
          userId: 0,
          wordbookId: bookId,
          wordId: wordId,
          state: WordLearningState.learning,
          status: WordStatus.learning,
        ),
      );
    }
    final all = await repo.getAll();
    expect(all, hasLength(4));
    expect(
      [for (final w in all) (w.wordbookId, w.wordId)],
      [(1, 1), (1, 2), (2, 1), (2, 3)],
    );
  });

  test('getDueWords：按 due_date≤todayEnd 过滤、limit 生效、空 due_date 不入列', () async {
    final (_, repo) = openRepo('due');
    final todayEnd = DateTime(2026, 8, 12, 23, 59, 59, 999);
    final dueAtEnd = DateTime(2026, 8, 12, 23, 59, 59, 999);
    final future = DateTime(2026, 8, 13);
    final overdue = DateTime(2026, 8, 10);
    for (final (wordId, dueDate) in [
      (1, dueAtEnd),
      (2, future),
      (3, overdue),
      (4, null),
    ]) {
      await repo.upsert(
        UserWord(
          wordbookId: 1,
          wordId: wordId,
          state: WordLearningState.review,
          status: WordStatus.review,
          dueDate: dueDate,
          stability: wordId.toDouble(),
        ),
      );
    }

    final all = await repo.getDueWords(todayEnd: todayEnd);
    expect(all.map((e) => e.wordId).toSet(), {1, 3}); // 2 未到期、4 无 due_date

    final limited = await repo.getDueWords(todayEnd: todayEnd, limit: 1);
    expect(limited, hasLength(1));
  });

  test('未知 state/status 存储值抛 StateError（损坏不静默）', () async {
    final (db, repo) = openRepo('corrupt');
    await db
        .into(db.userWords)
        .insert(
          UserWordsCompanion.insert(
            wordbookId: 1,
            wordId: 1,
            state: 'typo',
            status: 'review',
            stability: const Value(0),
            difficulty: const Value(0),
          ),
        );
    await expectLater(
      repo.getWord(userId: 0, wordbookId: 1, wordId: 1),
      throwsA(isA<StateError>()),
    );
  });
}
