import '../models/daily_stats.dart';
import '../models/review_log.dart';
import '../models/user_word.dart';
import '../scheduling/fsrs_scheduler.dart';
import '../services/review_log_repository.dart';
import '../services/session_repository.dart';
import '../services/stats_repository.dart';
import '../services/user_word_repository.dart';
import 'session_snapshot.dart';
import 'session_state_machine.dart';

/// 会话驱动：串联状态机事件、FSRS 调度与落库（TECH_DOC §5.4 驱动契约）。
///
/// 纯逻辑：注入 [SessionStateMachine] + [FsrsScheduler] + 四个仓储接口，
/// 不依赖 data/Flutter（AGENTS §3.2）。驱动不修改状态机与 FSRS 引擎行为，
/// 其语义以既有单测为准；UI 通过本驱动访问会话，不直接操作状态机。
/// 事件映射：startNewSession/resumeSession → SessionStarted；fetchCard →
/// CardFetched（折叠 Requeue→Fetching→Showing）；rate → CardRated → FSRS
/// 调度 + 落库 → RatingCommitted；interrupt → SessionInterrupted →
/// SessionRepository.save；resume（会话内恢复）→ SessionResumed；finish →
/// SessionFinished → 删快照 + daily_stats。
class SessionDriver {
  SessionDriver({
    required this.stateMachine,
    required this.scheduler,
    required this.userWords,
    required this.reviewLogs,
    required this.sessions,
    required this.stats,
    DateTime Function()? now,
    SessionDriverLog? logger,
  }) : _clock = now ?? DateTime.now,
       logger = logger ?? _noopLogger;

  /// 注入依赖（公开只读，便于测试与 DI 装配；行为由驱动契约锁定，调用方
  /// 不应绕过驱动直接操作状态机，TECH_DOC §5.4）。
  final SessionStateMachine stateMachine;
  final FsrsScheduler scheduler;
  final UserWordRepository userWords;
  final ReviewLogRepository reviewLogs;
  final SessionRepository sessions;
  final StatsRepository stats;
  final SessionDriverLog logger;

  final DateTime Function() _clock;

  String? _sessionId;
  SessionType? _type;
  int? _wordbookId;

  /// 本次会话评分 ≥ 3（Good/Easy）的次数，完成时计入 daily_stats.correct_count
  ///（TECH_DOC §6.4：rating ≥ 3 记正确）。
  int _correctCount = 0;

  /// 已进入 Done 但持久化（删快照/写统计）尚未成功的完成数据；全部成功后清空。
  /// 用于 finish 失败后的幂等重试（TECH_DOC §5.4 驱动契约）。
  _FinalizeData? _finalize;

  /// 当前阶段（透传状态机，TECH_DOC §5.4）。
  SessionPhase get phase => stateMachine.phase;

  int? get currentWordId => stateMachine.currentWordId;

  int get position => stateMachine.position;

  SessionSnapshot? get snapshot => stateMachine.snapshot;

  /// 新会话：先让状态机校验转移合法，成功后记录驱动元数据（sessionId/类型/
  /// 词书），避免机器抛错后残留脏状态。
  void startNewSession({
    required String sessionId,
    required SessionType type,
    required int wordbookId,
    required List<int> wordIds,
  }) {
    stateMachine.handle(
      SessionStarted.fresh(
        sessionId: sessionId,
        type: type,
        initialWordIds: wordIds,
      ),
    );
    _sessionId = sessionId;
    _type = type;
    _wordbookId = wordbookId;
    _correctCount = 0;
    _finalize = null;
  }

  /// 恢复会话：快照由调用方先经 SessionRepository.load 取得；[wordbookId]
  /// 由调用方提供（sessions 表无 wordbook_id，TD-07 快照不含词书信息，
  /// TECH_DOC §5.4 驱动契约）。无快照时抛 [ArgumentError]，由调用方引导用户
  /// 重新开始而非静默继续。
  void resumeSession(SessionSnapshot? snapshot, {required int wordbookId}) {
    if (snapshot == null) {
      throw ArgumentError('恢复会话必须提供非空快照（无快照应提示重新开始）');
    }
    stateMachine.handle(SessionStarted.resume(snapshot));
    _sessionId = snapshot.sessionId;
    _type = snapshot.type;
    _wordbookId = wordbookId;
    _correctCount = 0;
    _finalize = null;
  }

  /// 会话内恢复（Paused → Showing/Fetching）：退后台 interrupt 后切回前台时
  /// 调用，同一驱动实例内用状态机自产快照重建队列（SessionResumed，§5.4）。
  ///
  /// 与 [resumeSession] 的区别：后者是跨实例/跨页面恢复（Idle → Fetching，
  /// `SessionStarted.resume`，快照由调用方经 SessionRepository.load 取得）；
  /// 本方法要求状态机处于 Paused（_start 仅允许从 Idle 发起，TECH_DOC §5.4），
  /// 因此不能复用 SessionStarted.resume。事件与语义以状态机契约为准，
  /// 其余阶段调用抛 [StateError]。
  void resume() {
    _requireSession();
    stateMachine.handle(const SessionResumed());
  }

