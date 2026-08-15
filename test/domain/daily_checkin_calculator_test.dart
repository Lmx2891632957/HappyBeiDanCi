/// 整日任务完成判定单测（TECH_DOC §5.5 打卡口径，AGENTS §7）。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/domain/models/daily_plan.dart';
import 'package:happy_bei_dan_ci/domain/models/daily_stats.dart';
import 'package:happy_bei_dan_ci/domain/models/user_word.dart';
import 'package:happy_bei_dan_ci/domain/services/daily_checkin_calculator.dart';

void main() {
  const plan = DailyPlan(
    newWordCount: 20,
    reviewQueue: [],
    deferredCount: 50,
  );

  DailyStats stats({
    int newCount = 0,
    int reviewCount = 0,
    int completed = 0,
  }) => DailyStats(
    day: '2026-08-12',
    newCount: newCount,
    reviewCount: reviewCount,
    completed: completed,
  );

  test('新词与复习均达成 → 完成', () {
    expect(
      DailyCheckinCalculator.isTodayComplete(
        plan: plan,
        stats: stats(newCount: 20, reviewCount: 30),
      ),
      isTrue,
    );
  });

  test('新词目标未达成 → 未完成', () {
    expect(
      DailyCheckinCalculator.isTodayComplete(
        plan: plan,
        stats: stats(newCount: 19, reviewCount: 30),
      ),
      isFalse,
    );
  });

  test('计划内复习队列未清空 → 未完成', () {
    // 计划复习队列 30 词（reviewCount=30），当日只完成 29。
    final reviewPlanWithQueue = DailyPlan(
      newWordCount: 20,
      reviewQueue: [
        for (var i = 0; i < 30; i++)
          UserWord(
            wordbookId: 1,
            wordId: i + 1,
            state: WordLearningState.review,
            status: WordStatus.review,
          ),
      ],
      deferredCount: 0,
    );
    expect(
      DailyCheckinCalculator.isTodayComplete(
        plan: reviewPlanWithQueue,
        stats: stats(newCount: 20, reviewCount: 29),
      ),
      isFalse,
    );
  });

  test('被软上限顺延的词不阻塞打卡（deferred 不影响判定）', () {
    // 计划复习队列 0 词（全部顺延），复习数 0 即满足"队列已清空"。
    const deferredOnlyPlan = DailyPlan(
      newWordCount: 20,
      reviewQueue: [],
      deferredCount: 100,
    );
    expect(
      DailyCheckinCalculator.isTodayComplete(
        plan: deferredOnlyPlan,
        stats: stats(newCount: 20, reviewCount: 0),
      ),
      isTrue,
    );
  });

  test('复习计数含重排重复出现：超出计划数仍视为完成', () {
    expect(
      DailyCheckinCalculator.isTodayComplete(
        plan: plan,
        stats: stats(newCount: 22, reviewCount: 33),
      ),
      isTrue,
    );
  });

  test('空计划 + 空统计（词书耗尽且无到期词）→ 完成', () {
    const emptyPlan = DailyPlan(
      newWordCount: 0,
      reviewQueue: [],
      deferredCount: 0,
    );
    expect(
      DailyCheckinCalculator.isTodayComplete(
        plan: emptyPlan,
        stats: stats(),
      ),
      isTrue,
    );
  });

  test('今日剩余待学新词：计划减已学，完成目标后归零', () {
    expect(
      DailyCheckinCalculator.remainingNewWordsToday(
        plan: plan,
        stats: stats(),
      ),
      20,
    );
    expect(
      DailyCheckinCalculator.remainingNewWordsToday(
        plan: plan,
        stats: stats(newCount: 15),
      ),
      5,
    );
    expect(
      DailyCheckinCalculator.remainingNewWordsToday(
        plan: plan,
        stats: stats(newCount: 20),
      ),
      0,
    );
    // 超额学习不显示负数。
    expect(
      DailyCheckinCalculator.remainingNewWordsToday(
        plan: plan,
        stats: stats(newCount: 25),
      ),
      0,
    );
  });

  test('今日剩余待学新词：词书剩余不足时以计划量（min 已收敛）为准', () {
    // 每日目标 20、词书仅剩 5 词 → 计划 5，未学时为 5。
    const limitedPlan = DailyPlan(
      newWordCount: 5,
      reviewQueue: [],
      deferredCount: 0,
    );
    expect(
      DailyCheckinCalculator.remainingNewWordsToday(
        plan: limitedPlan,
        stats: stats(),
      ),
      5,
    );
    expect(
      DailyCheckinCalculator.remainingNewWordsToday(
        plan: limitedPlan,
        stats: stats(newCount: 5),
      ),
      0,
    );
  });
}
