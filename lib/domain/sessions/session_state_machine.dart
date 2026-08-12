import '../scheduling/fsrs_scheduler.dart';
import 'session_snapshot.dart';

/// 学习/复习会话状态机契约（TECH_DOC §5.4 状态图）。
///
/// 纯逻辑：sessionId、初始队列/词表与事件均由调用方传入；状态机不读写数据库、
/// 不执行 FSRS 计算、不生成随机，也不依赖 Flutter/Android API（AGENTS §3.2）。
/// 学习与复习共用同一状态机，[SessionType] 仅作记录，不影响转移规则。
abstract interface class SessionStateMachine {
  /// 当前阶段（与 TECH_DOC §5.4 状态图一一对应）。
  SessionPhase get phase;

  /// 非空时表示存在可恢复的未完成会话：活动阶段为实时快照，进入 Done 后为 null。
  SessionSnapshot? get snapshot;

  /// 当前正在展示/作答的卡（Showing/Rating/Requeue 阶段非空，其余为 null）。
  int? get currentWordId;

  /// 已消费卡数（进度，即 sessions.position，TECH_DOC §5.4）。
  int get position;

  /// 处理一个会话事件；非法转移抛出 [StateError]。
  void handle(SessionEvent event);
}

/// 会话阶段（与 TECH_DOC §5.4 状态图一一对应）。
enum SessionPhase { idle, fetching, showing, rating, requeue, paused, done }

/// 会话事件（驱动状态机转移的输入类型）。
sealed class SessionEvent {
  const SessionEvent();
}

/// 进入会话（Idle → Fetching）。
final class SessionStarted extends SessionEvent {
  /// 新会话：由调用方提供 sessionId、会话类型与初始词表（词 ID 列表，不重复）。
  const SessionStarted.fresh({
    required this.sessionId,
    required this.type,
    required this.initialWordIds,
  }) : snapshot = null;

  /// 恢复会话：以 [snapshot] 全量重建队列（TD-07），不需要初始词表。
  const SessionStarted.resume(this.snapshot)
    : sessionId = null,
      type = null,
      initialWordIds = null;

  /// 恢复快照（恢复会话时非空；新会话为 null）。
  final SessionSnapshot? snapshot;
  final String? sessionId;
  final SessionType? type;
  final List<int>? initialWordIds;
}

/// 取到下一张卡（Requeue → Fetching，或 Fetching → Showing）。
final class CardFetched extends SessionEvent {
  const CardFetched();
}

/// 用户作答完成（Showing → Rating）。
///
/// 评分映射见 TECH_DOC §7.3：Again（1）= 答错，是触发重排的唯一评分；
/// Hard/Good/Easy 一律不重排。FSRS 调度与落库由调用方在事件外完成。
final class CardRated extends SessionEvent {
  const CardRated({required this.rating});

  final Rating rating;
}

/// 调用方完成评分处理（FSRS 调度与写库）后推进状态机（Rating → Requeue/Fetching）。
///
/// 拆分为独立事件的原因：状态机不在评分时立即消费卡片，而是让调用方
/// 有机会在 CardRated 与 RatingCommitted 之间完成调度计算与持久化。
final class RatingCommitted extends SessionEvent {
  const RatingCommitted();
}

/// 中断/退后台（Fetching/Showing/Rating/Requeue → Paused，产出快照）。
final class SessionInterrupted extends SessionEvent {
  const SessionInterrupted();
}

/// 恢复会话（Paused → Showing/Fetching，按快照重建队列）。
final class SessionResumed extends SessionEvent {
  const SessionResumed();
}

/// 队列清空，会话完成（仅 Fetching 且队列为空时合法；Done 后快照置空）。
final class SessionFinished extends SessionEvent {
  const SessionFinished();
}
