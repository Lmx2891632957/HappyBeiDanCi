import '../models/user_word.dart';

/// 复习队列构建契约（TECH_DOC §6.2）。
///
/// 排序规则：overdueDays 降序（最逾期最优先）→ stability 升序（不稳定词优先）
/// → word_id 升序（确定性，便于测试）。
/// [cap] 为复习软上限（PRD F2，默认 300）：超出部分不修改 due_date，
/// 次日自然排在最前，实现“按逾期严重度顺延”且无惩罚语义。
abstract interface class ReviewQueueBuilder {
  /// 构建今日复习队列。
  ///
  /// [dueWords] 为已按 `due_date <= 今日结束` 过滤的到期词（仓储契约
  /// `UserWordRepository.getDueWords`）；[todayStart] 为“今日零点”，由调用方
  /// 按调度时区（TECH_DOC §18，默认 Asia/Shanghai）换算为当日 00:00:00 传入，
  /// overdueDays = floor((todayStart - due_date) / 1天)，构建器只做纯算术。
  /// [cap] 为 null 表示关闭软上限（不截断）。
  List<UserWord> build(
    List<UserWord> dueWords, {
    int? cap,
    required DateTime todayStart,
  });
}
