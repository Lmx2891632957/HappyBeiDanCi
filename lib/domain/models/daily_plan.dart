import 'user_word.dart';

/// 每日计划结果模型（TECH_DOC §6.1 常规模式）。
class DailyPlan {
  const DailyPlan({
    required this.newWordCount,
    required this.reviewQueue,
    required this.deferredCount,
  });

  /// 新词数 = min(dailyGoal, 词书剩余新词数)。
  final int newWordCount;

  /// 今日复习队列（已按逾期严重度排序并截断）。
  final List<UserWord> reviewQueue;

  /// 顺延数 = 到期词总数 - 复习数；顺延词保持原 due_date，次日自然排在最前。
  final int deferredCount;

  /// 复习数 = min(到期词总数, reviewCap) = reviewQueue.length。
  int get reviewCount => reviewQueue.length;
}
