/// ReviewLog 仓储集成测试：追加式写入、时间范围过滤、字段映射
///（TECH_DOC §8.1 review_logs，T-06 可导出，AGENTS §7）。
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_review_log_repository.dart';
import 'package:happy_bei_dan_ci/domain/models/review_log.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs_scheduler.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_snapshot.dart';
import 'package:happy_bei_dan_ci/domain/services/review_log_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'happy_beidanci_review_log_repo',
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  (AppDatabase, ReviewLogRepository) openRepo(String name) {
    final db = AppDatabase.forTesting(
      NativeDatabase(File('${tempDir.path}/$name.db')),
    );
    addTearDown(db.close);
    return (db, DriftReviewLogRepository(db));
  }

  test('add→getLogs 往返：枚举映射、epoch 毫秒与会话上下文一致', () async {
    final (db, repo) = openRepo('roundtrip');
    final reviewedAt = DateTime(2026, 8, 12, 10, 30);
    await repo.add(
      ReviewLog(
        wordbookId: 2,
        wordId: 9,
        rating: Rating.hard,
        reviewedAt: reviewedAt,
        intervalDays: 0.02,
        stability: 2.5,
        difficulty: 4.0,
        sessionId: 's1',
        sessionType: SessionType.review,
      ),
    );

    final logs = await repo.getLogs();
    expect(logs, hasLength(1));
    final log = logs.single;
    expect(log.id, isNotNull); // AUTOINCREMENT 已分配
    expect(log.userId, 0);
    expect(log.wordbookId, 2);
    expect(log.wordId, 9);
    expect(log.rating, Rating.hard);
    expect(log.reviewedAt, reviewedAt);
    expect(log.intervalDays, 0.02);
    expect(log.stability, 2.5);
    expect(log.difficulty, 4.0);
    expect(log.sessionId, 's1');
    expect(log.sessionType, SessionType.review);

    // 存储层：rating 存整数值、reviewed_at 存 epoch 毫秒。
    final row = await db.select(db.reviewLogs).getSingle();
    expect(row.rating, 2);
    expect(row.reviewedAt, reviewedAt.millisecondsSinceEpoch);
  });

  test('追加式：多次 add 各成一行，id 递增且互不影响', () async {
    final (db, repo) = openRepo('append');
    await repo.add(
      ReviewLog(
        wordbookId: 1,
        wordId: 1,
        rating: Rating.again,
        reviewedAt: DateTime(2026, 8, 12, 9),
        sessionType: SessionType.learning,
      ),
    );
    await repo.add(
      ReviewLog(
        wordbookId: 1,
        wordId: 2,
        rating: Rating.good,
        reviewedAt: DateTime(2026, 8, 12, 10),
        sessionType: SessionType.learning,
      ),
    );

    final logs = await repo.getLogs();
    expect(logs, hasLength(2));
    expect(logs[0].id, isNotNull);
    expect(logs[1].id, isNotNull);
    expect(logs[0].id!, lessThan(logs[1].id!));
    expect(logs.map((e) => e.wordId).toList(), [1, 2]); // 按 reviewed_at 升序
    expect(await db.select(db.reviewLogs).get(), hasLength(2));
  });

  test('getLogs 时间范围：闭区间过滤，跨日边界不丢记录', () async {
    final (_, repo) = openRepo('range');
    final t1 = DateTime(2026, 8, 11, 23, 59, 59, 999);
    final t2 = DateTime(2026, 8, 12, 0, 0);
    final t3 = DateTime(2026, 8, 12, 23, 59, 59, 999);
    for (final (wordId, at) in [(1, t1), (2, t2), (3, t3)]) {
      await repo.add(
        ReviewLog(
          wordbookId: 1,
          wordId: wordId,
          rating: Rating.good,
          reviewedAt: at,
          sessionType: SessionType.review,
        ),
      );
    }

    final inRange = await repo.getLogs(
      from: DateTime(2026, 8, 12),
      to: DateTime(2026, 8, 12, 23, 59, 59, 999),
    );
    expect(inRange.map((e) => e.wordId).toList(), [2, 3]); // t1 在范围外

    final fromOnly = await repo.getLogs(from: DateTime(2026, 8, 12));
    expect(fromOnly, hasLength(2));

    final toOnly = await repo.getLogs(to: DateTime(2026, 8, 12));
    expect(toOnly.map((e) => e.wordId).toList(), [1, 2]);
  });

  test('未知 rating/session_type 存储值抛 StateError（损坏不静默）', () async {
    final (db, repo) = openRepo('corrupt');
    await db
        .into(db.reviewLogs)
        .insert(
          ReviewLogsCompanion.insert(
            wordbookId: 1,
            wordId: 1,
            rating: 9,
            reviewedAt: 1,
            sessionType: 'typo',
          ),
        );
    await expectLater(repo.getLogs(), throwsA(isA<StateError>()));
  });
}
