/// 中断恢复集成测试（驱动 + 真实 Drift 仓储，TECH_DOC §14.2/§5.4 TD-07）：
/// 学习中途 interrupt → 快照落库 → 跨驱动实例 resume → 队列一致并完成。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/core/time_utils.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_review_log_repository.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_session_repository.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_stats_repository.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_user_word_repository.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_wordbook_repository.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs/fsrs_engine.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs_scheduler.dart';
import 'package:happy_bei_dan_ci/domain/sessions/default_session_state_machine.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_driver.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_snapshot.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_state_machine.dart';

import '../helpers/fixture.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('happy_beidanci_resume');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('学习中中断 → 快照落库 → 恢复后队列一致并完成', () async {
    final db = openTestDb(tempDir, 'resume');
    addTearDown(db.close);
    await seedWordbook(db, wordCount: 3);

    final words = DriftWordbookRepository(db);
    final userWords = DriftUserWordRepository(db);
    final reviewLogs = DriftReviewLogRepository(db);
    final sessions = DriftSessionRepository(db);
    final stats = DriftStatsRepository(db);
    final scheduler = FsrsEngine();

    SessionDriver newDriver() => SessionDriver(
      stateMachine: DefaultSessionStateMachine(),
      scheduler: scheduler,
      userWords: userWords,
      reviewLogs: reviewLogs,
      sessions: sessions,
      stats: stats,
    );

    final bookId = 1;
    final newWords = await words.getWordsByBook(bookId, limit: 3);
    final driver = newDriver();
    driver.startNewSession(
      sessionId: 'learn-resume',
      type: SessionType.learning,
      wordbookId: bookId,
      wordIds: [for (final w in newWords) w.id],
    );

    expect(driver.fetchCard(), 1);
    await driver.rate(Rating.good); // 已消费 1
    expect(driver.fetchCard(), 2);
    await driver.interrupt(); // 中断：快照落库
    expect(driver.phase, SessionPhase.paused);

    // 快照：position=1、剩余队列 [2,3]；loadAll 可枚举。
    final all = await sessions.loadAll();
    expect(all, hasLength(1));
    final snap = all.single;
    expect(snap.position, 1);
    expect(snap.items.map((e) => e.wordId).toList(), [2, 3]);

    // 跨实例恢复（模拟 App 重启后重新进入）：
    final resumed = newDriver();
    resumed.resumeSession(snap, wordbookId: bookId);
    expect(resumed.fetchCard(), 2); // 队列一致：下一张仍是 2
    await resumed.rate(Rating.good);
    expect(resumed.fetchCard(), 3);
    await resumed.rate(Rating.good);
    await resumed.finish();

    // 完成统计按已消费卡数累加；快照已清理。
    final statsRow = await stats.getByDay(TimeUtils.localDayKey(DateTime.now()));
    expect(statsRow!.newCount, 3);
    expect(await sessions.loadAll(), isEmpty);
    expect(await sessions.load('learn-resume'), isNull);
  });
}
