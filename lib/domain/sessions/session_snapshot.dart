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
/// 语义（TECH_DOC §5.4）：[items] 只含剩余队列（已答卡不重复，重排卡除外），
/// 按 seq 升序排列；[position] 为已消费卡数（进度），恢复时仅作进度恢复，
/// 下一张卡恒为剩余队列队首。会话进入 Done 后快照置空。
class SessionSnapshot {
  const SessionSnapshot({
    required this.sessionId,
    required this.type,
    required this.position,
    required this.items,
  });

  final String sessionId;
  final SessionType type;

  /// 已消费卡数（sessions.position，进度语义，TECH_DOC §5.4）。
  final int position;

  /// 剩余队列，按 [SessionItemSnapshot.seq] 升序。
  final List<SessionItemSnapshot> items;
}

/// 会话队列项快照（session_items 表，一行一卡）。
class SessionItemSnapshot {
  const SessionItemSnapshot({
    required this.wordId,
    required this.seq,
    required this.requeueLeft,
  });

  final int wordId;

  /// 该词待展示 occurrence 在剩余队列中的顺序（0 起连续，TECH_DOC §5.4）。
  final int seq;

  /// 该词剩余重排次数（每词每会话最多 2 次，TECH_DOC §5.2）。
  final int requeueLeft;
}
