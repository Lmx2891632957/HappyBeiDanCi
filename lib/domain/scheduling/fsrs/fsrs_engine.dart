/// FSRS-5 引擎：官方 py-fsrs v5.1.3 `Scheduler.review_card` 状态机的 Dart 移植。
///
/// 纯 Dart，不依赖 Flutter/Android API 与 data 层（TECH_DOC §2.1/§7.5）：
/// 输入“卡片状态 + 评分 + 当前时间”，输出“新卡片状态 + 间隔 + retrievability”。
library;

import 'dart:math' as math;

import '../../models/user_word.dart';
import '../fsrs_scheduler.dart';
import 'fsrs_formulas.dart';

/// FSRS-5 调度引擎（实现 [FsrsScheduler]）。
///
/// 状态转移逻辑逐分支对齐官方实现：
/// - Learning/Relearning：按步骤下标推进，Again 重置步骤、Hard 保持步骤
///   （单步配置下间隔 = 步骤 × 1.5）、Good 最后一步毕业、Easy 直接毕业；
/// - Review：Again 进入 Relearning（无重学步骤则保持 Review），其余按稳定性排期；
/// - 距上次复习不足 1 天走短期稳定性，否则按遗忘曲线走长期更新。
class FsrsEngine implements FsrsScheduler {
  FsrsEngine({
    FsrsParameters parameters = const FsrsParameters(),
    math.Random? random,
  })  : _parameters = parameters,
        _formulas = FsrsFormulas(parameters.weights),
        _random = random ?? math.Random();

  final FsrsParameters _parameters;
  final FsrsFormulas _formulas;
  final math.Random _random;

  @override
  FsrsParameters get parameters => _parameters;

  @override
  SchedulingState next(CardState card, Rating rating, {required DateTime now}) {
    // 距上次复习整天数（官方 `days_since_last_review`，无上次复习为 null）。
    final elapsedDays = card.elapsedDaysAt(now);

    // 评分时刻的预测记忆保持率：新词（无上次复习）为 0，其余按遗忘曲线计算。
    // 需在状态更新前用“更新前”的稳定性取值（官方 `get_retrievability` 语义）。
    final retrievability = card.lastReviewAt == null
        ? 0.0
        : _formulas.retrievability(
            stability: card.stability,
            elapsedDays: elapsedDays ?? 0,
          );

    var state = card.state;
    var step = card.step;
    var stability = card.stability;
    var difficulty = card.difficulty;

    // 首次评分（新词）：初始化 S/D（官方 stability/difficulty 为 None 的分支）。
    if (state == WordLearningState.new_) {
      stability = _formulas.initialStability(rating);
      difficulty = _formulas.initialDifficulty(rating);
    } else if (elapsedDays != null && elapsedDays < 1) {
      // 距上次复习不足 1 天：短期稳定性更新（学习/重学步骤场景）。
      stability = _formulas.shortTermStability(stability, rating);
      difficulty = _formulas.nextDifficulty(difficulty, rating);
    } else {
      // 距上次复习 ≥1 天（或无上次复习时间）：按遗忘曲线长期更新。
      stability = _formulas.nextStability(
        difficulty: difficulty,
        stability: stability,
        retrievability: retrievability,
        rating: rating,
      );
      difficulty = _formulas.nextDifficulty(difficulty, rating);
    }

    Duration interval;
    // 是否为整日复习间隔（fuzz 只作用于最终为 Review 的间隔，官方语义）。
    var isReviewInterval = false;

    switch (state) {
      case WordLearningState.new_:
      case WordLearningState.learning:
        state = WordLearningState.learning;
        step = step ?? 0;
        final steps = _parameters.learningStepsMinutes;
        // 无学习步骤，或卡片此前由更多步骤的配置调度且未评 Again（官方边缘情况）。
        final graduated = steps.isEmpty ||
            (step >= steps.length && rating != Rating.again);
        if (graduated) {
          state = WordLearningState.review;
          step = null;
          interval = Duration(days: _nextInterval(stability));
          isReviewInterval = true;
        } else {
          final result = _stepResult(
            steps: steps,
            state: state,
            step: step,
            rating: rating,
            stability: stability,
          );
          state = result.state;
          step = result.step;
          interval = result.interval;
          isReviewInterval = result.isReviewInterval;
        }

      case WordLearningState.review:
        if (rating == Rating.again) {
          if (_parameters.relearningStepsMinutes.isEmpty) {
            // 未配置重学步骤：遗忘后保持 Review，按遗忘稳定性排期（官方语义）。
            interval = Duration(days: _nextInterval(stability));
            isReviewInterval = true;
          } else {
            state = WordLearningState.relearning;
            step = 0;
            interval = _minutes(_parameters.relearningStepsMinutes[0]);
          }
        } else {
          interval = Duration(days: _nextInterval(stability));
          isReviewInterval = true;
        }

      case WordLearningState.relearning:
        final steps = _parameters.relearningStepsMinutes;
        step = step ?? 0;
        final graduated = steps.isEmpty ||
            (step >= steps.length && rating != Rating.again);
        if (graduated) {
          state = WordLearningState.review;
          step = null;
          interval = Duration(days: _nextInterval(stability));
          isReviewInterval = true;
        } else {
          final result = _stepResult(
            steps: steps,
            state: state,
            step: step,
            rating: rating,
            stability: stability,
          );
          state = result.state;
          step = result.step;
          interval = result.interval;
          isReviewInterval = result.isReviewInterval;
        }
    }

    // fuzz 仅作用于最终为 Review 状态的整日间隔（官方 `enable_fuzzing` 语义）。
    if (_parameters.enableFuzzing &&
        state == WordLearningState.review &&
        isReviewInterval) {
      interval = Duration(
        days: fuzzInterval(
          interval.inDays,
          random: _random,
          maximumIntervalDays: _parameters.maximumIntervalDays,
        ),
      );
    }

    final intervalDays = interval.inMicroseconds / Duration.microsecondsPerDay;
    final updated = CardState(
      state: state,
      step: step,
      stability: stability,
      difficulty: difficulty,
      dueDate: now.add(interval),
      // Anki 口径计数器（官方 py-fsrs 不维护，属本地扩展，TECH_DOC §7.2 注）：
      // reps 每次评分 +1；Review 状态评 Again（遗忘）时 lapses +1。
      reps: card.reps + 1,
      lapses: card.lapses +
          (card.state == WordLearningState.review && rating == Rating.again
              ? 1
              : 0),
      lastReviewAt: now,
      elapsedDays: elapsedDays?.toDouble(),
      scheduledDays: intervalDays,
    );

    return SchedulingState(
      card: updated,
      intervalDays: intervalDays,
      retrievability: retrievability,
    );
  }

