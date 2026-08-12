import '../models/user_word.dart';

/// 复习队列构建契约（TECH_DOC §6.2）。
///
/// 排序规则：overdueDays 降序（最逾期最优先）→ stability 升序（不稳定词优先）
/// → word_id 升序（确定性，便于测试）。
/// [cap] 为复习软上限（PRD F2，默认 300）：超出部分不修改 due_date，
/// 次日自然排在最前，实现“按逾期严重度顺延”且无惩罚语义。
abstract interface class ReviewQueueBuilder {
  List<UserWord> build(List<UserWord> dueWords, {int? cap});
}
