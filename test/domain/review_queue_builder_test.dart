/// 复习队列构建器单测：三键排序、软上限截断与顺延语义（TECH_DOC §6.2）。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/domain/models/user_word.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/default_review_queue_builder.dart';

void main() {
  // “今日零点”由调用方按调度时区（默认 Asia/Shanghai）换算后传入，测试直接用
  // 本地日界构造，纯算术与真实时区无关。
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

  List<int> wordIds(List<UserWord> queue) =>
      queue.map((word) => word.wordId).toList();

  const builder = DefaultReviewQueueBuilder();

  group('三键排序', () {
    test('overdueDays 降序：逾期越久越靠前', () {
      final words = [
        dueWord(wordId: 1, dueDate: DateTime(2026, 8, 12, 10)), // -1
        dueWord(wordId: 2, dueDate: DateTime(2026, 8, 9, 10)), // 2
        dueWord(wordId: 3, dueDate: DateTime(2026, 8, 10, 23)), // 1
      ];
      final queue = builder.build(words, todayStart: todayStart);
      expect(wordIds(queue), [2, 3, 1]);
    });

    test('stability 升序：同日到期时不稳定词优先', () {
      final words = [
        dueWord(wordId: 1, dueDate: DateTime(2026, 8, 9, 10), stability: 20),
        dueWord(wordId: 2, dueDate: DateTime(2026, 8, 9, 10), stability: 5),
        dueWord(wordId: 3, dueDate: DateTime(2026, 8, 9, 10), stability: 12),
      ];
      final queue = builder.build(words, todayStart: todayStart);
      expect(wordIds(queue), [2, 3, 1]);
    });

    test('word_id 升序：同桶同 stability 时按 id 确定性排序', () {
      final words = [
        dueWord(wordId: 30, dueDate: DateTime(2026, 8, 11, 10), stability: 8),
        dueWord(wordId: 7, dueDate: DateTime(2026, 8, 11, 10), stability: 8),
        dueWord(wordId: 12, dueDate: DateTime(2026, 8, 11, 10), stability: 8),
      ];
      final queue = builder.build(words, todayStart: todayStart);
      expect(wordIds(queue), [7, 12, 30]);
    });

    test('三键联动且结果与输入顺序无关（确定性）', () {
      final words = [
        dueWord(wordId: 6, dueDate: DateTime(2026, 8, 12, 10)), // -1，与 5 同桶
        dueWord(wordId: 1, dueDate: DateTime(2026, 8, 8, 10), stability: 10), // 3
        dueWord(wordId: 4, dueDate: DateTime(2026, 8, 11, 23)), // 0
        dueWord(wordId: 2, dueDate: DateTime(2026, 8, 8, 10), stability: 5), // 3
        dueWord(wordId: 5, dueDate: DateTime(2026, 8, 12, 10)), // -1
        dueWord(wordId: 3, dueDate: DateTime(2026, 8, 9, 10), stability: 1), // 2
      ];
      const expected = [2, 1, 3, 4, 5, 6];
      expect(wordIds(builder.build(words, todayStart: todayStart)), expected);
      // 输入乱序不影响输出，保证队列确定性。
      expect(
        wordIds(builder.build(words.reversed.toList(), todayStart: todayStart)),
        expected,
      );
    });

    test('同日到期与逾期多天混合时最逾期优先', () {
      final words = [
        dueWord(wordId: 1, dueDate: DateTime(2026, 8, 12, 9)), // 今日到期
        dueWord(wordId: 2, dueDate: DateTime(2026, 8, 9, 9)), // 逾期 2 天
        dueWord(wordId: 3, dueDate: DateTime(2026, 8, 11, 9)), // 昨日到期（0 桶）
      ];
      final queue = builder.build(words, todayStart: todayStart);
      expect(wordIds(queue), [2, 3, 1]);
    });
  });

  group('软上限与顺延', () {
    test('截断数量正确且保留排序后的最优先部分', () {
      final words = [
        dueWord(wordId: 1, dueDate: DateTime(2026, 8, 12, 10)),
        dueWord(wordId: 2, dueDate: DateTime(2026, 8, 8, 10)),
        dueWord(wordId: 3, dueDate: DateTime(2026, 8, 9, 10)),
        dueWord(wordId: 4, dueDate: DateTime(2026, 8, 10, 10)),
        dueWord(wordId: 5, dueDate: DateTime(2026, 8, 11, 10)),
      ];
      final queue = builder.build(words, cap: 2, todayStart: todayStart);
      expect(wordIds(queue), [2, 3]);
    });

    test('输入列表与顺延词 due_date 均不被修改', () {
      final words = [
        dueWord(wordId: 1, dueDate: DateTime(2026, 8, 12, 10)),
        dueWord(wordId: 2, dueDate: DateTime(2026, 8, 9, 10)),
        dueWord(wordId: 3, dueDate: DateTime(2026, 8, 11, 10)),
      ];
      final before = words.map((word) => word.dueDate).toList();
      final queue = builder.build(words, cap: 1, todayStart: todayStart);
      expect(queue, hasLength(1));
      // 原列表未被重排或改写，顺延词保持原 due_date（无惩罚语义）。
      expect(words.map((word) => word.dueDate), before);
      expect(words.map((word) => word.wordId), [1, 2, 3]);
    });

    test('次日构建时被顺延的词自然排在新到期词之前', () {
      // 第 1 天：A 逾期 1 天、B 今日到期，cap=1 只取 A，B 顺延。
      final day1Words = [
        dueWord(wordId: 1, dueDate: DateTime(2026, 8, 10, 10)), // A
        dueWord(wordId: 2, dueDate: DateTime(2026, 8, 12, 10)), // B
      ];
      final day1Queue =
          builder.build(day1Words, cap: 1, todayStart: DateTime(2026, 8, 12));
      expect(wordIds(day1Queue), [1]);

      // 第 2 天加入今日新到期词 C：A(2 天) > B(0 天) > C(-1)，B 自然居前。
      final day2Words = [
        ...day1Words,
        dueWord(wordId: 3, dueDate: DateTime(2026, 8, 13, 10)), // C
      ];
      final day2Queue =
          builder.build(day2Words, todayStart: DateTime(2026, 8, 13));
      expect(wordIds(day2Queue), [1, 2, 3]);
    });
  });

  group('边界', () {
    test('cap 为 null 表示关闭：不截断，全部返回', () {
      final words = [
        dueWord(wordId: 1, dueDate: DateTime(2026, 8, 12, 10)),
        dueWord(wordId: 2, dueDate: DateTime(2026, 8, 9, 10)),
      ];
      final queue = builder.build(words, cap: null, todayStart: todayStart);
      expect(wordIds(queue), [2, 1]);
    });

    test('空队列返回空列表', () {
      expect(builder.build(const [], todayStart: todayStart), isEmpty);
    });

    test('cap 为 0 时全部顺延', () {
      final words = [
        dueWord(wordId: 1, dueDate: DateTime(2026, 8, 12, 10)),
        dueWord(wordId: 2, dueDate: DateTime(2026, 8, 9, 10)),
      ];
      expect(builder.build(words, cap: 0, todayStart: todayStart), isEmpty);
    });

    test('负数 cap 拒绝', () {
      expect(
        () => builder.build(const [], cap: -1, todayStart: todayStart),
        throwsArgumentError,
      );
    });
  });
}
