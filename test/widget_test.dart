/// 应用装配 Widget 测试：Provider 覆盖测试 DB + 种子词书后，
/// 应用可装配并渲染今日任务页（TECH_DOC §4/§5.1）。
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/app/app.dart';
import 'package:happy_bei_dan_ci/app/providers.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';
import 'package:happy_bei_dan_ci/features/home/home_page.dart';

import 'helpers/fixture.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('happy_beidanci_widget');
    db = openTestDb(tempDir, 'app');
    await seedWordbook(db, wordCount: 3);
    // 首启标记已置：直接渲染今日任务页（首启流程由 onboarding_widget_test 覆盖）。
    await seedOnboardingDone(db);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('应用骨架可装配并渲染今日任务页（种子词书）', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    // flutter test 默认 locale 为 en_US，断言英文文案。
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('New words'), findsOneWidget);
    // 3 个新词（默认每日目标 20，词书仅 3 词 → 待学 3）。
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Due reviews'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
