import '../models/user_word.dart';
import 'review_queue_builder.dart';

/// 复习队列构建器：按逾期严重度排序并应用复习软上限（TECH_DOC §6.2）。
///
/// 纯 Dart，不依赖 Flutter/Android API 与 data 层：输入“到期词 + 软上限 +
/// 今日零点”，输出“排序并截断后的队列”。不修改任何词的 due_date，
/// 被顺延的词次日以更高的 overdueDays 自然排在最前，实现无惩罚的补卡语义。
class DefaultReviewQueueBuilder implements ReviewQueueBuilder {
  const DefaultReviewQueueBuilder();

  @override
  List<UserWord> build(
    List<UserWord> dueWords, {
    int? cap,
    required DateTime todayStart,
  }) {
    if (cap != null && cap < 0) {
      throw ArgumentError.value(cap, 'cap', '复习软上限不能为负数');
    }
    // 复制后排序，避免修改调用方持有的列表（顺延词保持原 due_date）。
    final queue = [...dueWords]
      ..sort((a, b) => _compareByOverdue(a, b, todayStart));
    if (cap == null || queue.length <= cap) {
      return queue;
    }
    return queue.sublist(0, cap);
  }

  /// 三键比较：overdueDays 降序 → stability 升序 → word_id 升序。
  int _compareByOverdue(UserWord a, UserWord b, DateTime todayStart) {
    final overdueA = _overdueDays(a.dueDate, todayStart);
    final overdueB = _overdueDays(b.dueDate, todayStart);
    if (overdueA != overdueB) {
      return overdueB.compareTo(overdueA);
    }
    if (a.stability != b.stability) {
      return a.stability.compareTo(b.stability);
    }
    return a.wordId.compareTo(b.wordId);
  }

  /// overdueDays = floor((今日零点 - due_date) / 1天)（TECH_DOC §6.2）。
  ///
  /// “今日零点”即 [todayStart]，由调用方按调度时区换算后传入，此处只做纯算术：
  /// 今日到期（差值为 (-1天, 0]）得 -1 或 0，昨日到期（未满 1 天）得 0，
  /// 更早按整日累计为正。due_date 为空的词兜底按今日到期（-1）处理，
  /// 避免 null 干扰排序。
  int _overdueDays(DateTime? dueDate, DateTime todayStart) {
    if (dueDate == null) {
      return -1;
    }
    final diffMs = todayStart.difference(dueDate).inMilliseconds;
    // Dart 的 `~/` 对负数向零截断而非向下取整，与口径不符
    // （如今日到期差值 -0.5 天应为 -1），故对负余数修正 1。
    var days = diffMs ~/ Duration.millisecondsPerDay;
    if (diffMs % Duration.millisecondsPerDay != 0 && diffMs < 0) {
      days -= 1;
    }
    return days;
  }
}
