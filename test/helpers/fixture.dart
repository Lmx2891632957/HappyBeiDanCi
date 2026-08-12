/// 测试 fixture 助手：临时 AppDatabase 与词书种子数据（内容管线未交付，
/// TECH_DOC §10；集成/Widget 测试共用，AGENTS §7 测试结构纪律）。
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:happy_bei_dan_ci/core/constants.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';

/// 创建临时文件 DB（调用方负责 close，并清理临时目录）。
AppDatabase openTestDb(Directory tempDir, String name) {
  return AppDatabase.forTesting(
    NativeDatabase(File('${tempDir.path}/$name.db')),
  );
}

/// 种子：1 本词书 + [wordCount] 个高频词（shuffled 递增），返回词 ID 列表。
Future<List<int>> seedWordbook(
  AppDatabase db, {
  int wordCount = 3,
  int bookId = 1,
}) async {
  await db
      .into(db.wordbooks)
      .insert(
        WordbooksCompanion.insert(
          id: Value(bookId),
          name: '高考大纲词汇 3500',
          level: 'gaokao',
          totalCount: wordCount,
          source: 'test-fixture',
          createdAt: 1,
        ),
      );
  final ids = <int>[];
  for (var i = 1; i <= wordCount; i++) {
    final word = 'word$i';
    await db
        .into(db.words)
        .insert(
          WordsCompanion.insert(
            id: Value(i),
            word: word,
            phonetic: '/w$i/',
            meanings: jsonEncode([
              {'pos': 'n.', 'meaning': '释义$i'},
            ]),
            examples: jsonEncode([
              {
                'en': 'I like $word.',
                'zh': '我喜欢 $word。',
                'source': 'Tatoeba',
                'attribution': 'test',
              },
            ]),
            frequency: 'high',
            audioKey: 'a$i',
            createdAt: 1,
          ),
        );
    await db
        .into(db.wordbookItems)
        .insert(
          WordbookItemsCompanion.insert(
            wordbookId: bookId,
            wordId: i,
            seq: i,
            shuffled: i,
          ),
        );
    ids.add(i);
  }
  return ids;
}

/// 预置首启标记（默认已完成引导），供“再次启动直达今日页”类测试使用；
/// 缺失标记时应用应进入 Onboarding（首启行为由 onboarding_widget_test 覆盖）。
Future<void> seedOnboardingDone(AppDatabase db, {bool done = true}) async {
  await db
      .into(db.settings)
      .insert(
        SettingsCompanion.insert(
          key: AppSettingKeys.onboardingDone,
          value: done ? 'true' : 'false',
        ),
      );
}
