/// 每日核心闭环 UI 级 Widget 测试（TECH_DOC §14.2 TD-07 口径）：
/// 今日页 → 学习 3 词 → 完成页打卡；中断返回 → 快照恢复 → 队列一致。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/app/app.dart';
import 'package:happy_bei_dan_ci/app/providers.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';

import '../helpers/fixture.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('happy_beidanci_loop');
    db = openTestDb(tempDir, 'loop');
    await seedWordbook(db, wordCount: 3);
    // 首启标记已置：测试从今日任务页入口开始（首启流程单独覆盖）。
    await seedOnboardingDone(db);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildApp() => ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const App(),
  );

  testWidgets('全流程：今日页 → 学习 3 词 → 完成页打卡（daily_stats 置位）', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();

    // 三张卡依次作答（认识 → Good，FSRS 毕业为 Review）。
    for (final expected in ['word1', 'word2', 'word3']) {
      expect(find.text(expected), findsOneWidget);
      await tester.tap(find.text('Know it'));
      await tester.pumpAndSettle();
    }

    // 队列清空 → 完成页：打卡成功（今日计划=3 新词、0 复习）。
    expect(find.text('Check-in complete!'), findsOneWidget);
    expect(find.text('Today: 3 new words · 0 reviews'), findsOneWidget);

    // 落库校验：daily_stats 新词 3、打卡置位 1；快照已删除。
    final stats = await db.select(db.dailyStats).getSingle();
    expect(stats.newCount, 3);
    expect(stats.reviewCount, 0);
    expect(stats.completed, 1);
    expect(await db.select(db.sessions).get(), isEmpty);
  });

  testWidgets('中断恢复：学习中返回 → 快照保存 → 继续入口 → 队列一致并完成', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();
    expect(find.text('word1'), findsOneWidget);

    // 答对 1 张后返回（AppBar 返回按钮触发 PopScope → interrupt 落库）。
    await tester.tap(find.text('Know it'));
    await tester.pumpAndSettle();
    expect(find.text('word2'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // 回到今日页：出现"继续上次未完成的学习"入口；快照 position=1、剩余 [2,3]。
    expect(find.text('Continue unfinished session'), findsOneWidget);
    final snapshots = await db.select(db.sessions).get();
    expect(snapshots, hasLength(1));
    expect(snapshots.single.position, 1);
    final items = await db.select(db.sessionItems).get();
    expect(items.map((e) => e.wordId).toList(), [2, 3]);

    // 继续：恢复后队列一致（下一张仍为 word2）。
    await tester.tap(find.text('Continue unfinished session'));
    await tester.pumpAndSettle();
    expect(find.text('word2'), findsOneWidget);
    await tester.tap(find.text('Know it'));
    await tester.pumpAndSettle();
    expect(find.text('word3'), findsOneWidget);
    await tester.tap(find.text('Know it'));
    await tester.pumpAndSettle();

    expect(find.text('Check-in complete!'), findsOneWidget);
    final stats = await db.select(db.dailyStats).getSingle();
    expect(stats.newCount, 3);
    expect(stats.completed, 1);
    expect(await db.select(db.sessions).get(), isEmpty);
  });
}
