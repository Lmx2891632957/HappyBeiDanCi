import '../sessions/session_snapshot.dart';

/// 会话快照仓储契约（TD-07：快照为中断续学的唯一恢复依据）。
///
/// 快照语义（TECH_DOC §5.4）：[SessionSnapshot.position] = 已消费卡数（进度）；
/// [SessionSnapshot.items] 为剩余队列、按 seq 升序。保存时 items 全量替换，
/// 删除时两表同事务清理，加载时按 seq 升序组装回快照，可直接交给状态机
/// `SessionStarted.resume` 恢复。
///
/// 调用方：今日任务页（TECH_DOC §5.1 第 4 点"存在未完成会话"提示）与会话页
/// （中断落库、启动恢复）。实现位于 `data/repositories/`，domain 不依赖 data
/// （AGENTS §3.2）。
abstract interface class SessionRepository {
  /// 保存快照：sessions 一行 + session_items 全量替换，同一数据库事务内完成
  /// （TECH_DOC §5.4/§8.2）。首次插入填 created_at/updated_at，覆盖保存保留
  /// created_at、刷新 updated_at。
  Future<void> save(SessionSnapshot snapshot);

  /// 加载单个快照：不存在返回 null；数据损坏（孤儿 items、seq 不连续、
  /// 非法负值、未知 session_type）抛出 StateError，不静默丢弃（TECH_DOC §5.4）。
  Future<SessionSnapshot?> load(String sessionId);

  /// 加载全部未完成快照，供今日任务页"存在未完成会话"提示（TECH_DOC §5.1）。
  /// 每个快照均按 load 的同一规则校验，任一损坏即整体抛错。
  Future<List<SessionSnapshot>> loadAll();

  /// 删除快照：sessions 与 session_items 两表同事务清理（会话进入 Done 后调用）。
  Future<void> delete(String sessionId);
}
