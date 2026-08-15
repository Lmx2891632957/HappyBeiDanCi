/// 会话驱动单测：事件→FSRS→落库串联、中断/恢复、完成统计、写库失败口径
///（TECH_DOC §5.4 驱动契约，AGENTS §7；状态机与 FSRS 行为以既有单测为准，
/// 此处用 fake 仓储与确定性假调度器验证驱动的编排）。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/domain/models/daily_stats.dart';
import 'package:happy_bei_dan_ci/domain/models/review_log.dart';
import 'package:happy_bei_dan_ci/domain/models/user_word.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs_scheduler.dart';
import 'package:happy_bei_dan_ci/domain/services/review_log_repository.dart';
import 'package:happy_bei_dan_ci/domain/services/session_repository.dart';
import 'package:happy_bei_dan_ci/domain/services/stats_repository.dart';
import 'package:happy_bei_dan_ci/domain/services/user_word_repository.dart';
import 'package:happy_bei_dan_ci/domain/sessions/default_session_state_machine.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_driver.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_snapshot.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_state_machine.dart';

void main() {
  group('评分落库与队列推进', () {
    test('新会话：fetch→rate(Good)→FSRS 调度并落库→队列推进', () async {
      final h = _buildHarness();
      h.driver.startNewSession(
        sessionId: 's1',
        type: SessionType.learning,
        wordbookId: 7,
        wordIds: const [1, 2],
      );
      expect(h.driver.phase, SessionPhase.fetching);
      expect(h.driver.currentWordId, isNull);

      expect(h.driver.fetchCard(), 1);
      final result = await h.driver.rate(Rating.good);
      expect(result.requeued, isFalse);
      expect(result.persistFailures, 0);
      expect(h.driver.phase, SessionPhase.fetching);
      expect(h.driver.position, 1);

      // 调度输入：新词（无 user_words 记录）+ 评分。
      expect(h.scheduler.cardInputs.single.state, WordLearningState.new_);
      expect(h.scheduler.ratingInputs.single, Rating.good);

      // user_words：新词 Good → review，镜像字段按调度结果写入。
      final word = h.userWords.rows[(0, 7, 1)]!;
      expect(word.state, WordLearningState.review);
      expect(word.status, WordStatus.review);
      expect(word.lastRating, 3);
      expect(word.lastReviewAt, isNotNull);
      expect(word.scheduledDays, 1);

      // review_logs：一条、含会话上下文。
      final log = h.reviewLogs.logs.single;
      expect(log.wordId, 1);
      expect(log.rating, Rating.good);
      expect(log.sessionId, 's1');
      expect(log.sessionType, SessionType.learning);
      expect(log.reviewedAt, h.fixedNow);
    });

    test('Again 重排：requeued=true，重排卡本次会话再见一次，完成计入已消费数', () async {
      final h = _buildHarness();
      h.driver.startNewSession(
        sessionId: 's',
        type: SessionType.learning,
        wordbookId: 1,
        wordIds: const [1, 2],
      );
      expect(h.driver.fetchCard(), 1);

      final r1 = await h.driver.rate(Rating.again);
      expect(r1.requeued, isTrue);
      expect(h.driver.phase, SessionPhase.requeue);

      expect(h.driver.fetchCard(), 2);
      await h.driver.rate(Rating.good);
      expect(h.driver.fetchCard(), 1); // 重排卡回到队尾后再次展示
      await h.driver.rate(Rating.good);
      await h.driver.finish();

      // Again 重排消费 1 次 + 两次 Good，共消费 3 次（position=已消费卡数）。
      expect(h.stats.byDay['2026-08-12']!.newCount, 3);
      expect(h.stats.byDay['2026-08-12']!.reviewCount, 0);
    });

    test('未取卡直接评分：状态机拒绝（CardRated 仅限 Showing）', () async {
      final h = _buildHarness();
      h.driver.startNewSession(
        sessionId: 's',
        type: SessionType.learning,
        wordbookId: 1,
        wordIds: const [1],
      );
      await expectLater(h.driver.rate(Rating.good), throwsStateError);
      expect(h.userWords.rows, isEmpty);
      expect(h.reviewLogs.logs, isEmpty);
    });
  });

  group('中断与恢复（AGENTS §6.2 续学验证）', () {
    test('中断→快照保存→跨实例恢复：队列与 position 一致，恢复后可继续作答', () async {
      final h = _buildHarness();
      h.driver.startNewSession(
        sessionId: 's1',
        type: SessionType.review,
        wordbookId: 3,
        wordIds: const [1, 2, 3],
      );
      for (final wordId in [1, 2, 3]) {
        _seedReviewWord(userWords: h.userWords, wordbookId: 3, wordId: wordId);
      }

      h.driver.fetchCard();
      await h.driver.rate(Rating.good); // 已消费 1
      h.driver.fetchCard(); // 展示 2
      await h.driver.interrupt();

      expect(h.driver.phase, SessionPhase.paused);
      expect(h.sessions.savedIds, ['s1']);
      final snap = h.sessions.snapshots['s1']!;
      expect(snap.position, 1);
      expect(snap.items.map((e) => e.wordId).toList(), [2, 3]);

      // 跨实例恢复：wordbookId 由调用方提供（TD-07 快照不含词书信息）。
      final h2 = _buildHarness();
      h2.driver.resumeSession(snap, wordbookId: 3);
      expect(h2.driver.phase, SessionPhase.fetching);
      expect(h2.driver.fetchCard(), 2);
      await h2.driver.rate(Rating.good);
      expect(h2.userWords.rows[(0, 3, 2)]!.reps, 1);
      expect(h2.userWords.rows[(0, 3, 2)]!.wordbookId, 3);
    });

    test('恢复时无快照：抛 ArgumentError，不静默继续', () {
      final h = _buildHarness();
      expect(
        () => h.driver.resumeSession(null, wordbookId: 1),
        throwsArgumentError,
      );
    });

    test('interrupt 快照保存失败：向上抛出，不静默吞掉；可重试保存', () async {
      final h = _buildHarness();
      h.driver.startNewSession(
        sessionId: 's',
        type: SessionType.learning,
        wordbookId: 1,
        wordIds: const [1],
      );
      h.driver.fetchCard();
      h.sessions.failNextSaves = 1;

      await expectLater(h.driver.interrupt(), throwsException);
      expect(h.driver.phase, SessionPhase.paused); // 状态机已暂停
      expect(h.sessions.snapshots, isEmpty); // 但未持久化

      await h.driver.interrupt(); // 已 Paused：幂等重存快照
      expect(h.sessions.snapshots['s'], isNotNull);
    });
  });

  group('完成：删快照 + daily_stats', () {
    test('finish：删除快照，review 会话累加 review_count 与 correct_count', () async {
      final h = _buildHarness();
      h.driver.startNewSession(
        sessionId: 's',
        type: SessionType.review,
        wordbookId: 2,
        wordIds: const [1, 2],
      );
      _seedReviewWord(userWords: h.userWords, wordbookId: 2, wordId: 1);
      _seedReviewWord(userWords: h.userWords, wordbookId: 2, wordId: 2);

      h.driver.fetchCard();
      await h.driver.rate(Rating.again); // 不算正确
      h.driver.fetchCard();
      await h.driver.rate(Rating.good); // 算正确
      expect(h.driver.fetchCard(), 1); // Again 重排卡本次会话再次出现
      await h.driver.rate(Rating.good); // 算正确
      await h.driver.finish();

      expect(h.sessions.deletedIds, ['s']);
      expect(h.sessions.snapshots, isEmpty);
      final stats = h.stats.byDay['2026-08-12']!;
      expect(stats.newCount, 0);
      expect(stats.reviewCount, 3);
      expect(stats.correctCount, 2);
      expect(stats.completed, 0); // 打卡标记由任务完成页写，驱动不置位
    });

    test('daily_stats 合并：同日先学习后复习，计数累加不覆盖', () async {
      // 状态机单次会话（Done 后不可复用），同日两会话用两个驱动实例、
      // 共享同一 stats 仓储验证合并口径。
      final stats = _FakeStatsRepository();
      final h1 = _buildHarness(sharedStats: stats);
      // 学习会话 2 词。
      h1.driver.startNewSession(
        sessionId: 'learn',
        type: SessionType.learning,
        wordbookId: 1,
        wordIds: const [1, 2],
      );
      h1.driver.fetchCard();
      await h1.driver.rate(Rating.good);
      h1.driver.fetchCard();
      await h1.driver.rate(Rating.good);
      await h1.driver.finish();

      // 复习会话 2 词（预置 review 状态）。
      final h2 = _buildHarness(sharedStats: stats);
      h2.driver.startNewSession(
        sessionId: 'review',
        type: SessionType.review,
        wordbookId: 2,
        wordIds: const [3, 4],
      );
      _seedReviewWord(userWords: h2.userWords, wordbookId: 2, wordId: 3);
      _seedReviewWord(userWords: h2.userWords, wordbookId: 2, wordId: 4);
      h2.driver.fetchCard();
      await h2.driver.rate(Rating.again);
      h2.driver.fetchCard();
      await h2.driver.rate(Rating.good);
      expect(h2.driver.fetchCard(), 3); // Again 重排卡再次出现
      await h2.driver.rate(Rating.good);
      await h2.driver.finish();

      final merged = stats.byDay['2026-08-12']!;
      expect(merged.newCount, 2);
      expect(merged.reviewCount, 3);
      expect(merged.correctCount, 2);
      expect(stats.upserted, hasLength(2)); // 第二次是合并后的整行
    });

    test('finish 在队列非空时抛 StateError，且不删快照/不写统计', () async {
      final h = _buildHarness();
      h.driver.startNewSession(
        sessionId: 's',
        type: SessionType.learning,
        wordbookId: 1,
        wordIds: const [1, 2],
      );
      h.driver.fetchCard();

      await expectLater(h.driver.finish(), throwsStateError);
      expect(h.sessions.deletedIds, isEmpty);
      expect(h.stats.upserted, isEmpty);
    });

    test('空队列会话：可直接 finish，统计 new_count 为 0', () async {
      final h = _buildHarness();
      h.driver.startNewSession(
        sessionId: 's',
        type: SessionType.learning,
        wordbookId: 1,
        wordIds: const [],
      );
      await h.driver.finish();
      expect(h.sessions.deletedIds, ['s']);
      expect(h.stats.byDay['2026-08-12']!.newCount, 0);
    });

    test('finish 删除快照失败：向上抛出且可幂等重试，统计不重复计数', () async {
      final h = _buildHarness();
      h.driver.startNewSession(
        sessionId: 's',
        type: SessionType.learning,
        wordbookId: 1,
        wordIds: const [1],
      );
      h.driver.fetchCard();
      await h.driver.rate(Rating.good);
      h.sessions.failNextDeletes = 1;

      await expectLater(h.driver.finish(), throwsException);
      expect(h.stats.upserted, isEmpty); // 删除失败时未写统计

      await h.driver.finish(); // 重试成功
      expect(h.sessions.deletedIds, ['s', 's']);
      expect(h.stats.byDay['2026-08-12']!.newCount, 1);
      expect(h.stats.upserted, hasLength(1)); // 未重复计数

      await expectLater(h.driver.finish(), throwsStateError); // 会话已结束
    });
  });

  group('写库失败口径（TECH_DOC §5.2/§5.4）', () {
    test('user_words 重试后仍失败：记录日志并继续推进队列', () async {
      final h = _buildHarness();
      h.driver.startNewSession(
        sessionId: 's',
        type: SessionType.learning,
        wordbookId: 1,
        wordIds: const [1, 2],
      );
      h.driver.fetchCard();
      h.userWords.failNextUpserts = 2; // 首次 + 重试均失败

      final result = await h.driver.rate(Rating.good);
      expect(result.persistFailures, 1);
      expect(result.requeued, isFalse);
      expect(h.driver.phase, SessionPhase.fetching); // 队列继续推进
      expect(h.driver.position, 1);
      expect(h.userWords.upsertCalls, 2); // 确已重试一次
      expect(h.userWords.rows, isEmpty);
      expect(h.logMessages, hasLength(1));
      expect(h.logMessages.single, contains('user_words.upsert'));

      expect(h.driver.fetchCard(), 2); // 下一张卡仍可作答
      await h.driver.rate(Rating.good);
      expect(h.userWords.rows[(0, 1, 2)], isNotNull);
    });

    test('写库失败一次后重试成功：persistFailures=0 且落库成功', () async {
      final h = _buildHarness();
      h.driver.startNewSession(
        sessionId: 's',
        type: SessionType.learning,
        wordbookId: 1,
        wordIds: const [1],
      );
      h.driver.fetchCard();
      h.userWords.failNextUpserts = 1;

      final result = await h.driver.rate(Rating.good);
      expect(result.persistFailures, 0);
      expect(h.userWords.upsertCalls, 2);
      expect(h.userWords.rows[(0, 1, 1)], isNotNull);
      expect(h.logMessages, isEmpty);
    });

    test('review_logs 重试后仍失败：user_words 已更新（部分持久化），队列仍推进', () async {
      final h = _buildHarness();
      h.driver.startNewSession(
        sessionId: 's',
        type: SessionType.learning,
        wordbookId: 1,
        wordIds: const [1, 2],
      );
      h.driver.fetchCard();
      h.reviewLogs.failNextAdds = 2;

      final result = await h.driver.rate(Rating.good);
      expect(result.persistFailures, 1);
      expect(h.userWords.rows[(0, 1, 1)], isNotNull); // 有状态无日志
      expect(h.reviewLogs.logs, isEmpty);
      expect(h.driver.phase, SessionPhase.fetching);
      expect(h.logMessages.single, contains('review_logs.add'));
    });
  });

  group('status 派生（TECH_DOC §5.4 字段口径）', () {
    test('review 且 scheduled_days≥21 → mature；<21 → review', () async {
      final mature = _buildHarness(intervalDays: 21);
      mature.driver.startNewSession(
        sessionId: 'm',
        type: SessionType.learning,
        wordbookId: 1,
        wordIds: const [1],
      );
      mature.driver.fetchCard();
      await mature.driver.rate(Rating.good);
      expect(mature.userWords.rows[(0, 1, 1)]!.status, WordStatus.mature);

      final normal = _buildHarness(intervalDays: 1);
      normal.driver.startNewSession(
        sessionId: 'n',
        type: SessionType.learning,
        wordbookId: 1,
        wordIds: const [1],
      );
      normal.driver.fetchCard();
      await normal.driver.rate(Rating.good);
      expect(normal.userWords.rows[(0, 1, 1)]!.status, WordStatus.review);
    });

    test('learning/relearning → learning 状态', () async {
      final h = _buildHarness();
      h.driver.startNewSession(
        sessionId: 's',
        type: SessionType.learning,
        wordbookId: 1,
        wordIds: const [1],
      );
      h.driver.fetchCard();
      await h.driver.rate(Rating.again); // fake 调度器保持 learning
      expect(h.userWords.rows[(0, 1, 1)]!.state, WordLearningState.learning);
      expect(h.userWords.rows[(0, 1, 1)]!.status, WordStatus.learning);
    });
  });
}

