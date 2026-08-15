/// 会话页生命周期 Widget 测试（切后台→切回前台回归，TECH_DOC §5.4）：
/// 1) 全流程（真实 DB）：退后台 interrupt 落库 → 切回前台 resumed 恢复 →
///    继续评分不报错并完成；
/// 2) 并发竞态（内存 fake + 慢写库钩子）：评分进行中触发中断，互斥逻辑
///    等评分完成后再保存快照，恢复后继续评分不抛 StateError。
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/app/app.dart';
import 'package:happy_bei_dan_ci/app/l10n/app_localizations.dart';
import 'package:happy_bei_dan_ci/app/providers.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_wordbook_repository.dart';
import 'package:happy_bei_dan_ci/domain/models/word.dart';
import 'package:happy_bei_dan_ci/domain/sessions/default_session_state_machine.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_driver.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_snapshot.dart';
import 'package:happy_bei_dan_ci/features/learn/session_flow.dart';

import '../helpers/fake_session_repos.dart';
import '../helpers/fixture.dart';

/// 测试词条（学习会话初始队列用，word 文本与 ID 一一对应便于断言）。
Word buildWord(int id) => Word(
  id: id,
  word: 'word$id',
  phonetic: '/w$id/',
  meanings: const [WordMeaning(pos: 'n.', meaning: '释义')],
  examples: const [
    WordExample(
      en: 'I like it.',
      zh: '我喜欢它。',
      source: 'test',
      attribution: 'test',
    ),
  ],
  frequency: WordFrequency.high,
  audioKey: 'a$id',
  createdAt: DateTime(2026, 1, 1),
);

/// 模拟退后台：AppLifecycleListener 校验状态转移（AppLifecycleState 状态机），
/// 必须按 inactive → hidden → paused 的合法序列逐次通知（真实 Android 时序）。
void backgroundApp(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
}

/// 模拟切回前台：paused → hidden → inactive → resumed 的合法转移序列。
void foregroundApp(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

void main() {
  group('切后台返回后继续评分（缺陷一/缺陷二回归）', () {
    late Directory tempDir;
    late AppDatabase db;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('happy_beidanci_lifecycle');
      db = openTestDb(tempDir, 'lifecycle');
      await seedWordbook(db, wordCount: 3);
      await seedOnboardingDone(db);
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('真实链路：退后台 interrupt 落库 → 切回前台恢复 → 继续评分并完成', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const App(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start learning'));
      await tester.pumpAndSettle();

      // 乱序后的实际学习顺序（与今日页取词同源）。
      final expected = await DriftWordbookRepository(db).getWordsByBook(
        1,
        limit: 3,
      );
      expect(find.text(expected[0].word), findsOneWidget);

      // 答对第 1 张 → 展示第 2 张。
      await tester.tap(find.text('Know it'));
      await tester.pumpAndSettle();
      expect(find.text(expected[1].word), findsOneWidget);

      // 模拟退后台：paused → interrupt 落库快照（position=1，剩余 [2,3]）。
      // 页面原样保留、驱动转 Paused（此前无 resumed 分支，继续评分会抛错）。
      backgroundApp(tester);
      await tester.pumpAndSettle();
      final snapshots = await db.select(db.sessions).get();
      expect(snapshots, hasLength(1));
      expect(snapshots.single.position, 1);

      // 模拟切回前台：resumed → 恢复会话，仍展示第 2 张且无任何错误弹窗。
      foregroundApp(tester);
      await tester.pumpAndSettle();
      expect(find.text(expected[1].word), findsOneWidget);
      expect(find.textContaining('Failed to rate'), findsNothing);
      expect(find.textContaining('Failed to load session'), findsNothing);

      // 恢复后继续评分不报错：第 2、3 张依次作答，队列清空后进入完成页。
      await tester.tap(find.text('Know it'));
      await tester.pumpAndSettle();
      expect(find.text(expected[2].word), findsOneWidget);
      await tester.tap(find.text('Know it'));
      await tester.pumpAndSettle();
      expect(find.text('Check-in complete!'), findsOneWidget);
    });
  });

  group('评分与中断并发竞态（缺陷二回归）', () {
    testWidgets('评分进行中触发中断：互斥等评分完成再保存快照，恢复后继续评分不报错', (tester) async {
      final userWords = FakeUserWordRepository();
      final reviewLogs = FakeReviewLogRepository();
      final sessions = FakeSessionRepository();
      final stats = FakeStatsRepository();
      final driver = SessionDriver(
        stateMachine: DefaultSessionStateMachine(),
        scheduler: FakeScheduler(intervalDays: 1),
        userWords: userWords,
        reviewLogs: reviewLogs,
        sessions: sessions,
        stats: stats,
        now: () => DateTime(2026, 8, 12, 10, 30),
      );
      // 慢写库钩子：让第 1 张的评分在 upsert 处挂起，制造"评分与中断并发"窗口。
      final gate = Completer<void>();
      userWords.onUpsert = () => gate.future;

      final words = [buildWord(1), buildWord(2), buildWord(3)];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sessionDriverProvider.overrideWith((ref) => driver)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SessionFlow(
              type: SessionType.learning,
              wordbookId: 1,
              initialWords: words,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('word1'), findsOneWidget);

      // 点评分（第 1 张）：评分挂起在慢写库钩子上（_submitting/_pendingRate 已置位）。
      await tester.tap(find.text('Know it'));
      await tester.pump();

      // 评分进行中触发退后台中断：互斥逻辑应等待评分完成后再保存快照，
      // 而不是让评分落到已 Paused 的状态机（旧实现此处抛 CardRated StateError）。
      backgroundApp(tester);

      // 放行评分写库：评分完成（队列推进到第 2 张）→ 中断随后保存快照。
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('Failed to rate'), findsNothing);
      expect(find.text('word2'), findsOneWidget);
      expect(sessions.snapshots, hasLength(1));
      final snap = sessions.snapshots.values.single;
      expect(snap.position, 1);
      expect(snap.items.map((e) => e.wordId).toList(), [2, 3]);

      // 切回前台：恢复会话，继续评分不报错（第 2 张作答 → 展示第 3 张）。
      foregroundApp(tester);
      await tester.pumpAndSettle();
      expect(find.text('word2'), findsOneWidget);
      await tester.tap(find.text('Know it'));
      await tester.pumpAndSettle();
      expect(find.text('word3'), findsOneWidget);
      expect(find.textContaining('Failed to rate'), findsNothing);
    });
  });
}
