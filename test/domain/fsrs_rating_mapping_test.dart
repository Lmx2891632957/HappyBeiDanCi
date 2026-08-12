/// FSRS 引擎评分映射用例：TD-05 配置（learning/relearning steps=[10m]，
/// desired retention=0.9）下的新词/学习词评分结果，以及官方双步骤学习行为。
/// 参考值由官方 py-fsrs v5.1.3 全精度生成。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/domain/models/user_word.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs/fsrs_engine.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs_scheduler.dart';

void main() {
  // TD-05 默认配置引擎。
  FsrsEngine defaultEngine() => FsrsEngine(
        parameters: const FsrsParameters(
          learningStepsMinutes: [10],
          relearningStepsMinutes: [10],
          enableFuzzing: false,
        ),
      );

  DateTime start() => DateTime.utc(2022, 11, 29, 12, 30);

  group('评分映射（TD-05：单步 [10m]）', () {
    test('新词 Again → 留在 Learning，+10 分钟，初始化 S/D', () {
      final result = defaultEngine().next(
        const CardState(state: WordLearningState.new_),
        Rating.again,
        now: start(),
      );
      expect(result.card.state, WordLearningState.learning);
      expect(result.card.step, 0);
      expect(result.card.stability, closeTo(0.40255, 1e-6));
      expect(result.card.difficulty, closeTo(7.1949, 1e-6));
      expect(result.card.dueDate, start().add(const Duration(minutes: 10)));
      expect(result.intervalDays, closeTo(10 / 1440, 1e-9));
      expect(result.retrievability, 0.0);
    });

    test('新词 Hard → 留在 Learning，+15 分钟（单步 ×1.5，官方语义）', () {
      final result = defaultEngine().next(
        const CardState(state: WordLearningState.new_),
        Rating.hard,
        now: start(),
      );
      expect(result.card.state, WordLearningState.learning);
      expect(result.card.step, 0);
      expect(result.card.stability, closeTo(1.18385, 1e-6));
      expect(result.card.difficulty, closeTo(6.48830526847, 1e-6));
      expect(result.card.dueDate, start().add(const Duration(minutes: 15)));
    });

    test('新词 Good → 毕业为 Review，间隔约 3 天', () {
      final result = defaultEngine().next(
        const CardState(state: WordLearningState.new_),
        Rating.good,
        now: start(),
      );
      expect(result.card.state, WordLearningState.review);
      expect(result.card.step, isNull);
      expect(result.card.stability, closeTo(3.173, 1e-6));
      expect(result.card.difficulty, closeTo(5.28243442232, 1e-6));
      expect(result.card.dueDate, start().add(const Duration(days: 3)));
      expect(result.intervalDays, closeTo(3, 1e-9));
    });

    test('新词 Easy → 直接毕业为 Review，间隔约 16 天', () {
      final result = defaultEngine().next(
        const CardState(state: WordLearningState.new_),
        Rating.easy,
        now: start(),
      );
      expect(result.card.state, WordLearningState.review);
      expect(result.card.step, isNull);
      expect(result.card.stability, closeTo(15.69105, 1e-6));
      expect(result.card.difficulty, closeTo(3.22450158937, 1e-6));
      expect(result.card.dueDate, start().add(const Duration(days: 16)));
    });

    test('学习中的词评 Good（单步最后一步）→ 毕业为 Review', () {
      final engine = defaultEngine();
      final learning = engine
          .next(const CardState(state: WordLearningState.new_), Rating.again, now: start())
          .card;
      expect(learning.state, WordLearningState.learning);

      final result = engine.next(learning, Rating.good, now: start());
      expect(result.card.state, WordLearningState.review);
      expect(result.card.step, isNull);
    });
  });

  group('官方学习步骤行为（双步骤 1m/10m）', () {
    FsrsEngine twoStepEngine() => FsrsEngine(
          parameters: const FsrsParameters(
            learningStepsMinutes: [1, 10],
            relearningStepsMinutes: [10],
            enableFuzzing: false,
          ),
        );

    test('Again 重置步骤，间隔 = 第一步（1 分钟）', () {
      final result = twoStepEngine().next(
        const CardState(state: WordLearningState.new_),
        Rating.again,
        now: start(),
      );
      expect(result.card.state, WordLearningState.learning);
      expect(result.card.step, 0);
      expect(result.card.dueDate, start().add(const Duration(minutes: 1)));
    });

    test('Hard 保持步骤，间隔 = 前两步均值（5.5 分钟）', () {
      final result = twoStepEngine().next(
        const CardState(state: WordLearningState.new_),
        Rating.hard,
        now: start(),
      );
      expect(result.card.state, WordLearningState.learning);
      expect(result.card.step, 0);
      expect(result.card.dueDate, start().add(const Duration(minutes: 5, seconds: 30)));
    });

    test('Good 逐步推进：第一步 → 第二步 → 毕业为 Review', () {
      final engine = twoStepEngine();
      final r1 = engine.next(
        const CardState(state: WordLearningState.new_),
        Rating.good,
        now: start(),
      );
      expect(r1.card.state, WordLearningState.learning);
      expect(r1.card.step, 1);
      expect(r1.card.dueDate, start().add(const Duration(minutes: 10)));

      final r2 = engine.next(r1.card, Rating.good, now: r1.card.dueDate!);
      expect(r2.card.state, WordLearningState.review);
      expect(r2.card.step, isNull);
      expect(r2.intervalDays, greaterThanOrEqualTo(1));
    });

    test('Easy 跳过步骤直接毕业，间隔 ≥ 1 天', () {
      final result = twoStepEngine().next(
        const CardState(state: WordLearningState.new_),
        Rating.easy,
        now: start(),
      );
      expect(result.card.state, WordLearningState.review);
      expect(result.card.step, isNull);
      expect(result.intervalDays, greaterThanOrEqualTo(1));
    });

    test('学习卡步骤超出当前步骤数（官方边缘情况）→ Good 毕业', () {
      // 卡片此前由更多步骤的配置调度（step=1），当前仅配置 [10m]。
      final engine = defaultEngine();
      final card = CardState(
        state: WordLearningState.learning,
        step: 1,
        stability: 3.173,
        difficulty: 5.28243442232,
        lastReviewAt: start(),
      );
      final result = engine.next(card, Rating.good, now: start());
      expect(result.card.state, WordLearningState.review);
      expect(result.card.step, isNull);
    });
  });

}