/// 测试装配：真实状态机 + 确定性假调度器 + 内存假仓储。
({
  SessionDriver driver,
  _FakeUserWordRepository userWords,
  _FakeReviewLogRepository reviewLogs,
  _FakeSessionRepository sessions,
  _FakeStatsRepository stats,
  _FakeScheduler scheduler,
  List<String> logMessages,
  DateTime fixedNow,
})
_buildHarness({double intervalDays = 1, _FakeStatsRepository? sharedStats}) {
  final fixedNow = DateTime(2026, 8, 12, 10, 30);
  final userWords = _FakeUserWordRepository();
  final reviewLogs = _FakeReviewLogRepository();
  final sessions = _FakeSessionRepository();
  final stats = sharedStats ?? _FakeStatsRepository();
  final scheduler = _FakeScheduler(intervalDays: intervalDays);
  final logMessages = <String>[];
  final driver = SessionDriver(
    stateMachine: DefaultSessionStateMachine(),
    scheduler: scheduler,
    userWords: userWords,
    reviewLogs: reviewLogs,
    sessions: sessions,
    stats: stats,
    now: () => fixedNow,
    logger: (message, [error]) =>
        logMessages.add('$message${error == null ? '' : ' :: $error'}'),
  );
  return (
    driver: driver,
    userWords: userWords,
    reviewLogs: reviewLogs,
    sessions: sessions,
    stats: stats,
    scheduler: scheduler,
    logMessages: logMessages,
    fixedNow: fixedNow,
  );
}

