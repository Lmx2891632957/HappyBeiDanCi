/// 会话类型（TECH_DOC §8.1 sessions.session_type）。
enum SessionType {
  learning,
  review;

  String get storageValue => switch (this) {
    SessionType.learning => 'learning',
    SessionType.review => 'review',
  };
}

/// 会话快照：中断后恢复队列的唯一依据（T-05 / TD-07）。
///
/// 设计意图：学习/复习会话全部完成后删除快照；中断恢复时按原队列继续，
/// 已答过的卡不重复（重排卡除外，TECH_DOC §5.4）。
class SessionSnapshot {
  const SessionSnapshot({
    required this.sessionId,
    required this.type,
    required this.position,
    required this.items,
  });

  final String sessionId;
  final SessionType type;

  /// 当前队列位置（sessions.position）。
  final int position;
  final List<SessionItemSnapshot> items;
}

/// 会话队列项快照（session_items 表）。
class SessionItemSnapshot {
  const SessionItemSnapshot({
    required this.wordId,
    required this.seq,
    required this.requeueLeft,
  });

  final int wordId;

  /// 当前队列顺序。
  final int seq;

  /// 该词剩余重排次数（每词每会话最多 2 次，TECH_DOC §5.2）。
  final int requeueLeft;
}