  /// 取下一张卡：把 Requeue→Fetching 与 Fetching→Showing 两次 CardFetched
  /// 折叠为一次取卡（§5.4 状态图），返回当前展示词；仅允许在 Requeue/Fetching
  /// 阶段调用（队列为空应调用 finish 而非取卡）。
  int? fetchCard() {
    if (stateMachine.phase == SessionPhase.requeue) {
      stateMachine.handle(const CardFetched());
      stateMachine.handle(const CardFetched());
    } else if (stateMachine.phase == SessionPhase.fetching) {
      stateMachine.handle(const CardFetched());
    } else {
      throw StateError(
        'fetchCard 仅允许在 Requeue/Fetching 阶段（phase=${stateMachine.phase}）',
      );
    }
    return stateMachine.currentWordId;
  }

  /// 用户作答：CardRated → FSRS 调度 + 落库（user_words/review_logs）→
  /// RatingCommitted（§5.4 拆分独立事件的原因）。
  ///
  /// 落库失败口径（TECH_DOC §5.2/§5.4）：每个写操作失败重试 1 次，仍失败记录
  /// 日志并继续推进队列，返回 [SessionRateResult.persistFailures] 供 UI 提示。
  Future<SessionRateResult> rate(Rating rating) async {
    _requireSession();
    stateMachine.handle(CardRated(rating: rating));
    final wordId = stateMachine.currentWordId!;
    final card = await _loadCard(wordId);
    final scheduling = scheduler.next(card, rating, now: _clock());
    final word = _toUserWord(wordId, scheduling.card, rating);
    final log = _toReviewLog(wordId, rating, scheduling);

    var failures = 0;
    failures += await _persistWithRetry(
      () => userWords.upsert(word),
      'user_words.upsert(wordId=$wordId)',
    );
    failures += await _persistWithRetry(
      () => reviewLogs.add(log),
      'review_logs.add(wordId=$wordId)',
    );

    if (rating.value >= 3) {
      _correctCount++;
    }
    stateMachine.handle(const RatingCommitted());
    return SessionRateResult(
      requeued: stateMachine.phase == SessionPhase.requeue,
      persistFailures: failures,
    );
  }

  /// 中断/退后台：SessionInterrupted → 快照保存（同事务，§5.4）。
  ///
  /// 快照是恢复唯一依据（TD-07），保存失败**向上抛出**而非记录日志继续——
  /// 静默丢弃会导致中断后 App 被杀时丢失整个会话（违反 T-05）。
  /// 已处于 Paused（上次保存失败后重试）时跳过状态机事件、直接重存快照，
  /// 使中断保存可幂等重试。
  Future<void> interrupt() async {
    _requireSession();
    if (stateMachine.phase != SessionPhase.paused) {
      stateMachine.handle(const SessionInterrupted());
    }
    await sessions.save(stateMachine.snapshot!);
  }

  /// 完成会话：SessionFinished → 删快照（幂等）→ daily_stats 合并累加。
  ///
  /// 持久化失败向上抛出，驱动保留完成数据，调用方可重试 finish（快照删除
  /// 幂等、daily_stats 先读后合并写，重试不重复计数，§5.4 驱动契约）。
  Future<void> finish() async {
    _requireSession();
    if (stateMachine.phase != SessionPhase.done) {
      // 状态机进入 Done 后清空 position 等元数据，完成数据必须在事件前捕获。
      final consumed = stateMachine.position;
      final correct = _correctCount;
      stateMachine.handle(const SessionFinished());
      _finalize = (
        sessionId: _sessionId!,
        type: _type!,
        wordbookId: _wordbookId!,
        consumed: consumed,
        correctCount: correct,
      );
    }
    final data = _finalize!;
    await sessions.delete(data.sessionId);
    await _mergeDailyStats(data);
    _finalize = null;
    _sessionId = null;
    _type = null;
    _wordbookId = null;
    _correctCount = 0;
  }

  /// 读取当前词的用户状态；无记录视为新词（首次学习尚未落库）。
  Future<CardState> _loadCard(int wordId) async {
    // 本地单用户预留（TECH_DOC §8.1 user_id DEFAULT 0）。
    final row = await userWords.getWord(
      userId: 0,
      wordbookId: _wordbookId!,
      wordId: wordId,
    );
    if (row == null) {
      return const CardState(state: WordLearningState.new_);
    }
    return CardState(
      state: row.state,
      // user_words 无 step 列（§8.1）；当前单步学习/重学配置（TD-05）下
      // learning/relearning 的 step 恒为 0，按 0 处理不影响调度（§5.4 口径）。
      step:
          row.state == WordLearningState.learning ||
              row.state == WordLearningState.relearning
          ? 0
          : null,
      stability: row.stability,
      difficulty: row.difficulty,
      dueDate: row.dueDate,
      reps: row.reps,
      lapses: row.lapses,
      lastReviewAt: row.lastReviewAt,
      elapsedDays: row.elapsedDays,
      scheduledDays: row.scheduledDays,
    );
  }