/// 预置 review 会话所需的用户词状态（复习词已有一行 user_words）。
void _seedReviewWord({
  required _FakeUserWordRepository userWords,
  required int wordbookId,
  required int wordId,
}) {
  userWords.rows[(0, wordbookId, wordId)] = UserWord(
    userId: 0,
    wordbookId: wordbookId,
    wordId: wordId,
    state: WordLearningState.review,
    status: WordStatus.review,
    dueDate: DateTime(2026, 8, 12),
    stability: 3,
    difficulty: 4,
    reps: 2,
    lapses: 0,
    lastReviewAt: DateTime(2026, 8, 1),
  );
}

/// 内存版用户词仓储：记录调用并可注入失败次数（重试口径测试用）。
class _FakeUserWordRepository implements UserWordRepository {
  final Map<(int, int, int), UserWord> rows = {};
  int upsertCalls = 0;
  int failNextUpserts = 0;

  @override
  Future<List<UserWord>> getDueWords({
    required DateTime todayEnd,
    int? limit,
  }) async => throw UnimplementedError('本测试不使用');

  @override
  Future<UserWord?> getWord({
    required int userId,
    required int wordbookId,
    required int wordId,
  }) async => rows[(userId, wordbookId, wordId)];

  @override
  Future<void> upsert(UserWord word) async {
    upsertCalls++;
    if (failNextUpserts > 0) {
      failNextUpserts--;
      throw Exception('simulated upsert failure');
    }
    rows[(word.userId, word.wordbookId, word.wordId)] = word;
  }

