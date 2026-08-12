import 'package:drift/drift.dart';

import '../../domain/sessions/session_snapshot.dart';
import '../../domain/services/session_repository.dart';
import '../local/app_database.dart';

/// 会话快照仓储实现（Drift）：sessions/session_items 两表读写（TD-07）。
///
/// 为什么全量替换 items：快照是剩余队列的唯一编码，逐行 diff 无收益且易残留
/// 旧行（TECH_DOC §5.4）；为什么同事务：sessions 与 session_items 必须同时
/// 可见或同时不可见，部分写入会制造"缺 sessions 行的 session_items"式损坏
/// （T-05 恢复一致性）。
class DriftSessionRepository implements SessionRepository {
  DriftSessionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(SessionSnapshot snapshot) {
    return _db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final sessionId = snapshot.sessionId;
      final existing = await (_db.select(_db.sessions)
            ..where((t) => t.id.equals(sessionId)))
          .getSingleOrNull();

      if (existing == null) {
        await _db.into(_db.sessions).insert(
          SessionsCompanion.insert(
            id: sessionId,
            sessionType: snapshot.type.storageValue,
            createdAt: now,
            updatedAt: now,
            position: Value(snapshot.position),
          ),
        );
      } else {
        // 覆盖保存保留 created_at、仅刷新 updated_at 与进度/类型（TECH_DOC §5.4）。
        await (_db.update(_db.sessions)
              ..where((t) => t.id.equals(sessionId)))
            .write(
              SessionsCompanion(
                sessionType: Value(snapshot.type.storageValue),
                updatedAt: Value(now),
                position: Value(snapshot.position),
              ),
            );
      }

      // 全量替换：先清空旧 items 再写入新队列，保证与快照完全一致。
      await (_db.delete(_db.sessionItems)
            ..where((t) => t.sessionId.equals(sessionId)))
          .go();
      final items = snapshot.items;
      if (items.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(_db.sessionItems, [
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
    });
  }

  @override
  Future<SessionSnapshot?> load(String sessionId) async {
    final session = await (_db.select(_db.sessions)
          ..where((t) => t.id.equals(sessionId)))
        .getSingleOrNull();
    final items = await (_db.select(_db.sessionItems)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm(expression: t.seq)]))
        .get();
    if (session == null) {
      if (items.isNotEmpty) {
        throw StateError(
          '会话快照损坏：存在 session_items 但缺少 sessions 行（sessionId=$sessionId）',
        );
      }
      return null;
    }
    return _assemble(session, items);
  }

  @override
  Future<List<SessionSnapshot>> loadAll() async {
    // 最新会话优先（TECH_DOC §5.1：今日页"继续上次未完成的学习"取最近一个）；
    // updated_at 由每次快照保存刷新（§5.4 时间戳语义）。
    final sessions = await (_db.select(_db.sessions)
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.updatedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
    if (sessions.isEmpty) {
      return const [];
    }
    final allItems = await (_db.select(_db.sessionItems)
          ..orderBy([
            (t) => OrderingTerm(expression: t.sessionId),
            (t) => OrderingTerm(expression: t.seq),
          ]))
        .get();
    final sessionIds = {for (final s in sessions) s.id};
    final bySession = <String, List<SessionItemRow>>{};
    for (final item in allItems) {
      // 孤儿行只可能来自损坏或手工写入，与 load 口径一致地拒绝而非忽略。
      if (!sessionIds.contains(item.sessionId)) {
        throw StateError(
          '会话快照损坏：存在无对应 sessions 行的 session_items'
          '（sessionId=${item.sessionId}）',
        );
      }
      bySession.putIfAbsent(item.sessionId, () => []).add(item);
    }
    return [
      for (final session in sessions)
        _assemble(session, bySession[session.id] ?? const []),
    ];
  }

  @override
  Future<void> delete(String sessionId) {
    return _db.transaction(() async {
      await (_db.delete(_db.sessionItems)
            ..where((t) => t.sessionId.equals(sessionId)))
          .go();
      await (_db.delete(_db.sessions)
            ..where((t) => t.id.equals(sessionId)))
          .go();
    });
  }

  /// 行 → 快照组装；校验项与状态机 `_restoreFromSnapshot` 拒绝非法输入的口径
  /// 一致（TECH_DOC §5.4）：缺 sessions 行已在调用方处理，这里覆盖 seq 不连续、
  /// position/requeueLeft/wordId 为负、未知 session_type。
  SessionSnapshot _assemble(SessionRow session, List<SessionItemRow> rows) {
    if (session.position < 0) {
      throw StateError(
        '会话快照损坏：position 为负（sessionId=${session.id}, '
        'position=${session.position}）',
      );
    }
    final type = switch (session.sessionType) {
      'learning' => SessionType.learning,
      'review' => SessionType.review,
      _ => throw StateError(
        '会话快照损坏：未知 session_type（sessionId=${session.id}, '
        'type=${session.sessionType}）',
      ),
    };
    final items = <SessionItemSnapshot>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.seq != i) {
        throw StateError(
          '会话快照损坏：seq 不连续（sessionId=${session.id}, '
          '期望 $i 实际 ${row.seq}）',
        );
      }
      if (row.requeueLeft < 0) {
        throw StateError(
          '会话快照损坏：requeueLeft 为负（sessionId=${session.id}, '
          'wordId=${row.wordId}）',
        );
      }
      if (row.wordId < 0) {
        throw StateError(
          '会话快照损坏：wordId 为负（sessionId=${session.id}, '
          'wordId=${row.wordId}）',
        );
      }
      items.add(
        SessionItemSnapshot(
          wordId: row.wordId,
          seq: row.seq,
          requeueLeft: row.requeueLeft,
        ),
      );
    }
    return SessionSnapshot(
      sessionId: session.id,
      type: type,
      position: session.position,
      items: items,
    );
  }
}
