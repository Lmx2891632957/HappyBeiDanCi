/// 首页"待学新词归零 + 再学一组"Widget 测试（2026-08-15 修复口径）：
/// 完成每日目标后待学新词归零、展示今日已学数；再点"开始学习"弹确认框，
/// 确认后按每日目标再学一组（词书剩余不足时封顶）。
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/app/app.dart';
import 'package:happy_bei_dan_ci/app/providers.dart';
import 'package:happy_bei_dan_ci/core/constants.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_wordbook_repository.dart';

import '../helpers/fixture.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('happy_beidanci_extra');
    db = openTestDb(tempDir, 'extra');
    // 词书 6 词：完成每日目标（3 词）后仍有剩余，可"再学一组"。
    await seedWordbook(db, wordCount: 6);
    await seedOnboardingDone(db);
    await db.into(db.settings).insert(
      SettingsCompanion.insert(
        key: AppSettingKeys.dailyNewWords,
        value: '3',
      ),
    );
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

  testWidgets('完成目标后待学新词归零并展示今日已学；再学一组确认后继续', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // 初始：每日目标 3 → 待学新词 3；今日已学 0。
    expect(find.text('New words'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Learned today: 0 words'), findsOneWidget);

    // 完成第一组（3 词，目标达成）。
    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();
    final firstGroup = await DriftWordbookRepository(db).getWordsByBook(
      1,
      limit: 3,
    );
    expect(firstGroup, hasLength(3));
    for (final word in firstGroup) {
      expect(find.text(word.word), findsOneWidget);
      await tester.tap(find.text('Know it'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Check-in complete!'), findsOneWidget);
    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();

    // 目标达成：待学新词 0（新词/复习两张卡片均为 0），今日已学 3。
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('Learned today: 3 words'), findsOneWidget);

    // 再点"开始学习"：弹"今日学习任务已完成，是否再学习一组单词？"。
    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();
    expect(
      find.text("Today's learning is done. Learn another set of words?"),
      findsOneWidget,
    );

    // 确认：再学一组（目标 3，词书剩余 3）。
    await tester.tap(find.text('Learn another set'));
    await tester.pumpAndSettle();
    final secondGroup = await DriftWordbookRepository(db).getWordsByBook(
      1,
      limit: 3,
    );
    expect(secondGroup, hasLength(3));
    expect(
      secondGroup.map((w) => w.id).toSet().intersection(
        firstGroup.map((w) => w.id).toSet(),
      ),
      isEmpty,
    );
    for (final word in secondGroup) {
      expect(find.text(word.word), findsOneWidget);
      await tester.tap(find.text('Know it'));
      await tester.pumpAndSettle();
    }

    // 两组共 6 词全部学完：统计落库、打卡成功。
    expect(find.text('Check-in complete!'), findsOneWidget);
    expect(find.text('Today: 6 new words · 0 reviews'), findsOneWidget);
    final stats = await db.select(db.dailyStats).getSingle();
    expect(stats.newCount, 6);
    expect(stats.completed, 1);
  });
}
