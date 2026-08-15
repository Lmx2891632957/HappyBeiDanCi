/// M1 首启流程 Widget 测试（PRD §3.1 设计原则 5 / TECH_DOC §5.1）：
/// 首次启动（无标记）→ Onboarding（选词书 → 设每日目标 → 开始）→ 设置落库 →
/// 直达今日任务页；再次启动（标记已置）→ 直达今日页，不再进入 Onboarding。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/app/app.dart';
import 'package:happy_bei_dan_ci/app/providers.dart';
import 'package:happy_bei_dan_ci/core/constants.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_wordbook_repository.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_settings_repository.dart';
import 'package:happy_bei_dan_ci/domain/models/app_settings.dart';
import 'package:happy_bei_dan_ci/domain/services/settings_repository.dart';
import 'package:happy_bei_dan_ci/features/onboarding/onboarding_page.dart';

import '../helpers/fixture.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'happy_beidanci_onboarding',
    );
    db = openTestDb(tempDir, 'onboarding');
    await seedWordbook(db, wordCount: 3);
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

  testWidgets('首次启动：无标记 → Onboarding → 设置落库 → 直达今日任务页', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Splash 判定未完成 → Onboarding：词书默认选中第一个、目标默认 20。
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Choose your wordbook'), findsOneWidget);
    expect(find.text('高考大纲词汇 3500'), findsOneWidget);
    expect(find.text('Daily new words goal (words/day)'), findsOneWidget);

    // 改选每日目标 30 并开始。
    await tester.tap(find.text('30'));
    await tester.pump();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    // 直达今日任务页（词书 3 词 → 待学 3）。
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Start learning'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // 落库校验：每日目标 30、首启标记 true（同一事务写入）。
    final settings = await DriftSettingsRepository(db).load();
    expect(settings.dailyNewWords, 30);
    expect(settings.onboardingDone, isTrue);
    final rows = await db.select(db.settings).get();
    expect(
      rows.singleWhere((r) => r.key == AppSettingKeys.dailyNewWords).value,
      '30',
    );
    expect(
      rows.singleWhere((r) => r.key == AppSettingKeys.onboardingDone).value,
      'true',
    );
  });

  testWidgets('首次启动默认目标：不操作直接开始 → 每日目标 20 落库', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    final settings = await DriftSettingsRepository(db).load();
    expect(settings.dailyNewWords, AppConstants.defaultDailyNewWords);
    expect(settings.onboardingDone, isTrue);
  });

  testWidgets('再次启动：标记已置 → 直达今日页，不进入 Onboarding', (tester) async {
    await seedOnboardingDone(db);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Start learning'), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.text('Get started'), findsNothing);
  });

  testWidgets('熟词快筛（PRD F1）：标记已掌握词 → 摘要计数 → 开始后新词序列排除', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);

    // 进入快筛页：3 词全量展示。
    await tester.tap(find.text('Mark words you already know (optional)'));
    await tester.pumpAndSettle();
    expect(find.text('Mark known words'), findsOneWidget);
    for (final word in ['word1', 'word2', 'word3']) {
      expect(find.text(word), findsOneWidget);
    }

    // 标记 word1 为已掌握并完成。
    await tester.tap(find.text('word1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // 返回 Onboarding：摘要显示已标记 1 个词。
    expect(find.text('1 word(s) marked'), findsOneWidget);

    // 开始学习 → 今日任务页；仓储口径：word1 不再进入新词序列。
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    final repo = DriftWordbookRepository(db);
    expect(await repo.getSkippedWordIds(1), {1});
    expect(await repo.countRemainingNewWords(1), 2);
    // 今日页加载时已触发乱序（TD-06），剩余新词顺序不固定但只含未标记词。
    final remaining = (await repo.getWordsByBook(1)).map((w) => w.word);
    expect(remaining, hasLength(2));
    expect(remaining.toSet(), {'word2', 'word3'});
  });

  testWidgets('引导保存失败：SnackBar 提示且不跳转，可重试保存', (tester) async {
    final failingSave = _FailingSaveSettingsRepository(
      DriftSettingsRepository(db),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          settingsRepositoryProvider.overrideWithValue(failingSave),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    // 门卫读取正常 → 进入 Onboarding；开始保存失败 → 提示且停留在引导页。
    expect(find.byType(OnboardingPage), findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Failed to save settings'), findsOneWidget);
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('Today'), findsNothing);

    // 恢复可保存后重试成功：直达今日页。
    failingSave.allowSave = true;
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
  });
}

/// 读取正常、首次保存抛错的设置仓储：验证 Onboarding 保存失败不跳转、
/// 可重试（TECH_DOC §5.1 完成落库口径）。
class _FailingSaveSettingsRepository implements SettingsRepository {
  _FailingSaveSettingsRepository(this._inner);

  final SettingsRepository _inner;
  bool allowSave = false;

  @override
  Future<AppSettings> load() => _inner.load();

  @override
  Future<void> save(AppSettings settings) async {
    if (!allowSave) {
      throw StateError('simulated save failure');
    }
    await _inner.save(settings);
  }

  @override
  Future<String?> get(String key) => _inner.get(key);

  @override
  Future<void> set(String key, String value) => _inner.set(key, value);
}
