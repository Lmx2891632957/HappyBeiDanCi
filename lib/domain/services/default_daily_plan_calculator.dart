import 'dart:math' as math;

import '../models/daily_plan.dart';
import '../models/user_word.dart';
import '../scheduling/default_review_queue_builder.dart';
import '../scheduling/review_queue_builder.dart';
import 'daily_plan_calculator.dart';

/// 每日计划计算器（常规模式，TECH_DOC §6.1）：纯逻辑，不读写数据库。
class DefaultDailyPlanCalculator implements DailyPlanCalculator {
  const DefaultDailyPlanCalculator({ReviewQueueBuilder? queueBuilder})
      : _queueBuilder = queueBuilder ?? const DefaultReviewQueueBuilder();

  final ReviewQueueBuilder _queueBuilder;

  @override
  DailyPlan calculate({
    required int dailyGoal,
    required int remainingNewWords,
    required List<UserWord> dueWords,
    int? cap,
    required DateTime todayStart,
  }) {
    if (dailyGoal < 0) {
      throw ArgumentError.value(dailyGoal, 'dailyGoal', '每日新词目标不能为负数');
    }
    if (remainingNewWords < 0) {
      throw ArgumentError.value(
        remainingNewWords,
        'remainingNewWords',
        '剩余新词数不能为负数',
      );
    }
    final newWordCount = math.min(dailyGoal, remainingNewWords);
    final reviewQueue = _queueBuilder.build(
      dueWords,
      cap: cap,
      todayStart: todayStart,
    );
    final deferredCount = dueWords.length - reviewQueue.length;
    return DailyPlan(
      newWordCount: newWordCount,
      reviewQueue: reviewQueue,
      deferredCount: deferredCount,
    );
  }
}