  @override
  Future<List<UserWord>> getAll() async =>
      throw UnimplementedError('本测试不使用');
}

/// 内存版复习日志仓储。
class _FakeReviewLogRepository implements ReviewLogRepository {
  final List<ReviewLog> logs = [];
  int addCalls = 0;
  int failNextAdds = 0;

  @override
  Future<void> add(ReviewLog log) async {
    addCalls++;
    if (failNextAdds > 0) {
      failNextAdds--;
      throw Exception('simulated add failure');
    }
    logs.add(log);
  }

  @override
  Future<List<ReviewLog>> getLogs({DateTime? from, DateTime? to}) async =>
      throw UnimplementedError('本测试不使用');
}

/// 内存版会话快照仓储。
class _FakeSessionRepository implements SessionRepository {
  final Map<String, SessionSnapshot> snapshots = {};
  final List<String> savedIds = [];
  final List<String> deletedIds = [];
  int failNextSaves = 0;
  int failNextDeletes = 0;

  @override
  Future<void> save(SessionSnapshot snapshot) async {
    savedIds.add(snapshot.sessionId);
    if (failNextSaves > 0) {
      failNextSaves--;
      throw Exception('simulated save failure');
    }
    snapshots[snapshot.sessionId] = snapshot;
  }

  @override
  Future<SessionSnapshot?> load(String sessionId) async => snapshots[sessionId];

