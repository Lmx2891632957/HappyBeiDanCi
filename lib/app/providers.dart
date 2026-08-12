import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logger.dart';
import '../core/time_utils.dart';
import '../data/local/app_database.dart';
import '../data/repositories/drift_review_log_repository.dart';
import '../data/repositories/drift_session_repository.dart';
import '../data/repositories/drift_settings_repository.dart';
import '../data/repositories/drift_stats_repository.dart';
import '../data/repositories/drift_user_word_repository.dart';
import '../data/repositories/drift_wordbook_repository.dart';
import '../domain/models/app_settings.dart';
import '../domain/models/daily_plan.dart';
import '../domain/models/wordbook.dart';
import '../domain/scheduling/fsrs/fsrs_engine.dart';
import '../domain/scheduling/fsrs_scheduler.dart';
import '../domain/services/daily_plan_calculator.dart';
import '../domain/services/default_daily_plan_calculator.dart';
import '../domain/services/review_log_repository.dart';
import '../domain/services/session_repository.dart';
import '../domain/services/settings_repository.dart';
import '../domain/services/stats_repository.dart';
import '../domain/services/user_word_repository.dart';
import '../domain/services/wordbook_repository.dart';
import '../domain/sessions/default_session_state_machine.dart';
import '../domain/sessions/session_driver.dart';
import '../domain/sessions/session_snapshot.dart';

/// 数据库实例：Provider 惰性求值，应用启动时首页先渲染骨架、
/// 不等待磁盘 IO（TECH_DOC §12 启动到首卡 < 2s）。
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

/// 各仓储（UI 不直接读写数据库，AGENTS §3.2：一律经本层注入的仓储接口访问）。
final wordbookRepositoryProvider = Provider<WordbookRepository>(
  (ref) => DriftWordbookRepository(ref.watch(databaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => DriftSettingsRepository(ref.watch(databaseProvider)),
);

final userWordRepositoryProvider = Provider<UserWordRepository>(
  (ref) => DriftUserWordRepository(ref.watch(databaseProvider)),
);

final reviewLogRepositoryProvider = Provider<ReviewLogRepository>(
  (ref) => DriftReviewLogRepository(ref.watch(databaseProvider)),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => DriftSessionRepository(ref.watch(databaseProvider)),
);

final statsRepositoryProvider = Provider<StatsRepository>(
  (ref) => DriftStatsRepository(ref.watch(databaseProvider)),
);

/// FSRS-5 调度器（TD-05 默认参数：DR=0.9、learning_steps=[10m]、fuzz 关闭）。
final fsrsSchedulerProvider = Provider<FsrsScheduler>((ref) => FsrsEngine());

/// 每日计划计算器（纯逻辑，TECH_DOC §6.1）。
final dailyPlanCalculatorProvider = Provider<DailyPlanCalculator>(
  (ref) => const DefaultDailyPlanCalculator(),
);

/// SessionDriver：一场会话一实例（TECH_DOC §5.4 驱动契约）。
///
/// `autoDispose`：会话页退出后实例随 Provider 释放，下次进入重建——
/// 状态机进入 Done 后不可再次 `SessionStarted`，因此不能跨场会话复用。
final sessionDriverProvider = Provider.autoDispose<SessionDriver>((ref) {
  return SessionDriver(
    stateMachine: DefaultSessionStateMachine(),
    scheduler: ref.watch(fsrsSchedulerProvider),
    userWords: ref.watch(userWordRepositoryProvider),
    reviewLogs: ref.watch(reviewLogRepositoryProvider),
    sessions: ref.watch(sessionRepositoryProvider),
    stats: ref.watch(statsRepositoryProvider),
    logger: AppLogger.error,
  );
});

/// 今日计划结果展示模型（TECH_DOC §5.1 今日页数据流）：聚合设置、默认词书、
/// 剩余新词与到期词后由 `DefaultDailyPlanCalculator` 计算得出；仅用于展示与
/// 构建会话入口，不落库。今日任务页与完成页共用（今日页计算、完成页重算）。
class TodayPlan {
  const TodayPlan({
    required this.settings,
    required this.wordbook,
    required this.plan,
    required this.remainingNewWords,
  });

  final AppSettings settings;

  /// 默认词书（getWordbooks 排序后第一个）；null 表示词库包未安装。
  final Wordbook? wordbook;

  /// 今日计划（新词数、排序截断后的复习队列、顺延数）。
  final DailyPlan plan;

  /// 词书剩余新词数（供完成页"明日预告"估算）。
  final int remainingNewWords;
}

/// 今日计划（TECH_DOC §5.1/§6.1 数据流）：
/// 设置 → 默认词书 → 剩余新词 + 到期词（当前词书）→ 每日计划计算器。
///
/// M1 单词书假设：到期词按当前默认词书过滤在调用方完成（多词书支持需扩展
/// `UserWordRepository.getDueWords` 按词书过滤，TECH_DOC §5.1）。
final todayPlanProvider = FutureProvider.autoDispose<TodayPlan>((ref) async {
  final settings = await ref.watch(settingsRepositoryProvider).load();
  final wordbookRepository = ref.watch(wordbookRepositoryProvider);
  final wordbooks = await wordbookRepository.getWordbooks();
  if (wordbooks.isEmpty) {
    return TodayPlan(
      settings: settings,
      wordbook: null,
      plan: const DailyPlan(
        newWordCount: 0,
        reviewQueue: [],
        deferredCount: 0,
      ),
      remainingNewWords: 0,
    );
  }

  final book = wordbooks.first; // sortOrder 升序第一个 = 默认词书。
  final remainingNew = await wordbookRepository.countRemainingNewWords(book.id);
  final now = DateTime.now();
  final todayStart = TimeUtils.todayStart(now, timezone: settings.timezone);
  final todayEnd = TimeUtils.todayEnd(now, timezone: settings.timezone);
  final dueWords = await ref.watch(userWordRepositoryProvider).getDueWords(
    todayEnd: todayEnd,
  );
  final dueForBook = dueWords.where((w) => w.wordbookId == book.id).toList();
  final plan = ref.watch(dailyPlanCalculatorProvider).calculate(
    dailyGoal: settings.dailyNewWords,
    remainingNewWords: remainingNew,
    dueWords: dueForBook,
    cap: settings.reviewCap,
    todayStart: todayStart,
  );
  return TodayPlan(
    settings: settings,
    wordbook: book,
    plan: plan,
    remainingNewWords: remainingNew,
  );
});

/// 未完成会话快照（TECH_DOC §5.1 第 4 点）：loadAll 按 updated_at 降序，
/// 今日页取最近一个展示"继续上次未完成的学习"入口；会话页中断/完成后会
/// `invalidate` 本 provider，保证返回今日页时快照列表是最新的。
final unfinishedSessionsProvider = FutureProvider.autoDispose<
  List<SessionSnapshot>
>((ref) => ref.watch(sessionRepositoryProvider).loadAll());
