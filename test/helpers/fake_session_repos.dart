/// 会话测试共享内存仓储与确定性调度器：session_driver_test 与会话页 widget
/// 测试（session_flow_lifecycle_test）共用，避免两处重复实现（AGENTS §7
/// 测试结构纪律）。实现 domain 仓储接口，可注入失败次数与异步钩子。
library;

import 'package:happy_bei_dan_ci/domain/models/daily_stats.dart';
import 'package:happy_bei_dan_ci/domain/models/review_log.dart';
import 'package:happy_bei_dan_ci/domain/models/user_word.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs_scheduler.dart';
import 'package:happy_bei_dan_ci/domain/services/review_log_repository.dart';
import 'package:happy_bei_dan_ci/domain/services/session_repository.dart';
import 'package:happy_bei_dan_ci/domain/services/stats_repository.dart';
import 'package:happy_bei_dan_ci/domain/services/user_word_repository.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_snapshot.dart';

/// 内存版用户词仓储：记录调用、可注入失败次数（重试口径测试用）与
/// [onUpsert] 异步钩子（模拟慢写库，供"评分与中断并发"类用例控制时序）。
class FakeUserWordRepository implements UserWordRepository {
  final Map<(int, int, int), UserWord> rows = {};
  int upsertCalls = 0;
  int failNextUpserts = 0;

  /// upsert 开始时等待的钩子；非空时先 await 再继续（模拟慢写库）。
  Future<void> Function()? onUpsert;

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
    final hook = onUpsert;
    if (hook != null) {
      await hook();
    }
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
class FakeReviewLogRepository implements ReviewLogRepository {
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
class FakeSessionRepository implements SessionRepository {
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
class FakeStatsRepository implements StatsRepository {
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
class FakeScheduler implements FsrsScheduler {
  FakeScheduler({required this.intervalDays});

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
