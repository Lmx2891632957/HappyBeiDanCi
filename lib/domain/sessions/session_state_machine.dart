import 'session_snapshot.dart';

/// 学习/复习会话状态机契约（TECH_DOC §5.4 状态图）。
///
/// 骨架阶段只定义状态与事件类型，状态转移规则（答错重排 ≤2 次、中断恢复、
/// 完成后清理快照）由具体实现完成，并在 test/domain 下配套“中断→恢复”测试
/// （AGENTS §6.2）。
abstract interface class SessionStateMachine {
  SessionPhase get phase;

  /// 非空时表示存在可恢复的未完成会话。
  SessionSnapshot? get snapshot;
}

/// 会话阶段（与 TECH_DOC §5.4 状态图一一对应）。
enum SessionPhase {
  idle,
  fetching,
  showing,
  rating,
  requeue,
  paused,
  done,
}

/// 会话事件（驱动状态机转移的输入类型）。
sealed class SessionEvent {
  const SessionEvent();
}

/// 进入会话（可能携带恢复快照）。
final class SessionStarted extends SessionEvent {
  const SessionStarted({this.snapshot});

  final SessionSnapshot? snapshot;
}

/// 取到下一张卡。
final class CardFetched extends SessionEvent {
  const CardFetched();
}

/// 用户作答完成（实现方携带评分与答案结果）。
final class CardRated extends SessionEvent {
  const CardRated({required this.rating, required this.correct});

  final int rating;
  final bool correct;
}

/// 中断/退后台。
final class SessionInterrupted extends SessionEvent {
  const SessionInterrupted();
}

/// 恢复会话。
final class SessionResumed extends SessionEvent {
  const SessionResumed();
}

/// 队列清空，会话完成。
final class SessionFinished extends SessionEvent {
  const SessionFinished();
}