  UserWord _toUserWord(int wordId, CardState card, Rating rating) => UserWord(
    userId: 0,
    wordbookId: _wordbookId!,
    wordId: wordId,
    state: card.state,
    status: _deriveStatus(card),
    dueDate: card.dueDate,
    stability: card.stability,
    difficulty: card.difficulty,
    reps: card.reps,
    lapses: card.lapses,
    lastReviewAt: card.lastReviewAt,
    lastRating: rating.value,
    elapsedDays: card.elapsedDays,
    scheduledDays: card.scheduledDays,
  );

  /// 业务层派生状态（TECH_DOC §4）：review 且安排间隔 ≥ [kMatureIntervalDays]
  /// → mature，review → review，其余（new/learning/relearning）→ learning。
  WordStatus _deriveStatus(CardState card) {
    if (card.state != WordLearningState.review) {
      return WordStatus.learning;
    }
    final scheduled = card.scheduledDays;
    if (scheduled != null && scheduled >= kMatureIntervalDays) {
      return WordStatus.mature;
    }
    return WordStatus.review;
  }

  ReviewLog _toReviewLog(
    int wordId,
    Rating rating,
    SchedulingState scheduling,
  ) => ReviewLog(
    userId: 0,
    wordbookId: _wordbookId!,
    wordId: wordId,
    rating: rating,
    reviewedAt: scheduling.card.lastReviewAt ?? _clock(),
    intervalDays: scheduling.intervalDays,
    stability: scheduling.card.stability,
    difficulty: scheduling.card.difficulty,
    sessionId: _sessionId,
    sessionType: _type!,
  );

  /// 评分落库失败口径（TECH_DOC §5.2/§5.4）：重试 1 次，仍失败记录日志并
  /// 返回失败计数（队列推进不受影响）。user_words 与 review_logs 分属两个
  /// 仓储接口、顺序写入，可能出现"user_words 成功而 review_logs 失败"的
  /// 部分持久化；调度正确性以 user_words 为准（§7.2），日志缺失仅影响导出
  /// 与调参，缺失评分由该词下次到期按旧状态重新调度兜底。
  Future<int> _persistWithRetry(
    Future<void> Function() write,
    String opName,
  ) async {
    try {
      await write();
      return 0;
    } catch (error) {
      try {
        await write();
        return 0;
      } catch (error2) {
        logger('评分落库失败（重试 1 次后仍失败）：$opName', error2);
        return 1;
      }
    }
  }

  Future<void> _mergeDailyStats(_FinalizeData data) async {
    // 按会话类型累加（learning→new_count；review→review_count+correct_count，
    // §6.4），先读当日再合并 upsert，避免覆盖同日其他会话的计数；completed
    // 打卡标记由任务完成页在整日任务完成后写入，驱动不置位（§5.4）。
    final day = _formatLocalDay(_clock());
    final existing = await stats.getByDay(day);
    final base = existing ?? DailyStats(day: day);
    final merged = data.type == SessionType.learning
        ? DailyStats(
            day: day,
            newCount: base.newCount + data.consumed,
            reviewCount: base.reviewCount,
            correctCount: base.correctCount,
            completed: base.completed,
          )
        : DailyStats(
            day: day,
            newCount: base.newCount,
            reviewCount: base.reviewCount + data.consumed,
            correctCount: base.correctCount + data.correctCount,
            completed: base.completed,
          );
    await stats.upsert(merged);
  }

  /// 本地日边界 YYYY-MM-DD（daily_stats.day 键，§8.1）。不引入 intl，
  /// 纯字符串补零保持 domain 零依赖。
  String _formatLocalDay(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    return '${time.year}-$month-$day';
  }

  void _requireSession() {
    if (_sessionId == null) {
      throw StateError('当前没有进行中的会话');
    }
  }
}

/// 驱动日志回调：domain 不依赖 Flutter/foundation，由应用装配层接入
/// AppLogger（TECH_DOC §5.4 驱动契约）；默认空实现避免生产遗漏接线时静默丢日志。
typedef SessionDriverLog = void Function(String message, [Object? error]);

void _noopLogger(String message, [Object? error]) {}

/// 会话完成数据：触发 SessionFinished 前捕获（状态机 Done 后清空元数据），
/// 供删快照与 daily_stats 累加，并在持久化失败后支持幂等重试 finish。
typedef _FinalizeData = ({
  String sessionId,
  SessionType type,
  int wordbookId,
  int consumed,
  int correctCount,
});

/// rate() 返回结果：本次评分后是否需要重排、落库失败计数（0=全部成功）。
class SessionRateResult {
  const SessionRateResult({
    required this.requeued,
    required this.persistFailures,
  });

  /// Again 且仍有剩余重排次数（状态机进入 Requeue，答错词稍后再次出现）。
  final bool requeued;

  /// 重试后仍失败的写操作数（0=全部成功；>0 表示有评分未落库，UI 可提示）。
  final int persistFailures;
}

/// 业务层"间隔足够长"阈值（Anki 口径的 mature 判定，PRD §4"掌握"定义；
/// TECH_DOC §5.4 驱动契约字段口径）。
const int kMatureIntervalDays = 21;
