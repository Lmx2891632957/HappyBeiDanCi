import '../models/user_word.dart';

/// FSRS-5 调度器契约（TECH_DOC §7.1）。
///
/// 设计意图：具体引擎（官方 Python 参考实现的 Dart 移植）放在
/// domain/scheduling/fsrs/ 内实现本接口；备选 SM-2 也实现同一接口，
/// 切换算法时调用方与数据层均无需改动。
abstract interface class FsrsScheduler {
  /// 以 [rating] 对 [card] 在 [now] 时刻评分，返回该评分对应的新调度状态。
  ///
  /// 算法层不读数据库：输入为“词状态 + 评分 + 当前时间”，输出为“新状态 + 日志”，
  /// 可整层单元测试（TECH_DOC §7.5）。
  SchedulingState next(CardState card, Rating rating, {required DateTime now});

  /// 当前算法参数（desired retention、学习步骤等），便于展示与持久化。
  FsrsParameters get parameters;
}

/// 用户评分（TECH_DOC §7.3 评分映射：认识/模糊/不认识 → Good/Hard/Again）。
enum Rating {
  again(1),
  hard(2),
  good(3),
  easy(4);

  const Rating(this.value);

  /// 与 review_logs.rating 存储值一致。
  final int value;
}

/// FSRS-5 记忆卡片状态（TECH_DOC §7.2 字段）。
class CardState {
  const CardState({
    required this.state,
    this.stability = 0,
    this.difficulty = 0,
    this.dueDate,
    this.reps = 0,
    this.lapses = 0,
    this.lastReviewAt,
    this.elapsedDays,
    this.scheduledDays,
  });

  final WordLearningState state;

  /// 记忆稳定性 S（间隔的数学期望）。
  final double stability;

  /// 难度因子 D（0–10）。
  final double difficulty;
  final DateTime? dueDate;
  final int reps;
  final int lapses;
  final DateTime? lastReviewAt;
  final double? elapsedDays;
  final double? scheduledDays;
}

/// FSRS 评分后的调度结果：下次状态、间隔与新到期时间。
class SchedulingState {
  const SchedulingState({
    required this.state,
    required this.stability,
    required this.difficulty,
    required this.dueDate,
    required this.intervalDays,
  });

  final WordLearningState state;
  final double stability;
  final double difficulty;
  final DateTime dueDate;

  /// 本次评分安排的间隔（天）。
  final double intervalDays;
}

/// FSRS 参数（TD-05：learning_steps=[10m]，desired retention=0.9）。
class FsrsParameters {
  const FsrsParameters({
    this.desiredRetention = 0.9,
    this.learningStepsMinutes = const [10],
    this.relearningStepsMinutes = const [10],
  });

  final double desiredRetention;
  final List<int> learningStepsMinutes;
  final List<int> relearningStepsMinutes;
}
