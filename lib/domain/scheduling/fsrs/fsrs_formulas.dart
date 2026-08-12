/// FSRS-5 纯公式层：状态无关的数学函数集合。
///
/// 来源：open-spaced-repetition/py-fsrs v5.1.3 `fsrs/fsrs.py`（FSRS-5 论文
/// “A Stochastic Shortest Path Algorithm for Optimizing Spaced Repetition
/// Scheduling”的官方 Python 实现）。状态机推进见 [fsrs_engine.dart]。
library;

import 'dart:math' as math;

import '../fsrs_scheduler.dart';
import 'fsrs_defaults.dart';

/// 遗忘曲线因子 FACTOR = 0.9^(1/DECAY) - 1（DR=0.9 时下一间隔 ≈ 稳定性）。
final double kFsrs5Factor = math.pow(0.9, 1 / kFsrs5Decay).toDouble() - 1;

/// Python `round()` 语义：银行家舍入（恰好 .5 时取偶数）。
///
/// 官方 `_next_interval`/fuzz 使用 Python `round()`，与 Dart `double.round()`
/// （四舍五入）在 .5 边界行为不同，故单独实现以保证数值一致。
int roundHalfEven(double value) {
  final floor = value.floor();
  final fraction = value - floor;
  if (fraction < 0.5) {
    return floor;
  }
  if (fraction > 0.5) {
    return floor + 1;
  }
  return floor.isEven ? floor : floor + 1;
}

/// FSRS-5 数学公式集合；每个实例绑定一组权重 w。
class FsrsFormulas {
  FsrsFormulas(this.weights) : assert(weights.length == kFsrs5WeightCount);

  /// 模型权重 w[0..18]。
  final List<double> weights;

  static const int kFsrs5WeightCount = 19;

  /// 难度钳制到 [1, 10]。
  double clampDifficulty(double difficulty) =>
      difficulty.clamp(1.0, 10.0).toDouble();

  /// S0(rating) = max(w[rating-1], 0.1)：首次评分初始稳定性。
  double initialStability(Rating rating) =>
      math.max(weights[rating.value - 1], 0.1);

  /// D0(rating) = clamp(w[4] - e^(w[5]*(rating-1)) + 1, 1, 10)：首次评分初始难度。
  double initialDifficulty(Rating rating) => clampDifficulty(
        weights[4] - math.exp(weights[5] * (rating.value - 1)) + 1,
      );

  /// D' = clamp(w[7]·D0(Easy) + (1-w[7])·(D + (10-D)·(-w[6]·(rating-3))/9), 1, 10)
  ///
  /// 来源：py-fsrs `_next_difficulty`（线性阻尼 + 均值回归，向 Easy 初始难度回归）。
  double nextDifficulty(double difficulty, Rating rating) {
    final easyInitial = initialDifficulty(Rating.easy);
    final deltaD = -weights[6] * (rating.value - 3);
    final damped = difficulty + (10 - difficulty) * deltaD / 9;
    return clampDifficulty(weights[7] * easyInitial + (1 - weights[7]) * damped);
  }

  /// R(t,S) = (1 + FACTOR·t/S)^DECAY：给定经过天数后的预测记忆保持率。
  double retrievability({required double stability, required int elapsedDays}) =>
      math.pow(1 + kFsrs5Factor * elapsedDays / stability, kFsrs5Decay).toDouble();

  /// S'_r（回忆成功）：S·(1 + e^w[8]·(11-D)·S^-w[9]·(e^((1-R)·w[10])-1)·hardPenalty·easyBonus)
  ///
  /// hardPenalty = w[15]（Hard）否则 1；easyBonus = w[16]（Easy）否则 1。
  double nextRecallStability({
    required double difficulty,
    required double stability,
    required double retrievability,
    required Rating rating,
  }) {
    final hardPenalty = rating == Rating.hard ? weights[15] : 1.0;
    final easyBonus = rating == Rating.easy ? weights[16] : 1.0;
    return stability *
        (1 +
            math.exp(weights[8]) *
                (11 - difficulty) *
                math.pow(stability, -weights[9]).toDouble() *
                (math.exp((1 - retrievability) * weights[10]) - 1) *
                hardPenalty *
                easyBonus);
  }

  /// S'_f（遗忘）：min(w[11]·D^-w[12]·((S+1)^w[13]-1)·e^((1-R)·w[14]),
  /// S / e^(w[17]·w[18]))——长期遗忘稳定性与短期遗忘稳定性取较小者。
  double nextForgetStability({
    required double difficulty,
    required double stability,
    required double retrievability,
  }) {
    final longTerm = weights[11] *
        math.pow(difficulty, -weights[12]).toDouble() *
        (math.pow(stability + 1, weights[13]).toDouble() - 1) *
        math.exp((1 - retrievability) * weights[14]);
    final shortTerm = stability / math.exp(weights[17] * weights[18]);
    return math.min(longTerm, shortTerm);
  }

  /// S'_s（短期稳定性）：S·e^(w[17]·(rating-3+w[18]))，用于距上次复习不足 1 天的评分。
  double shortTermStability(double stability, Rating rating) =>
      stability * math.exp(weights[17] * (rating.value - 3 + weights[18]));

  /// 更新后的稳定性分派：Again → 遗忘稳定性；Hard/Good/Easy → 回忆稳定性。
  double nextStability({
    required double difficulty,
    required double stability,
    required double retrievability,
    required Rating rating,
  }) {
    if (rating == Rating.again) {
      return nextForgetStability(
        difficulty: difficulty,
        stability: stability,
        retrievability: retrievability,
      );
    }
    return nextRecallStability(
      difficulty: difficulty,
      stability: stability,
      retrievability: retrievability,
      rating: rating,
    );
  }

  /// I = round(S/FACTOR·(DR^(1/DECAY)-1))，钳制 [1, maximumIntervalDays]（整日）。
  ///
  /// 舍入采用 Python `round()` 语义（见 [roundHalfEven]）；DR=0.9 时约等于 round(S)。
  int nextInterval(
    double stability, {
    required double desiredRetention,
    required int maximumIntervalDays,
  }) {
    final raw = stability /
        kFsrs5Factor *
        (math.pow(desiredRetention, 1 / kFsrs5Decay).toDouble() - 1);
    return roundHalfEven(raw).clamp(1, maximumIntervalDays);
  }
}

/// 官方 fuzz：对 ≥2.5 天的复习间隔在 [min, max] 内随机取整日
/// （py-fsrs v5.1.3 `_get_fuzzed_interval`）。
///
/// [random] 由调用方注入以支持确定性测试；本项目默认关闭 fuzz（TECH_DOC §7.4）。
int fuzzInterval(
  int intervalDays, {
  required math.Random random,
  required int maximumIntervalDays,
}) {
  if (intervalDays < 2.5) {
    return intervalDays;
  }
  var delta = 1.0;
  for (final range in kFsrs5FuzzRanges) {
    delta += range.factor *
        math.max(math.min(intervalDays.toDouble(), range.end) - range.start, 0.0);
  }
  var minIvl = roundHalfEven(intervalDays - delta);
  if (minIvl < 2) {
    minIvl = 2;
  }
  var maxIvl = roundHalfEven(intervalDays + delta);
  if (maxIvl > maximumIntervalDays) {
    maxIvl = maximumIntervalDays;
  }
  if (minIvl > maxIvl) {
    minIvl = maxIvl;
  }
  final fuzzed = roundHalfEven(random.nextDouble() * (maxIvl - minIvl + 1) + minIvl);
  return fuzzed > maximumIntervalDays ? maximumIntervalDays : fuzzed;
}
