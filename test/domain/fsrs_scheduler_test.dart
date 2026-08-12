/// FSRS 引擎产品行为用例：TD-05 配置（learning/relearning steps=[10m]，
/// desired retention=0.9）下的评分映射、状态转移、Relearning 流程与
/// elapsed_days 边界；参考值由官方 py-fsrs v5.1.3 全精度生成。
library;

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/domain/models/user_word.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs/fsrs_engine.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs/fsrs_formulas.dart';
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

  group('复习词评分与 Relearning 流程（TD-05）', () {
    test('毕业后的连续 Good 正常推进间隔', () {
      final engine = defaultEngine();
      var now = start();
      var card = engine.next(
        const CardState(state: WordLearningState.new_),
        Rating.good,
        now: now,
      ).card;
      now = card.dueDate!;

      final good1 = engine.next(card, Rating.good, now: now);
      expect(good1.card.stability, closeTo(10.7389258461, 1e-6));
      expect(good1.card.difficulty, closeTo(5.27296793129, 1e-6));
      expect(good1.intervalDays, closeTo(11, 1e-9));
      expect(good1.retrievability, closeTo(0.904698210889, 1e-6));

      now = good1.card.dueDate!;
      final good2 = engine.next(good1.card, Rating.good, now: now);
      expect(good2.card.stability, closeTo(34.5776235006, 1e-6));
      expect(good2.intervalDays, closeTo(35, 1e-9));

      now = good2.card.dueDate!;
      final good3 = engine.next(good2.card, Rating.good, now: now);
      expect(good3.card.stability, closeTo(100.748312852, 1e-6));
      expect(good3.intervalDays, closeTo(101, 1e-9));
    });

    test('Review 评 Again → 进入 Relearning，+10 分钟；再 Again 重置步骤', () {
      final engine = defaultEngine();
      var now = start();
      var card = engine.next(
        const CardState(state: WordLearningState.new_),
        Rating.good,
        now: now,
      ).card;
      now = card.dueDate!;
      card = engine.next(card, Rating.good, now: now).card;
      now = card.dueDate!;
      card = engine.next(card, Rating.good, now: now).card;
      now = card.dueDate!;
      card = engine.next(card, Rating.good, now: now).card;
      now = card.dueDate!;

      final again = engine.next(card, Rating.again, now: now);
      expect(again.card.state, WordLearningState.relearning);
      expect(again.card.step, 0);
      expect(again.card.stability, closeTo(5.94295756461, 1e-6));
      expect(again.card.difficulty, closeTo(6.77792562457, 1e-6));
      expect(again.card.dueDate, now.add(const Duration(minutes: 10)));

      final again2 = engine.next(again.card, Rating.again, now: again.card.dueDate!);
      expect(again2.card.state, WordLearningState.relearning);
      expect(again2.card.step, 0);
      expect(again2.card.stability, closeTo(2.977591257943105, 1e-6));
      expect(again2.card.difficulty, closeTo(7.802440326843958, 1e-6));
    });

    test('Relearning 评 Good → 毕业为 Review，间隔按稳定性（约 3 天）', () {
      final engine = defaultEngine();
      var now = start();
      var card = engine.next(
        const CardState(state: WordLearningState.new_),
        Rating.good,
        now: now,
      ).card;
      now = card.dueDate!;
      card = engine.next(card, Rating.good, now: now).card;
      now = card.dueDate!;
      card = engine.next(card, Rating.good, now: now).card;
      now = card.dueDate!;
      card = engine.next(card, Rating.again, now: now).card;
      now = card.dueDate!;
      card = engine.next(card, Rating.again, now: now).card;
      now = card.dueDate!;

      final good = engine.next(card, Rating.good, now: now);
      expect(good.card.state, WordLearningState.review);
      expect(good.card.step, isNull);
      expect(good.card.stability, closeTo(2.69308638106, 1e-6));
      expect(good.card.difficulty, closeTo(7.78560251419, 1e-6));
      expect(good.card.dueDate, now.add(const Duration(days: 3)));
    });

    test('Relearning 评 Hard 保持步骤不变，+15 分钟；Easy 直接毕业', () {
      final engine = defaultEngine();
      var now = start();
      var card = engine.next(
        const CardState(state: WordLearningState.new_),
        Rating.good,
        now: now,
      ).card;
      now = card.dueDate!;
      card = engine.next(card, Rating.good, now: now).card;
      now = card.dueDate!;
      card = engine.next(card, Rating.good, now: now).card;
      now = card.dueDate!;
      card = engine.next(card, Rating.good, now: now).card;
      now = card.dueDate!;
      card = engine.next(card, Rating.again, now: now).card;
      now = card.dueDate!;

      final hard = engine.next(card, Rating.hard, now: now);
      expect(hard.card.state, WordLearningState.relearning);
      expect(hard.card.step, 0);
      expect(hard.card.stability, closeTo(4.99114164895, 1e-6));
      expect(hard.card.dueDate, now.add(const Duration(minutes: 15)));

      final easy = engine.next(hard.card, Rating.easy, now: hard.card.dueDate!);
      expect(easy.card.state, WordLearningState.review);
      expect(easy.card.step, isNull);
      expect(easy.card.stability, closeTo(11.7778709308, 1e-6));
      expect(easy.card.difficulty, closeTo(6.82433518038, 1e-6));
      expect(easy.intervalDays, closeTo(12, 1e-9));
    });
  });

  group('elapsed_days 边界（官方按整天数判定短期/长期）', () {
    // 构造一个已毕业且复习过一次的 Review 卡（s=10.7389，d=5.2729，due 距上次复习 11 天）。
    ({CardState card, DateTime due}) reviewCard(DateTime now) {
      final engine = defaultEngine();
      final card = engine.next(
        const CardState(state: WordLearningState.new_),
        Rating.good,
        now: now,
      ).card;
      final good = engine.next(card, Rating.good, now: card.dueDate!);
      return (card: good.card, due: good.card.dueDate!);
    }

    test('到期日评分（elapsed=11 天）→ 长期更新', () {
      final now = start();
      final setup = reviewCard(now);
      final result = defaultEngine().next(setup.card, Rating.good, now: setup.due);
      expect(result.card.stability, closeTo(34.5776235006, 1e-6));
      expect(result.card.difficulty, closeTo(5.26354498611, 1e-6));
      expect(result.intervalDays, closeTo(35, 1e-9));
    });

    test('逾期 1 天（elapsed=12）→ 长期更新，间隔随保持率降低而增长', () {
      final now = start();
      final setup = reviewCard(now);
      final result = defaultEngine().next(
        setup.card,
        Rating.good,
        now: setup.due.add(const Duration(days: 1)),
      );
      expect(result.card.stability, closeTo(36.5043259438, 1e-6));
      expect(result.intervalDays, closeTo(37, 1e-9));
    });

    test('逾期 23 小时（elapsed 向下取整仍为 11）→ 与到期日评分结果一致', () {
      final now = start();
      final setup = reviewCard(now);
      final result = defaultEngine().next(
        setup.card,
        Rating.good,
        now: setup.due.add(const Duration(hours: 23)),
      );
      expect(result.card.stability, closeTo(34.5776235006, 1e-6));
      expect(result.intervalDays, closeTo(35, 1e-9));
    });

    test('不足 1 天（elapsed=0）→ 短期稳定性更新', () {
      final engine = defaultEngine();
      var now = start();
      var card = engine.next(
        const CardState(state: WordLearningState.new_),
        Rating.good,
        now: now,
      ).card;
      now = card.dueDate!;
      card = engine.next(card, Rating.good, now: now).card;
      now = card.dueDate!;
      card = engine.next(card, Rating.good, now: now).card;
      now = card.dueDate!;
      card = engine.next(card, Rating.again, now: now).card;
      now = card.dueDate!;

      // Relearning 10 分钟后评分：elapsed=0 → 短期更新（s 按 e^(w17*(r-3+w18)) 缩放）。
      final result = engine.next(card, Rating.good, now: now);
      expect(result.retrievability, closeTo(1.0, 1e-9));
      expect(result.card.state, WordLearningState.review);
    });
  });

  group('计数器与参数边界（Anki 口径扩展 + 官方边界）', () {
    test('reps 每次评分 +1；Review 评 Again 时 lapses +1', () {
      final engine = defaultEngine();
      var now = start();
      var card = const CardState(state: WordLearningState.new_);

      final first = engine.next(card, Rating.good, now: now);
      expect(first.card.reps, 1);
      expect(first.card.lapses, 0);
      now = first.card.dueDate!;

      final second = engine.next(first.card, Rating.good, now: now);
      expect(second.card.reps, 2);
      expect(second.card.lapses, 0);
      now = second.card.dueDate!;

      final again = engine.next(second.card, Rating.again, now: now);
      expect(again.card.reps, 3);
      expect(again.card.lapses, 1);

      final again2 = engine.next(again.card, Rating.again, now: again.card.dueDate!);
      expect(again2.card.reps, 4);
      expect(again2.card.lapses, 1);
    });

    test('新词学习中的 Again 不增加 lapses', () {
      final engine = defaultEngine();
      final result = engine.next(
        const CardState(state: WordLearningState.new_),
        Rating.again,
        now: start(),
      );
      expect(result.card.lapses, 0);
    });

    test('maximumIntervalDays 生效（间隔不超过上限）', () {
      final engine = FsrsEngine(
        parameters: const FsrsParameters(
          learningStepsMinutes: [10],
          relearningStepsMinutes: [10],
          maximumIntervalDays: 100,
          enableFuzzing: false,
        ),
      );
      var now = start();
      var card = const CardState(state: WordLearningState.new_);
      for (var i = 0; i < 6; i++) {
        final result = engine.next(card, Rating.easy, now: now);
        expect(result.card.dueDate!.difference(now).inDays, lessThanOrEqualTo(100));
        card = result.card;
        now = card.dueDate!;
      }
    });

    test('无学习步骤：新词 Again 直接毕业为 Review，间隔 ≥ 1 天', () {
      final engine = FsrsEngine(
        parameters: const FsrsParameters(
          learningStepsMinutes: [],
          relearningStepsMinutes: [10],
          enableFuzzing: false,
        ),
      );
      final result = engine.next(
        const CardState(state: WordLearningState.new_),
        Rating.again,
        now: start(),
      );
      expect(result.card.state, WordLearningState.review);
      expect(result.intervalDays, greaterThanOrEqualTo(1));
    });

    test('无重学步骤：Review 评 Again 保持 Review，间隔 ≥ 1 天', () {
      final engine = FsrsEngine(
        parameters: const FsrsParameters(
          learningStepsMinutes: [10],
          relearningStepsMinutes: [],
          enableFuzzing: false,
        ),
      );
      var now = start();
      var card = engine.next(
        const CardState(state: WordLearningState.new_),
        Rating.good,
        now: now,
      ).card;
      now = card.dueDate!;
      final again = engine.next(card, Rating.again, now: now);
      expect(again.card.state, WordLearningState.review);
      expect(again.intervalDays, greaterThanOrEqualTo(1));
    });
  });

  group('fuzz（官方区间算法，默认关闭；注入 Random 确定性验证）', () {
    test('小于 2.5 天的间隔不参与 fuzz', () {
      final result = fuzzInterval(
        2,
        random: math.Random(42),
        maximumIntervalDays: 36500,
      );
      expect(result, 2);
    });

    test('fuzz 结果落在官方 [min, max] 区间内', () {
      for (final interval in [3, 7, 14, 30, 60, 100, 365]) {
        final random = math.Random(interval);
        // 官方 delta 计算：1 + 各区间比例增量。
        var delta = 1.0;
        final ranges = [
          (start: 2.5, end: 7.0, factor: 0.15),
          (start: 7.0, end: 20.0, factor: 0.1),
          (start: 20.0, end: double.infinity, factor: 0.05),
        ];
        for (final range in ranges) {
          delta += range.factor *
              math.max(math.min(interval.toDouble(), range.end) - range.start, 0.0);
        }
        final minIvl = math.max(2, roundHalfEven(interval - delta));
        final maxIvl = math.min(roundHalfEven(interval + delta), 36500);
        for (var i = 0; i < 20; i++) {
          final fuzzed = fuzzInterval(
            interval,
            random: random,
            maximumIntervalDays: 36500,
          );
          // 官方 round 语义下随机值上界为开区间 [min, max+1)，输出可能为 max+1。
          expect(fuzzed, inInclusiveRange(minIvl, maxIvl + 1));
        }
      }
    });

    test('引擎开启 fuzz 时仅作用于 Review 间隔，学习步骤不受影响', () {
      final engine = FsrsEngine(
        parameters: const FsrsParameters(
          learningStepsMinutes: [10],
          relearningStepsMinutes: [10],
          enableFuzzing: true,
        ),
        random: math.Random(7),
      );
      final now = start();
      final again = engine.next(
        const CardState(state: WordLearningState.new_),
        Rating.again,
        now: now,
      );
      // Learning 步骤间隔不 fuzz，精确 +10 分钟。
      expect(again.card.dueDate, now.add(const Duration(minutes: 10)));

      final good = engine.next(
        const CardState(state: WordLearningState.new_),
        Rating.good,
        now: now,
      );
      // 毕业后的 Review 间隔在官方 fuzz 区间内（原间隔 3 天，delta=1.075 → [2,4]）。
      expect(
        good.card.dueDate!.difference(now).inDays,
        inInclusiveRange(2, 5),
      );
    });
  });
}
