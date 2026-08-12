/// 每日核心闭环集成测试（驱动 + 真实 Drift 仓储，TECH_DOC §14.2 TD-07 口径）：
/// 学习 3 词（含答错重排）→ 复习（含重排）→ 完成页打卡判定与置位。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/core/time_utils.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_review_log_repository.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_session_repository.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_settings_repository.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_stats_repository.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_user_word_repository.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_wordbook_repository.dart';
import 'package:happy_bei_dan_ci/domain/models/daily_stats.dart';
import 'package:happy_bei_dan_ci/domain/models/user_word.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs/fsrs_engine.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs_scheduler.dart';
import 'package:happy_bei_dan_ci/domain/services/default_daily_plan_calculator.dart';
import 'package:happy_bei_dan_ci/domain/services/daily_checkin_calculator.dart';
import 'package:happy_bei_dan_ci/domain/sessions/default_session_state_machine.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_driver.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_snapshot.dart';

import '../helpers/fixture.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('happy_beidanci_loop_repo');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('全流程：学习（含重排）→ 复习（含重排）→ 打卡置位', () async {
    final db = openTestDb(tempDir, 'loop');
    addTearDown(db.close);
    await seedWordbook(db, wordCount: 3);

    final words = DriftWordbookRepository(db);
    final settings = DriftSettingsRepository(db);
    final userWords = DriftUserWordRepository(db);
    final reviewLogs = DriftReviewLogRepository(db);
    final sessions = DriftSessionRepository(db);
    final stats = DriftStatsRepository(db);
    final scheduler = FsrsEngine();
    const calculator = DefaultDailyPlanCalculator();

    SessionDriver newDriver({required int wordbookId}) => SessionDriver(
      stateMachine: DefaultSessionStateMachine(),
      scheduler: scheduler,
      userWords: userWords,
      reviewLogs: reviewLogs,
      sessions: sessions,
      stats: stats,
    );

    // --- 学习会话：3 词，第一张答错（Again）触发重排 ---
    final appSettings = await settings.load();
    final book = (await words.getWordbooks()).single;
    final now = DateTime.now();
    final todayStart = TimeUtils.todayStart(now, timezone: appSettings.timezone);
    final todayEnd = TimeUtils.todayEnd(now, timezone: appSettings.timezone);
    final remaining = await words.countRemainingNewWords(book.id);
    final dueBeforeLearn = await userWords.getDueWords(todayEnd: todayEnd);
    final learnPlan = calculator.calculate(
      dailyGoal: appSettings.dailyNewWords,
      remainingNewWords: remaining,
      dueWords: dueBeforeLearn.where((w) => w.wordbookId == book.id).toList(),
      cap: appSettings.reviewCap,
      todayStart: todayStart,
    );
    expect(learnPlan.newWordCount, 3);

    final newWords = await words.getWordsByBook(
      book.id,
      limit: learnPlan.newWordCount,
    );
    final learnDriver = newDriver(wordbookId: book.id);
    learnDriver.startNewSession(
      sessionId: 'learn-1',
      type: SessionType.learning,
      wordbookId: book.id,
      wordIds: [for (final w in newWords) w.id],
    );

    expect(learnDriver.fetchCard(), newWords[0].id);
    final again = await learnDriver.rate(Rating.again);
    expect(again.requeued, isTrue); // 答错重排：本次会话内再次出现
    expect(learnDriver.fetchCard(), newWords[1].id);
    await learnDriver.rate(Rating.good);
    expect(learnDriver.fetchCard(), newWords[2].id);
    await learnDriver.rate(Rating.good);
    expect(learnDriver.fetchCard(), newWords[0].id); // 重排卡回到队尾后再次出现
    await learnDriver.rate(Rating.good);
    await learnDriver.finish();

    // --- 复习会话：预置 2 个到期复习词 ---
    for (final (wordId, daysOverdue) in [(1, 2), (2, 1)]) {
      await userWords.upsert(
        UserWord(
          wordbookId: book.id,
          wordId: wordId,
          state: WordLearningState.review,
          status: WordStatus.review,
          dueDate: now.subtract(Duration(days: daysOverdue)),
          stability: 3,
          difficulty: 4,
          reps: 2,
          lastReviewAt: now.subtract(Duration(days: daysOverdue + 10)),
        ),
      );
    }
    final dueAfterLearn = await userWords.getDueWords(todayEnd: todayEnd);
    final reviewPlan = calculator.calculate(
      dailyGoal: appSettings.dailyNewWords,
      remainingNewWords: await words.countRemainingNewWords(book.id),
      dueWords: dueAfterLearn.where((w) => w.wordbookId == book.id).toList(),
      cap: appSettings.reviewCap,
      todayStart: todayStart,
    );
    expect(reviewPlan.reviewCount, 2);

    final reviewDriver = newDriver(wordbookId: book.id);
    reviewDriver.startNewSession(
      sessionId: 'review-1',
      type: SessionType.review,
      wordbookId: book.id,
      wordIds: [for (final w in reviewPlan.reviewQueue) w.wordId],
    );
    expect(reviewDriver.fetchCard(), 1);
    final againReview = await reviewDriver.rate(Rating.again);
    expect(againReview.requeued, isTrue);
    expect(reviewDriver.fetchCard(), 2);
    await reviewDriver.rate(Rating.good);
    expect(reviewDriver.fetchCard(), 1); // 答错重排卡再次出现
    await reviewDriver.rate(Rating.good);
    await reviewDriver.finish();

    // --- daily_stats 合并与打卡判定 ---
    final day = TimeUtils.localDayKey(now);
    final merged = await stats.getByDay(day);
    expect(merged, isNotNull);
    // 按驱动"已消费卡数"口径（§5.4）：学习 3 词中 1 次 Again 重排 → 4 次消费；
    // 复习 2 词中 1 次 Again 重排 → 3 次消费；正确数 = rating ≥ 3 的次数
    //（§6.4 仅复习会话累加：复习 2 次）。
    expect(merged!.newCount, 4);
    expect(merged.reviewCount, 3);
    expect(merged.correctCount, 2);
    expect(merged.completed, 0); // 驱动不置位打卡

    // 完成页口径：重算计划后判定整日完成并置位。
    final finalRemaining = await words.countRemainingNewWords(book.id);
    final dueFinal = await userWords.getDueWords(todayEnd: todayEnd);
    final finalPlan = calculator.calculate(
      dailyGoal: appSettings.dailyNewWords,
      remainingNewWords: finalRemaining,
      dueWords: dueFinal.where((w) => w.wordbookId == book.id).toList(),
      cap: appSettings.reviewCap,
      todayStart: todayStart,
    );
    expect(
      DailyCheckinCalculator.isTodayComplete(plan: finalPlan, stats: merged),
      isTrue,
    );
    await stats.upsert(DailyStats(day: day, completed: 1));
    expect((await stats.getByDay(day))!.completed, 1);

    // 快照均已清理；评分日志累计 7 条（学习 4 次消费 + 复习 3 次消费）。
    expect(await sessions.loadAll(), isEmpty);
    expect((await reviewLogs.getLogs()).length, 7);
  });
}
