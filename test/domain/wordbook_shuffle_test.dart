/// 乱序生成器单元测试（TECH_DOC §8.3 / TD-06）：
/// 种子确定性、排列合法性、同种子跨调用稳定、不同种子可区分、golden 防回归。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/domain/services/wordbook_shuffle.dart';

void main() {
  group('WordbookShuffle.seedFor（seed = hash(wordbookId, 安装时间)）', () {
    final install = DateTime.fromMillisecondsSinceEpoch(1_750_000_000_000);

    test('同输入恒同种子；不同安装时间/词书产生不同种子', () {
      final a = WordbookShuffle.seedFor(wordbookId: 1, installTime: install);
      final b = WordbookShuffle.seedFor(wordbookId: 1, installTime: install);
      expect(a, b);
      expect(
        WordbookShuffle.seedFor(wordbookId: 2, installTime: install),
        isNot(a),
      );
      expect(
        WordbookShuffle.seedFor(
          wordbookId: 1,
          installTime: install.add(const Duration(days: 1)),
        ),
        isNot(a),
      );
    });

    test('golden：固定词书与安装时间的种子值（防实现漂移）', () {
      expect(
        WordbookShuffle.seedFor(wordbookId: 1, installTime: install),
        1598937845,
      );
    });
  });

  group('WordbookShuffle.ranks（Fisher–Yates + xorshift32）', () {
    test('同 seed 与词数跨调用稳定', () {
      final first = WordbookShuffle.ranks(42, 50);
      final second = WordbookShuffle.ranks(42, 50);
      expect(first, second);
    });

    test('结果是 0..count-1 的排列（无重复无遗漏）', () {
      for (final count in [0, 1, 2, 3, 8, 100, 3677]) {
        for (final seed in [0, 1, 42, 0x7fffffff]) {
          final ranks = WordbookShuffle.ranks(seed, count);
          expect(ranks, hasLength(count));
          expect(ranks.toSet(), {for (var i = 0; i < count; i++) i});
        }
      }
    });

    test('不同 seed 产生不同排列（至少所取样例两两不同）', () {
      final orders = [
        for (final seed in [1, 2, 3, 4, 5])
          WordbookShuffle.ranks(seed, 50).join(','),
      ];
      expect(orders.toSet(), hasLength(orders.length));
    });

    test('非平凡规模下乱序不等于原序（修复"首卡全是 a 开头"的关键断言）', () {
      for (final seed in [1, 2, 3, 42, 0x9e3779b9]) {
        final ranks = WordbookShuffle.ranks(seed, 100);
        expect(ranks, isNot([for (var i = 0; i < 100; i++) i]));
      }
    });

    test('golden：固定 seed 与词数的排列（防算法实现漂移）', () {
      expect(
        WordbookShuffle.ranks(42, 10),
        [5, 1, 6, 9, 4, 0, 3, 8, 7, 2],
      );
    });
  });
}
