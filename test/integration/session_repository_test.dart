/// 会话快照仓储集成测试（TD-07，TECH_DOC §5.4 快照持久化口径）：
/// 保存/加载往返、覆盖保存、删除、loadAll、事务一致性（AGENTS §6.3/§7）。
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_session_repository.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_snapshot.dart';
import 'package:happy_bei_dan_ci/domain/services/session_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('happy_beidanci_session_repo');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  (AppDatabase, SessionRepository) openRepo(String name) {
    final db = AppDatabase.forTesting(
      NativeDatabase(File('${tempDir.path}/$name.db')),
    );
    addTearDown(db.close);
    return (db, DriftSessionRepository(db));
  }

  SessionSnapshot snap({
    String sessionId = 's1',
    SessionType type = SessionType.learning,
    int position = 0,
    List<SessionItemSnapshot> items = const [],
  }) => SessionSnapshot(
    sessionId: sessionId,
    type: type,
    position: position,
    items: items,
  );

  test('保存→加载往返：position、items 顺序与 requeueLeft 逐字段一致', () async {
    final (db, repo) = openRepo('roundtrip');
    await repo.save(
      snap(
        sessionId: 's1',
        type: SessionType.review,
        position: 3,
        items: const [
          SessionItemSnapshot(wordId: 10, seq: 0, requeueLeft: 2),
          SessionItemSnapshot(wordId: 20, seq: 1, requeueLeft: 1),
          SessionItemSnapshot(wordId: 30, seq: 2, requeueLeft: 0),
        ],
      ),
    );

    final loaded = await repo.load('s1');
    expect(loaded, isNotNull);
    expect(loaded!.sessionId, 's1');
    expect(loaded.type, SessionType.review);
    expect(loaded.position, 3);
    expect(loaded.items.map((e) => e.wordId).toList(), [10, 20, 30]);
    expect(loaded.items.map((e) => e.seq).toList(), [0, 1, 2]);
    expect(loaded.items.map((e) => e.requeueLeft).toList(), [2, 1, 0]);

    // 事务一致性：两表行数一一对应（§5.4）。
    expect(await db.select(db.sessions).get(), hasLength(1));
    expect(await db.select(db.sessionItems).get(), hasLength(3));
  });

  test('多个会话并存；空 items（队列为空但未完成）可往返', () async {
    final (_, repo) = openRepo('multi');
    await repo.save(
      snap(
        sessionId: 'a',
        type: SessionType.learning,
        position: 1,
        items: const [
          SessionItemSnapshot(wordId: 1, seq: 0, requeueLeft: 2),
        ],
      ),
    );
    await repo.save(
      snap(
        sessionId: 'b',
        type: SessionType.review,
        position: 5,
        items: const [],
      ),
    );

    final a = await repo.load('a');
    expect(a!.items.single.wordId, 1);
    final b = await repo.load('b');
    expect(b!.position, 5);
    expect(b.items, isEmpty);
    expect(await repo.load('missing'), isNull);
  });

  test('loadAll 返回全部未完成快照（learning 与 review 混合）', () async {
    final (_, repo) = openRepo('load_all');
    await repo.save(
      snap(
        sessionId: 'learn-1',
        type: SessionType.learning,
        position: 0,
        items: const [
          SessionItemSnapshot(wordId: 1, seq: 0, requeueLeft: 2),
        ],
      ),
    );
    await repo.save(
      snap(
        sessionId: 'review-1',
        type: SessionType.review,
        position: 2,
        items: const [
          SessionItemSnapshot(wordId: 3, seq: 0, requeueLeft: 1),
          SessionItemSnapshot(wordId: 4, seq: 1, requeueLeft: 0),
        ],
      ),
    );

    final all = await repo.loadAll();
    expect(all, hasLength(2));
    expect({for (final s in all) s.sessionId}, {'learn-1', 'review-1'});
    expect(
      {for (final s in all) s.type},
      {SessionType.learning, SessionType.review},
    );
    final review = all.singleWhere((s) => s.sessionId == 'review-1');
    expect(review.items.map((e) => e.wordId).toList(), [3, 4]);
  });

  test('覆盖保存：同 sessionId 新快照生效，旧 items 不残留', () async {
    final (db, repo) = openRepo('overwrite');
    await repo.save(
      snap(
        sessionId: 's',
        position: 0,
        items: const [
          SessionItemSnapshot(wordId: 1, seq: 0, requeueLeft: 2),
          SessionItemSnapshot(wordId: 2, seq: 1, requeueLeft: 2),
        ],
      ),
    );
    await repo.save(
      snap(
        sessionId: 's',
        position: 1,
        items: const [
          SessionItemSnapshot(wordId: 2, seq: 0, requeueLeft: 1),
        ],
      ),
    );

    final loaded = await repo.load('s');
    expect(loaded!.position, 1);
    expect(loaded.items.map((e) => e.wordId).toList(), [2]);
    expect(loaded.items.single.requeueLeft, 1);
    expect(await db.select(db.sessionItems).get(), hasLength(1));
  });

  test('覆盖保存保留 created_at、刷新 updated_at', () async {
    final (db, repo) = openRepo('timestamps');
    await repo.save(snap(sessionId: 's'));
    final before = await db.select(db.sessions).getSingle();

    // 等待时钟前进至少 1ms，确保 updated_at 严格刷新（§5.4 时间戳语义）。
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.save(
      snap(
        sessionId: 's',
        position: 1,
        items: const [
          SessionItemSnapshot(wordId: 9, seq: 0, requeueLeft: 2),
        ],
      ),
    );

    final after = await db.select(db.sessions).getSingle();
    expect(after.createdAt, before.createdAt);
    expect(after.updatedAt, greaterThan(before.updatedAt));
    expect(after.position, 1);
  });

  test('删除：load 返回 null，sessions/session_items 两表均无残留', () async {
    final (db, repo) = openRepo('delete');
    await repo.save(
      snap(
        sessionId: 's',
        items: const [
          SessionItemSnapshot(wordId: 1, seq: 0, requeueLeft: 2),
        ],
      ),
    );
    await repo.delete('s');

    expect(await repo.load('s'), isNull);
    expect(await db.select(db.sessions).get(), isEmpty);
    expect(await db.select(db.sessionItems).get(), isEmpty);
  });

  test('删除不存在的会话是幂等空操作', () async {
    final (db, repo) = openRepo('delete_missing');
    await repo.delete('missing');
    expect(await db.select(db.sessions).get(), isEmpty);
    expect(await db.select(db.sessionItems).get(), isEmpty);
  });

  test('事务一致性：items 写入失败时整体回滚，不残留部分数据', () async {
    final (db, repo) = openRepo('rollback');
    await repo.save(
      snap(
        sessionId: 's',
        position: 0,
        items: const [
          SessionItemSnapshot(wordId: 1, seq: 0, requeueLeft: 2),
        ],
      ),
    );

    // 注入 (session_id, word_id) 主键冲突使 items 批量写入失败；save 应整体
    // 回滚——sessions 行与旧 items 均保持原状（§5.4 同事务语义）。
    await expectLater(
      repo.save(
        snap(
          sessionId: 's',
          position: 1,
          items: const [
            SessionItemSnapshot(wordId: 9, seq: 0, requeueLeft: 2),
            SessionItemSnapshot(wordId: 9, seq: 1, requeueLeft: 1),
          ],
        ),
      ),
      throwsA(isA<SqliteException>()),
    );

    final loaded = await repo.load('s');
    expect(loaded!.position, 0);
    expect(loaded.items.map((e) => e.wordId).toList(), [1]);
    expect(await db.select(db.sessionItems).get(), hasLength(1));
  });

  group('损坏快照口径：load/loadAll 抛 StateError，不静默丢弃（§5.4）', () {
    // 损坏态无法经仓储构造（save 只写合法快照），只能直接写表制造，用于
    // 验证 load 的校验路径。
    Future<void> seedCorruptRow(
      AppDatabase db,
      String sessionId, {
      required String sessionType,
      int position = 0,
      List<({int wordId, int seq, int requeueLeft})> items = const [],
    }) async {
      await db.into(db.sessions).insert(
        SessionsCompanion.insert(
          id: sessionId,
          sessionType: sessionType,
          createdAt: 1,
          updatedAt: 1,
          position: Value(position),
        ),
      );
      if (items.isNotEmpty) {
        await db.batch((batch) {
          batch.insertAll(db.sessionItems, [
            for (final item in items)
              SessionItemsCompanion.insert(
                sessionId: sessionId,
                wordId: item.wordId,
                seq: item.seq,
                requeueLeft: Value(item.requeueLeft),
              ),
          ]);
        });
      }
    }

    test('seq 不连续被拒绝', () async {
      final (db, repo) = openRepo('corrupt_seq');
      await seedCorruptRow(
        db,
        's',
        sessionType: 'learning',
        items: [
          (wordId: 1, seq: 0, requeueLeft: 2),
          (wordId: 2, seq: 2, requeueLeft: 2),
        ],
      );
      await expectLater(repo.load('s'), throwsA(isA<StateError>()));
    });

    test('存在 items 但缺 sessions 行被拒绝', () async {
      final (db, repo) = openRepo('corrupt_orphan');
      await db.into(db.sessionItems).insert(
        SessionItemsCompanion.insert(
          sessionId: 's',
          wordId: 1,
          seq: 0,
          requeueLeft: const Value(2),
        ),
      );
      await expectLater(repo.load('s'), throwsA(isA<StateError>()));
    });

    test('未知 session_type 被拒绝', () async {
      final (db, repo) = openRepo('corrupt_type');
      await seedCorruptRow(db, 's', sessionType: 'typo');
      await expectLater(repo.load('s'), throwsA(isA<StateError>()));
    });

    test('position 为负被拒绝', () async {
      final (db, repo) = openRepo('corrupt_position');
      await seedCorruptRow(db, 's', sessionType: 'learning', position: -1);
      await expectLater(repo.load('s'), throwsA(isA<StateError>()));
    });

    test('requeueLeft 为负被拒绝', () async {
      final (db, repo) = openRepo('corrupt_requeue');
      await seedCorruptRow(
        db,
        's',
        sessionType: 'learning',
        items: [
          (wordId: 1, seq: 0, requeueLeft: -1),
        ],
      );
      await expectLater(repo.load('s'), throwsA(isA<StateError>()));
    });

    test('loadAll 对孤儿 items 整体抛错', () async {
      final (db, repo) = openRepo('corrupt_orphan_all');
      await seedCorruptRow(
        db,
        'ok',
        sessionType: 'learning',
        items: [
          (wordId: 1, seq: 0, requeueLeft: 2),
        ],
      );
      await db.into(db.sessionItems).insert(
        SessionItemsCompanion.insert(
          sessionId: 'orphan',
          wordId: 2,
          seq: 0,
          requeueLeft: const Value(2),
        ),
      );
      await expectLater(repo.loadAll(), throwsA(isA<StateError>()));
    });

    test('空库 loadAll 返回空列表', () async {
      final (_, repo) = openRepo('empty');
      expect(await repo.loadAll(), isEmpty);
    });
  });
}