  @override
  Future<List<SessionSnapshot>> loadAll() async => snapshots.values.toList();

  @override
  Future<void> delete(String sessionId) async {
    deletedIds.add(sessionId);
    if (failNextDeletes > 0) {
      failNextDeletes--;
      throw Exception('simulated delete failure');
    }
    snapshots.remove(sessionId);
  }
}

/// 内存版每日统计仓储。
class _FakeStatsRepository implements StatsRepository {
  final Map<String, DailyStats> byDay = {};
  final List<DailyStats> upserted = [];

  @override
  Future<DailyStats?> getByDay(String day) async => byDay[day];

  @override
  Future<void> upsert(DailyStats stats) async {
    byDay[stats.day] = stats;
    upserted.add(stats);
  }
}

/// 确定性假调度器：Again 停留在学习/重学，其余毕业为 Review；
/// 固定间隔 [intervalDays]，便于断言驱动写入 user_words/review_logs 的字段。
class _FakeScheduler implements FsrsScheduler {
  _FakeScheduler({required this.intervalDays});

  final double intervalDays;
  final List<CardState> cardInputs = [];
  final List<Rating> ratingInputs = [];

  @override
  FsrsParameters get parameters => const FsrsParameters();

  @override
  SchedulingState next(CardState card, Rating rating, {required DateTime now}) {
    cardInputs.add(card);
    ratingInputs.add(rating);
    final state = switch ((card.state, rating)) {
      (WordLearningState.review, Rating.again) => WordLearningState.relearning,
      (WordLearningState.relearning, Rating.again) =>
        WordLearningState.relearning,
      (_, Rating.again) => WordLearningState.learning,
      _ => WordLearningState.review,
    };
    return SchedulingState(
      card: CardState(
        state: state,
        stability: card.stability + 1,
        difficulty: card.difficulty + 0.5,
        dueDate: now.add(
          Duration(
            days: intervalDays.round(),
            minutes: rating == Rating.again ? 10 : 0,
          ),
        ),
        reps: card.reps + 1,
        lapses:
            card.lapses +
            (card.state == WordLearningState.review && rating == Rating.again
                ? 1
                : 0),
        lastReviewAt: now,
        elapsedDays: card.elapsedDaysAt(now)?.toDouble(),
        scheduledDays: intervalDays,
      ),
      intervalDays: intervalDays,
      retrievability: 0.9,
    );
  }
}
