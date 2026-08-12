/// 每日计划计算器单测：常规模式各字段与边界（TECH_DOC §6.1）。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/domain/models/user_word.dart';
import 'package:happy_bei_dan_ci/domain/services/default_daily_plan_calculator.dart';

void main() {
  final todayStart = DateTime(2026, 8, 12);

  UserWord dueWord({
    required int wordId,
    required DateTime dueDate,
    double stability = 0,
  }) {
    return UserWord(
      wordbookId: 1,
      wordId: wordId,
      state: WordLearningState.review,
      status: WordStatus.review,
      dueDate: dueDate,
      stability: stability,
    );
  }

  List<UserWord> sampleDueWords(int count) {
    return List.generate(count, (i) {
      return dueWord(
        wordId: i + 1,
        // wordId 越小逾期越久，便于断言“队列即排序前 N 个”。
        dueDate: DateTime(2026, 8, 8, 10).add(Duration(days: i)),
      );
    });
  }

  const calculator = DefaultDailyPlanCalculator();

  group('常规模式', () {
    test('各字段按公式计算且复习队列已排序', () {
      final dueWords = sampleDueWords(5);
      final plan = calculator.calculate(
        dailyGoal: 20,
        remainingNewWords: 50,
        dueWords: dueWords,
        cap: 3,
        todayStart: todayStart,
      );
      expect(plan.newWordCount, 20);
      expect(plan.reviewCount, 3);
      expect(plan.deferredCount, 2);
      // 复习队列为排序后最优先的 3 个（wordId 升序即逾期天数降序）。
      expect(
        plan.reviewQueue.map((word) => word.wordId),
        [1, 2, 3],
      );
    });

    test('新词数受词书剩余新词数限制', () {
      final plan = calculator.calculate(
        dailyGoal: 20,
        remainingNewWords: 5,
        dueWords: const [],
        todayStart: todayStart,
      );
      expect(plan.newWordCount, 5);
    });

    test('复习数受 cap 限制，cap 关闭时全部计入', () {
      final dueWords = sampleDueWords(30);
      final capped = calculator.calculate(
        dailyGoal: 20,
        remainingNewWords: 50,
        dueWords: dueWords,
        cap: 10,
        todayStart: todayStart,
      );
      expect(capped.reviewCount, 10);
      expect(capped.deferredCount, 20);

      final uncapped = calculator.calculate(
        dailyGoal: 20,
        remainingNewWords: 50,
        dueWords: dueWords,
        cap: null,
        todayStart: todayStart,
      );
      expect(uncapped.reviewCount, 30);
      expect(uncapped.deferredCount, 0);
    });

    test('顺延数 = 到期词数 - 复习数', () {
      final dueWords = sampleDueWords(7);
      final plan = calculator.calculate(
        dailyGoal: 20,
        remainingNewWords: 50,
        dueWords: dueWords,
        cap: 4,
        todayStart: todayStart,
      );
      expect(plan.deferredCount, dueWords.length - plan.reviewCount);
    });
  });

  group('边界', () {
    test('到期队列为空：复习数与顺延数均为 0', () {
      final plan = calculator.calculate(
        dailyGoal: 20,
        remainingNewWords: 50,
        dueWords: const [],
        todayStart: todayStart,
      );
      expect(plan.newWordCount, 20);
      expect(plan.reviewCount, 0);
      expect(plan.deferredCount, 0);
    });

    test('词书剩余新词为 0：新词数为 0', () {
      final plan = calculator.calculate(
        dailyGoal: 20,
        remainingNewWords: 0,
        dueWords: sampleDueWords(3),
        todayStart: todayStart,
      );
      expect(plan.newWordCount, 0);
      expect(plan.reviewCount, 3);
    });

    test('cap 为 0：复习数为 0，全部顺延', () {
      final plan = calculator.calculate(
        dailyGoal: 20,
        remainingNewWords: 50,
        dueWords: sampleDueWords(5),
        cap: 0,
        todayStart: todayStart,
      );
      expect(plan.reviewCount, 0);
      expect(plan.deferredCount, 5);
    });

    test('负数输入拒绝', () {
      expect(
        () => calculator.calculate(
          dailyGoal: -1,
          remainingNewWords: 10,
          dueWords: const [],
          todayStart: todayStart,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculator.calculate(
          dailyGoal: 10,
          remainingNewWords: -1,
          dueWords: const [],
          todayStart: todayStart,
        ),
        throwsArgumentError,
      );
    });
  });
}
