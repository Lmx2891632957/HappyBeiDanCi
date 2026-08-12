/// 官方 FSRS-5 golden 用例（移植自 open-spaced-repetition/py-fsrs v5.1.3
/// `tests/test_basic.py`，参考值由官方实现全精度生成，断言容差 1e-6）。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/domain/models/user_word.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs/fsrs_engine.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs_scheduler.dart';

/// 官方参数 w[0..18]（py-fsrs v5.1.3 DEFAULT_PARAMETERS）。
const List<double> _parameters2 = [
  0.1456, 0.4186, 1.1104, 4.1315, 5.2417, 1.3098, 0.8975, 0.0, 1.5674,
  0.0567, 0.9661, 2.0275, 0.1592, 0.2446, 1.5071, 0.2272, 2.8755, 1.234,
  5.6789,
];

void main() {
  group('官方 golden：review_card 序列（默认双学习步骤 1m/10m，无 fuzz）', () {
    const ratings = [
      Rating.good, Rating.good, Rating.good, Rating.good, Rating.good,
      Rating.good, Rating.again, Rating.again, Rating.good, Rating.good,
      Rating.good, Rating.good, Rating.good,
    ];

    // 每步参考值：状态、步骤、稳定性、难度、间隔（天）、retrievability、到期时间。
    const expected = [
      (state: WordLearningState.learning, step: 1, s: 3.173, d: 5.28243442232, ivl: 0, r: 0.0, due: '2022-11-29T12:40:00.000Z'),
      (state: WordLearningState.review, step: null, s: 4.46685806436, d: 5.27296793129, ivl: 4, r: 1.0, due: '2022-12-03T12:40:00.000Z'),
      (state: WordLearningState.review, step: null, s: 14.2172841093, d: 5.26354498611, ivl: 14, r: 0.909071448293, due: '2022-12-17T12:40:00.000Z'),
      (state: WordLearningState.review, step: null, s: 43.7250940622, d: 5.25416538649, ivl: 44, r: 0.901309557355, due: '2023-01-30T12:40:00.000Z'),
      (state: WordLearningState.review, step: null, s: 124.796556046, d: 5.24482893302, ivl: 125, r: 0.899462930359, due: '2023-06-04T12:40:00.000Z'),
      (state: WordLearningState.review, step: null, s: 328.473441009, d: 5.23553542724, ivl: 328, r: 0.899860649854, due: '2024-04-27T12:40:00.000Z'),
      (state: WordLearningState.relearning, step: 0, s: 9.25594891756, d: 6.76539959411, ivl: 0, r: 0.900123259653, due: '2024-04-27T12:50:00.000Z'),
      (state: WordLearningState.relearning, step: 0, s: 4.63749442618, d: 7.79401833102, ivl: 0, r: 1.0, due: '2024-04-27T13:00:00.000Z'),
      (state: WordLearningState.review, step: null, s: 6.52853116168, d: 7.77299855401, ivl: 7, r: 1.0, due: '2024-05-04T13:00:00.000Z'),
      (state: WordLearningState.review, step: null, s: 15.5554680166, d: 7.75207546797, ivl: 16, r: 0.89388829731, due: '2024-05-20T13:00:00.000Z'),
      (state: WordLearningState.review, step: null, s: 34.3624151754, d: 7.73124862813, ivl: 34, r: 0.897566553096, due: '2024-06-23T13:00:00.000Z'),
      (state: WordLearningState.review, step: null, s: 71.1019171291, d: 7.71051759175, ivl: 71, r: 0.900903113057, due: '2024-09-02T13:00:00.000Z'),
      (state: WordLearningState.review, step: null, s: 141.834003976, d: 7.68988191814, ivl: 142, r: 0.900122580307, due: '2025-01-22T13:00:00.000Z'),
    ];

    test('13 次评分逐步匹配官方 S/D/间隔/retrievability/到期时间', () {
      final engine = FsrsEngine(
        parameters: const FsrsParameters(
          learningStepsMinutes: [1, 10],
          relearningStepsMinutes: [10],
          enableFuzzing: false,
        ),
      );
      var card = const CardState(state: WordLearningState.new_);
      var now = DateTime.utc(2022, 11, 29, 12, 30);

      for (var i = 0; i < ratings.length; i++) {
        final result = engine.next(card, ratings[i], now: now);
        final e = expected[i];
        expect(result.card.state, e.state, reason: 'step ${i + 1} state');
        expect(result.card.step, e.step, reason: 'step ${i + 1} step');
        expect(result.card.stability, closeTo(e.s, 1e-6), reason: 'step ${i + 1} S');
        expect(result.card.difficulty, closeTo(e.d, 1e-6), reason: 'step ${i + 1} D');
        // 官方断言口径：间隔取整日（(due - last_review).days）。
        expect(result.card.dueDate!.difference(now).inDays, e.ivl, reason: 'step ${i + 1} interval');
        expect(result.retrievability, closeTo(e.r, 1e-6), reason: 'step ${i + 1} R');
        expect(result.card.dueDate, DateTime.parse(e.due), reason: 'step ${i + 1} due');

        card = result.card;
        now = card.dueDate!;
      }
    });
  });

  group('官方 golden：memo_state 序列（默认 fuzz，S/D 不受 fuzz 影响）', () {
    test('Again×1 + Good×5 后最终 Good 的 S/D 与官方一致', () {
      final engine = FsrsEngine(
        parameters: const FsrsParameters(
          learningStepsMinutes: [1, 10],
          relearningStepsMinutes: [10],
          enableFuzzing: true,
        ),
      );
      const ratings = [
        Rating.again, Rating.good, Rating.good, Rating.good, Rating.good,
        Rating.good,
      ];
      const dayAdvances = [0, 0, 1, 3, 8, 21];

      var card = const CardState(state: WordLearningState.new_);
      var now = DateTime.utc(2022, 11, 29, 12, 30);
      for (var i = 0; i < ratings.length; i++) {
        card = engine.next(card, ratings[i], now: now).card;
        now = now.add(Duration(days: dayAdvances[i]));
      }

      final finalResult = engine.next(card, Rating.good, now: now);
      expect(finalResult.card.stability, closeTo(48.7169595525, 1e-6));
      expect(finalResult.card.difficulty, closeTo(7.08656950569, 1e-6));
      expect(finalResult.retrievability, closeTo(0.895962729952, 1e-6));
      // 官方断言：round(S) == 49，round(D, 4) == 7.0866。
      expect(finalResult.card.stability.round(), 49);
      expect(double.parse(finalResult.card.difficulty.toStringAsFixed(4)), 7.0866);
    });
  });

  group('官方 golden：自定义参数（DR=0.85，权重 w2）', () {
    test('参数写入引擎且完整序列间隔与官方实现一致', () {
      final engine = FsrsEngine(
        parameters: FsrsParameters(
          weights: _parameters2,
          desiredRetention: 0.85,
          maximumIntervalDays: 36500,
          learningStepsMinutes: const [1, 10],
          relearningStepsMinutes: const [10],
          enableFuzzing: false,
        ),
      );
      expect(engine.parameters.weights, _parameters2);
      expect(engine.parameters.desiredRetention, 0.85);
      expect(engine.parameters.maximumIntervalDays, 36500);

      const ratings = [
        Rating.good, Rating.good, Rating.good, Rating.good, Rating.good,
        Rating.good, Rating.again, Rating.again, Rating.good, Rating.good,
        Rating.good, Rating.good, Rating.good,
      ];
      // 官方实现全精度生成的间隔序列（DR=0.85 下快速增长并触顶 36500）。
      const expectedIvls = [0, 2009, 12045, 36500, 36500, 36500, 0, 0, 36500, 36500, 36500, 36500, 36500];
      var card = const CardState(state: WordLearningState.new_);
      var now = DateTime.utc(2022, 11, 29, 12, 30);
      for (var i = 0; i < ratings.length; i++) {
        final result = engine.next(card, ratings[i], now: now);
        expect(result.card.dueDate!.difference(now).inDays, expectedIvls[i]);
        card = result.card;
        now = card.dueDate!;
      }
    });
  });
}
