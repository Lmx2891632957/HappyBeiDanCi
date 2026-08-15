/// 会话卡片布局 Widget 测试（TECH_DOC §4 补充说明 5）：
/// 高度自适应、反面例句固定展示区始终可见、例句展开/收起。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/app/l10n/app_localizations.dart';
import 'package:happy_bei_dan_ci/domain/models/word.dart';
import 'package:happy_bei_dan_ci/features/learn/widgets/session_card.dart';

/// 构造测试词条：可指定释义数量/长度与例句。
Word buildWord({
  int id = 1,
  String word = 'test',
  int meaningCount = 1,
  int meaningRepeat = 0,
  String exampleEn = 'I like this word.',
  String? exampleZh = '我喜欢这个词。',
  bool withExample = true,
}) {
  return Word(
    id: id,
    word: word,
    phonetic: '/test/',
    meanings: [
      for (var i = 1; i <= meaningCount; i++)
        WordMeaning(
          pos: 'n.',
          // 释义文本重复若干次以模拟"中文释义较多"的长释义。
          meaning: '释义$i${'长' * meaningRepeat}',
        ),
    ],
    examples: withExample
        ? [
            WordExample(
              en: exampleEn,
              zh: exampleZh,
              source: 'Tatoeba',
              attribution: 'test',
            ),
          ]
        : const [],
    frequency: WordFrequency.high,
    audioKey: 'a$id',
    createdAt: DateTime(2026, 1, 1),
  );
}

/// 在给定最大高度内渲染单张卡片（默认英文界面，便于断言文案）。
///
/// 使用 `ConstrainedBox`（松约束）而非 `SizedBox`（紧约束）模拟真实
/// 页面中 `Expanded > Center > Padding` 的约束环境：卡片按自身内容
/// 收缩，LayoutBuilder 的上限逻辑才能生效。
Future<void> pumpCard(WidgetTester tester, Word word, {double maxHeight = 600}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SessionCard(word: word, wordbookId: 1),
            ),
          ),
        ),
      ),
    ),
  );
}

/// 当前展示面（正面/反面）的内容高度：卡片内容被 LayoutBuilder 封顶后
/// 的高度，排除 Card 自身的外边距。
double cardContentHeight(WidgetTester tester) {
  final front = find.byKey(const ValueKey('front'));
  final back = find.byKey(const ValueKey('back'));
  if (front.evaluate().isNotEmpty) {
    return tester.getSize(front).height;
  }
  return tester.getSize(back).height;
}

/// 点击卡片翻面（点单词文本，避开正面居中的发音按钮）。
Future<void> flipCard(WidgetTester tester, String word) async {
  await tester.tap(find.text(word));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('卡片高度自适应：较大空间时高于固定 320 且封顶于上限', (tester) async {
    await pumpCard(tester, buildWord(), maxHeight: 600);
    // 卡片默认显示正面（单词）。
    expect(find.text('test'), findsOneWidget);

    final height = cardContentHeight(tester);
    expect(height, greaterThan(320));
    expect(height, SessionCard.maxHeight);
  });

  testWidgets('卡片高度自适应：小空间时收缩而不溢出', (tester) async {
    await pumpCard(tester, buildWord(), maxHeight: 300);
    final height = cardContentHeight(tester);
    expect(height, lessThan(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('翻面后展示释义与例句，例句标签可见', (tester) async {
    final word = buildWord(meaningCount: 2);
    await pumpCard(tester, word);
    await flipCard(tester, word.word);

    expect(find.text('n. 释义1'), findsOneWidget);
    expect(find.text('n. 释义2'), findsOneWidget);
    expect(find.text('Example'), findsOneWidget);
    expect(find.text(word.examples.first.en), findsOneWidget);
    expect(find.text(word.examples.first.zh!), findsOneWidget);
  });

  testWidgets('释义较多时例句始终可见：滚动释义区不隐藏例句', (tester) async {
    // 6 条长释义：保证释义区内容超高、需要内部滚动。
    final word = buildWord(meaningCount: 6, meaningRepeat: 60);
    await pumpCard(tester, word, maxHeight: 400);
    await flipCard(tester, word.word);

    final exampleFinder = find.text(word.examples.first.en);
    expect(exampleFinder, findsOneWidget);
    final cardRect = tester.getRect(find.byType(Card));
    expect(cardRect.contains(tester.getRect(exampleFinder).center), isTrue);

    // 滚动释义区（列表向上拖动）后，例句仍在卡片内可见（不在滚动区里）。
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(exampleFinder, findsOneWidget);
    expect(cardRect.contains(tester.getRect(exampleFinder).center), isTrue);
  });

  testWidgets('例句过长时可点按展开/收起', (tester) async {
    // 18 词长句：折叠态 2 行截断，展开后完整展示。
    final word = buildWord(
      exampleEn:
          'This is a quite long example sentence with many words so that it '
          'will wrap to more than two lines on a normal phone screen width.',
      meaningCount: 1,
    );
    await pumpCard(tester, word);
    await flipCard(tester, word.word);

    // 折叠态：展开图标。
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    // 点按例句区（标签文本）→ 展开。
    await tester.tap(find.text('Example'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.expand_less), findsOneWidget);
    expect(find.text(word.examples.first.en), findsOneWidget);
    // 再点按 → 收起。
    await tester.tap(find.text('Example'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
  });

  testWidgets('无例句的词不渲染例句区（防御）', (tester) async {
    final word = buildWord(withExample: false, meaningCount: 2);
    await pumpCard(tester, word);
    await flipCard(tester, word.word);

    expect(find.text('n. 释义1'), findsOneWidget);
    expect(find.text('Example'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('换词后卡片重置回正面（翻面/例句展开态不跨词保留）', (tester) async {
    final wordA = buildWord(id: 1, word: 'alpha', meaningCount: 2);
    final wordB = buildWord(id: 2, word: 'beta');
    await pumpCard(tester, wordA);

    // 翻面并展开例句。
    await flipCard(tester, 'alpha');
    expect(find.text('Example'), findsOneWidget);
    await tester.tap(find.text('Example'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.expand_less), findsOneWidget);

    // 同一卡片位置换词：State 复用触发 didUpdateWidget，应回到正面且收起。
    await pumpCard(tester, wordB);
    await tester.pumpAndSettle();
    expect(find.text('beta'), findsOneWidget);
    expect(find.text('Example'), findsNothing);
    expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);
  });
}
