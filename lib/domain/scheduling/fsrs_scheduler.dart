import '../models/user_word.dart';
import 'fsrs/fsrs_defaults.dart';

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
    this.step,
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

  /// 学习/重学步骤下标（对应官方实现 `Card.step`，0 起；Review 状态为 null，
  /// 新词首次评分时视作 0）。TECH_DOC §7.2。
  final int? step;

  /// 记忆稳定性 S（间隔的数学期望）。
  final double stability;

  /// 难度因子 D（0–10）。
  final double difficulty;

  final DateTime? dueDate;

  /// 复习次数（Anki 口径：每次评分 +1，TECH_DOC §7.2 注）。
  final int reps;

  /// 遗忘次数（Anki 口径：Review 状态评 Again 时 +1，TECH_DOC §7.2 注）。
  final int lapses;

  final DateTime? lastReviewAt;

  /// 距上次复习天数（user_words 镜像字段；调度计算不使用，见 TECH_DOC §7.2 注）。
  final double? elapsedDays;

  /// 上次安排的间隔（天）（user_words 镜像字段；调度计算不使用）。
  final double? scheduledDays;

  /// 距 [lastReviewAt] 的整天数（向下取整，等价官方 `(now - last_review).days`）。
  ///
  /// 无上次复习返回 null；[now] 早于上次复习（业务上不允许）按 0 处理。
  int? elapsedDaysAt(DateTime now) {
    final last = lastReviewAt;
    if (last == null) {
      return null;
    }
    if (now.isBefore(last)) {
      return 0;
    }
    return now.difference(last).inDays;
  }
}

/// FSRS 评分后的调度结果（对齐官方 `review_card` 返回的调度数据）。
class SchedulingState {
  const SchedulingState({
    required this.card,
    required this.intervalDays,
    required this.retrievability,
  });

  /// 评分后的完整新卡片状态，可直接持久化到 user_words（TECH_DOC §7.6）。
  final CardState card;

  /// 本次评分安排的间隔（天）。
  final double intervalDays;

  /// 评分时刻的预测记忆保持率 R(t,S)；新词首次评分为 0。
  /// 写入 review_logs 供导出与 FSRS 参数优化（M3）使用（TECH_DOC §7.5）。
  final double retrievability;
}

/// FSRS 参数（TD-05：learning_steps=[10m]，desired retention=0.9；TECH_DOC §7.4）。
class FsrsParameters {
  const FsrsParameters({
    this.desiredRetention = 0.9,
    this.learningStepsMinutes = const [10],
    this.relearningStepsMinutes = const [10],
    this.weights = kFsrs5DefaultWeights,
    this.maximumIntervalDays = 36500,
    this.enableFuzzing = false,
  });

  final double desiredRetention;
  final List<int> learningStepsMinutes;
  final List<int> relearningStepsMinutes;

  /// FSRS-5 模型权重 w[0..18]，默认官方参数表（TECH_DOC §7.4）。
  final List<double> weights;

  /// 复习间隔上限（天），官方默认 36500。
  final int maximumIntervalDays;

  /// 是否对 Review 间隔施加官方 fuzz 随机微扰。
  /// 官方默认开启，本项目默认关闭以保证调度确定性与测试可复现（TECH_DOC §7.4）。
  final bool enableFuzzing;
}
