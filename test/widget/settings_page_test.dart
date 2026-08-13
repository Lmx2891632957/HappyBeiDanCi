/// 设置页 Widget 测试（TECH_DOC §4 补充说明 9）：设置项保存落库、
/// 提醒调度（注入桩）、数据导出（注入桩 + 真实仓储/临时目录）、关于页入口。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/app/app.dart';
import 'package:happy_bei_dan_ci/app/providers.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_review_log_repository.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_settings_repository.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_user_word_repository.dart';
import 'package:happy_bei_dan_ci/data/sources/data_exporter.dart';
import 'package:happy_bei_dan_ci/data/sources/reminder_scheduler.dart';

import '../helpers/fixture.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late _FakeReminderScheduler reminder;
  late List<List<String>> sharedFiles;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('happy_beidanci_settings');
    db = openTestDb(tempDir, 'settings');
    await seedWordbook(db, wordCount: 3);
    await seedOnboardingDone(db);
    reminder = _FakeReminderScheduler();
    sharedFiles = [];
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildApp() {
    final exporter = DataExporter(
      reviewLogs: DriftReviewLogRepository(db),
      userWords: DriftUserWordRepository(db),
      exportDirectory: () async => Directory('${tempDir.path}/exports'),
      share: (files, subject) async {
        sharedFiles.add([for (final f in files) f.path]);
      },
    );
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        reminderSchedulerProvider.overrideWithValue(reminder),
        dataExporterProvider.overrideWithValue(exporter),
      ],
      child: const App(),
    );
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
  }

  /// 设置页为长列表，目标项可能在视口外（ListView 懒构建）→ 先滚动再断言/点击。
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('设置页分组完整渲染：目标/复习上限/发音/提醒/外观/数据/关于', (
    tester,
  ) async {
    await openSettings(tester);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Daily new words'), findsOneWidget);
    expect(find.text('Daily review cap'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Pronunciation'), findsOneWidget);
    await scrollTo(tester, find.text('Enable daily reminder'));
    expect(find.text('Language'), findsOneWidget);
    await scrollTo(tester, find.text('Language'));
    expect(find.text('Dark mode'), findsOneWidget);
    await scrollTo(tester, find.text('Dark mode'));
    expect(find.text('Export review logs & word progress (CSV)'), findsOneWidget);
    expect(find.text('About & data sources'), findsOneWidget);
  });

  testWidgets('每日目标 20→30 落库，语言切中文、深色模式切 Dark 落库', (
    tester,
  ) async {
    await openSettings(tester);
    await tester.tap(find.text('30'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Dark'));
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    // 语言切中文（切到中文后断言走仓储，避免后续英文文案找不到）。
    await scrollTo(tester, find.text('中文'));
    await tester.tap(find.text('中文'));
    await tester.pumpAndSettle();

    final settings = await DriftSettingsRepository(db).load();
    expect(settings.dailyNewWords, 30);
    expect(settings.themeMode, 'dark');
    expect(settings.language, 'zh');
  });

  testWidgets('提醒开关关闭→取消任务；重新开启→权限检测后按提醒时间排程', (
    tester,
  ) async {
    await openSettings(tester);
    // 默认开启 → 先关闭（取消），再开启（排程）。
    await scrollTo(tester, find.text('Enable daily reminder'));
    await tester.tap(find.text('Enable daily reminder'));
    await tester.pumpAndSettle();
    expect(reminder.cancelCalls, greaterThanOrEqualTo(1));

    await tester.tap(find.text('Enable daily reminder'));
    await tester.pumpAndSettle();
    expect(reminder.scheduleCalls, 1);
    expect(reminder.lastHour, 20);
    expect(reminder.lastMinute, 0);
  });

  testWidgets('通知权限被拒：展示系统设置引导，不排程', (tester) async {
    reminder.enabled = false;
    reminder.permissionGranted = false;
    await openSettings(tester);
    // 先关闭再开启，触发权限流程。
    await scrollTo(tester, find.text('Enable daily reminder'));
    await tester.tap(find.text('Enable daily reminder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable daily reminder'));
    await tester.pumpAndSettle();

    // 权限引导 banner 渲染在列表顶部，滚动回顶部后断言。
    await tester.drag(find.byType(ListView).last, const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Notifications are disabled. Enable them in system settings to '
        'get daily reminders.',
      ),
      findsOneWidget,
    );
    expect(find.text('Open settings'), findsOneWidget);
    expect(reminder.scheduleCalls, 0);
  });

  testWidgets('导出 CSV：生成 review_logs.csv 与 user_words.csv 并经分享桩', (
    tester,
  ) async {
    await openSettings(tester);
    await scrollTo(
      tester,
      find.text('Export review logs & word progress (CSV)'),
    );
    await tester.tap(find.text('Export review logs & word progress (CSV)'));
    await tester.pumpAndSettle();

    expect(sharedFiles, hasLength(1));
    expect(sharedFiles.single, hasLength(2));
    final dir = Directory('${tempDir.path}/exports');
    final reviewFile = File('${dir.path}/review_logs.csv');
    final wordsFile = File('${dir.path}/user_words.csv');
    expect(reviewFile.existsSync(), isTrue);
    expect(wordsFile.existsSync(), isTrue);
    // UTF-8 BOM（EF BB BF）：readAsStringSync 解码会剥掉 BOM，需按原始字节断言。
    expect(reviewFile.readAsBytesSync().take(3).toList(), [0xEF, 0xBB, 0xBF]);
  });

  testWidgets('关于入口：进入数据来源页并展示来源署名', (tester) async {
    await openSettings(tester);
    await scrollTo(tester, find.text('About & data sources'));
    await tester.tap(find.text('About & data sources'));
    await tester.pumpAndSettle();
    expect(find.text('Data sources'), findsOneWidget);
    expect(find.text('ECDICT (MIT)'), findsOneWidget);
    expect(find.text('Tatoeba English sentences (CC BY 2.0 FR)'), findsOneWidget);
  });
}

class _FakeReminderScheduler implements ReminderScheduler {
  int scheduleCalls = 0;
  int cancelCalls = 0;
  int lastHour = -1;
  int lastMinute = -1;
  bool? enabled = true;
  bool permissionGranted = true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleDaily({
    required String timezoneName,
    required DateTime now,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    scheduleCalls++;
    lastHour = hour;
    lastMinute = minute;
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }

  @override
  Future<bool?> requestNotificationsPermission() async => permissionGranted;

  @override
  Future<bool?> areNotificationsEnabled() async => enabled;

  @override
  Future<void> openNotificationSettings() async {}
}