  /// 学习/重学步骤推进（官方 Learning/Relearning 分支共用的逻辑）。
  ///
  /// 返回评分后的 (新状态, 新步骤, 间隔, 是否整日复习间隔)：
  /// - Again：步骤重置为 0，间隔 = 首个步骤；
  /// - Hard：步骤保持不变；单步配置间隔 = 步骤 × 1.5，双步配置取前两步均值；
  /// - Good：非最后一步前进 1 步，最后一步毕业；
  /// - Easy：跳过剩余步骤直接毕业。
  ({
    WordLearningState state,
    int? step,
    Duration interval,
    bool isReviewInterval,
  }) _stepResult({
    required List<int> steps,
    required WordLearningState state,
    required int step,
    required Rating rating,
    required double stability,
  }) {
    switch (rating) {
      case Rating.again:
        return (
          state: state,
          step: 0,
          interval: _minutes(steps[0]),
          isReviewInterval: false,
        );
      case Rating.hard:
        final double minutes;
        if (step == 0 && steps.length == 1) {
          minutes = steps[0] * 1.5;
        } else if (step == 0 && steps.length >= 2) {
          minutes = (steps[0] + steps[1]) / 2.0;
        } else {
          minutes = steps[step].toDouble();
        }
        return (
          state: state,
          step: step,
          interval: _minutes(minutes),
          isReviewInterval: false,
        );
      case Rating.good:
        if (step + 1 == steps.length) {
          return (
            state: WordLearningState.review,
            step: null,
            interval: Duration(days: _nextInterval(stability)),
            isReviewInterval: true,
          );
        }
        return (
          state: state,
          step: step + 1,
          interval: _minutes(steps[step + 1]),
          isReviewInterval: false,
        );
      case Rating.easy:
        return (
          state: WordLearningState.review,
          step: null,
          interval: Duration(days: _nextInterval(stability)),
          isReviewInterval: true,
        );
    }
  }

  int _nextInterval(double stability) => _formulas.nextInterval(
        stability,
        desiredRetention: _parameters.desiredRetention,
        maximumIntervalDays: _parameters.maximumIntervalDays,
      );

  Duration _minutes(num minutes) => Duration(
        microseconds: (minutes * Duration.microsecondsPerMinute).round(),
      );
}
