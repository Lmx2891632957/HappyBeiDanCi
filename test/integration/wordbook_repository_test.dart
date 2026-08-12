/// Wordbook 仓储集成测试：词书/词条读取、新词过滤与学习顺序、批量取词
///（TECH_DOC §8.1/§8.3，AGENTS §7）。
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_wordbook_repository.dart';
import 'package:happy_bei_dan_ci/domain/models/word.dart';
import 'package:happy_bei_dan_ci/domain/services/wordbook_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'happy_beidanci_wordbook_repo',
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  (AppDatabase, WordbookRepository) openRepo(String name) {
    final db = AppDatabase.forTesting(
      NativeDatabase(File('${tempDir.path}/$name.db')),
    );
    addTearDown(db.close);
    return (db, DriftWordbookRepository(db));
  }

  Future<void> seedBook(
    AppDatabase db, {
    int id = 1,
    String name = '高考大纲词汇 3500',
    int sortOrder = 0,
    int totalCount = 0,
  }) async {
    await db.into(db.wordbooks).insert(
      WordbooksCompanion.insert(
        id: Value(id),
        name: name,
        level: 'gaokao',
        totalCount: totalCount,
        source: 'ECDICT + 考纲',
        createdAt: 1,
        sortOrder: Value(sortOrder),
      ),
    );
  }

  Future<void> seedWord(
    AppDatabase db, {
    required int id,
    required String word,
    required String frequency,
    String? meanings,
  }) async {
    await db.into(db.words).insert(
      WordsCompanion.insert(
        id: Value(id),
        word: word,
        phonetic: '/test/',
        meanings:
            meanings ??
            jsonEncode([
              {'pos': 'n.', 'meaning': '释义$id'},
            ]),
        examples: jsonEncode([
          {
            'en': 'This is $word.',
            'zh': '这是 $word。',
            'source': 'Tatoeba',
            'attribution': 'test',
          },
        ]),
        frequency: frequency,
        audioKey: 'a$id',
        createdAt: 1,
      ),
    );
  }

  Future<void> seedItem(
    AppDatabase db, {
    required int wordId,
    int wordbookId = 1,
    required int seq,
    required int shuffled,
    bool isSkipped = false,
  }) async {
    await db.into(db.wordbookItems).insert(
      WordbookItemsCompanion.insert(
        wordbookId: wordbookId,
        wordId: wordId,
        seq: seq,
        shuffled: shuffled,
        isSkipped: Value(isSkipped),
      ),
    );
  }

  /// 预置"已学"行（user_words 存在即不算新词，§8.3）。
  Future<void> seedLearned(
    AppDatabase db, {
    required int wordId,
    int wordbookId = 1,
  }) async {
    await db.into(db.userWords).insert(
      UserWordsCompanion.insert(
        wordbookId: wordbookId,
        wordId: wordId,
        state: 'review',
        status: 'review',
      ),
    );
  }

  group('词书读取', () {
    test('getWordbookById 往返；不存在返回 null', () async {
      final (db, repo) = openRepo('book_roundtrip');
      await seedBook(db, id: 7, totalCount: 12);
      final book = await repo.getWordbookById(7);
      expect(book, isNotNull);
      expect(book!.id, 7);
      expect(book.name, '高考大纲词汇 3500');
      expect(book.level, 'gaokao');
      expect(book.totalCount, 12);
      expect(book.createdAt, DateTime.fromMillisecondsSinceEpoch(1));
      expect(await repo.getWordbookById(99), isNull);
    });

    test('getWordbooks 按 sortOrder 升序（次键 id 升序，确定性）', () async {
      final (db, repo) = openRepo('book_list');
      await seedBook(db, id: 2, sortOrder: 1, totalCount: 10);
      await seedBook(db, id: 1, sortOrder: 0, totalCount: 20);
      final books = await repo.getWordbooks();
      expect(books.map((b) => b.id).toList(), [1, 2]);
    });
  });

  group('词条读取与新词顺序（§8.3）', () {
    test('getItem 往返；不存在返回 null', () async {
      final (db, repo) = openRepo('item');
      await seedItem(db, wordId: 5, seq: 1, shuffled: 3);
      final item = await repo.getItem(wordbookId: 1, wordId: 5);
      expect(item, isNotNull);
      expect(item!.wordbookId, 1);
      expect(item.wordId, 5);
      expect(item.seq, 1);
      expect(item.shuffled, 3);
      expect(item.isSkipped, isFalse);
      expect(await repo.getItem(wordbookId: 1, wordId: 9), isNull);
    });

    test('getWordsByBook：频段 high→medium→low、频段内 shuffled 递增', () async {
      final (db, repo) = openRepo('order');
      await seedBook(db, totalCount: 5);
      // 故意乱序插入，验证排序完全由查询决定。
      await seedWord(db, id: 1, word: 'low1', frequency: 'low');
      await seedWord(db, id: 2, word: 'high2', frequency: 'high');
      await seedWord(db, id: 3, word: 'high1', frequency: 'high');
      await seedWord(db, id: 4, word: 'mid1', frequency: 'medium');
      await seedItem(db, wordId: 1, seq: 1, shuffled: 9);
      await seedItem(db, wordId: 2, seq: 2, shuffled: 2);
      await seedItem(db, wordId: 3, seq: 3, shuffled: 1);
      await seedItem(db, wordId: 4, seq: 4, shuffled: 5);

      final words = await repo.getWordsByBook(1);
      expect(words.map((w) => w.word).toList(), ['high1', 'high2', 'mid1', 'low1']);

      // 分页作用于排序后序列。
      final page1 = await repo.getWordsByBook(1, limit: 2);
      expect(page1.map((w) => w.word).toList(), ['high1', 'high2']);
      final page2 = await repo.getWordsByBook(1, limit: 2, offset: 2);
      expect(page2.map((w) => w.word).toList(), ['mid1', 'low1']);
    });

    test('getWordsByBook 排除已学词与熟词跳过项', () async {
      final (db, repo) = openRepo('filter');
      await seedBook(db, totalCount: 4);
      for (final (id, word) in [(1, 'a'), (2, 'b'), (3, 'c'), (4, 'd')]) {
        await seedWord(db, id: id, word: word, frequency: 'high');
        await seedItem(
          db,
          wordId: id,
          seq: id,
          shuffled: id,
          isSkipped: id == 3, // 词 3 标记为熟词跳过
        );
      }
      await seedLearned(db, wordId: 2);

      final words = await repo.getWordsByBook(1);
      expect(words.map((w) => w.word).toList(), ['a', 'd']);
      expect(await repo.countRemainingNewWords(1), 2);

      // 已学词不影响其他词书的统计口径（wordbook_id 隔离）。
      await seedBook(db, id: 2, totalCount: 2, sortOrder: 1);
      expect(await repo.countRemainingNewWords(2), 0);
    });

    test('countRemainingNewWords：空词书为 0，学习后递减', () async {
      final (db, repo) = openRepo('count');
      await seedBook(db, totalCount: 3);
      expect(await repo.countRemainingNewWords(1), 0);
      for (final (id, word) in [(1, 'a'), (2, 'b'), (3, 'c')]) {
        await seedWord(db, id: id, word: word, frequency: 'high');
        await seedItem(db, wordId: id, seq: id, shuffled: id);
      }
      expect(await repo.countRemainingNewWords(1), 3);
      await seedLearned(db, wordId: 1);
      expect(await repo.countRemainingNewWords(1), 2);
    });

    test('getWordsByIds：返回顺序与入参一致、缺失 ID 跳过', () async {
      final (db, repo) = openRepo('by_ids');
      await seedWord(db, id: 1, word: 'one', frequency: 'high');
      await seedWord(db, id: 2, word: 'two', frequency: 'medium');
      await seedWord(db, id: 3, word: 'three', frequency: 'low');
      final words = await repo.getWordsByIds([3, 1, 99, 2]);
      expect(words.map((w) => w.word).toList(), ['three', 'one', 'two']);
      expect(await repo.getWordsByIds(const []), isEmpty);
    });

    test('词条字段往返：meanings/examples JSON 解析为领域值类型', () async {
      final (db, repo) = openRepo('fields');
      await seedWord(
        db,
        id: 1,
        word: 'apple',
        frequency: 'high',
        meanings: jsonEncode([
          {'pos': 'n.', 'meaning': '苹果'},
          {'pos': 'n.', 'meaning': '苹果树'},
        ]),
      );
      await seedItem(db, wordId: 1, seq: 1, shuffled: 1);
      final word = (await repo.getWordsByBook(1)).single;
      expect(word.meanings, hasLength(2));
      expect(word.meanings.first.pos, 'n.');
      expect(word.meanings.first.meaning, '苹果');
      expect(word.examples.single.en, 'This is apple.');
      expect(word.examples.single.source, 'Tatoeba');
      expect(word.frequency, WordFrequency.high);
      expect(word.audioKey, 'a1');
    });
  });

  group('损坏数据口径：不静默', () {
    test('未知 frequency 抛 StateError', () async {
      final (db, repo) = openRepo('corrupt_freq');
      await seedWord(db, id: 1, word: 'x', frequency: 'typo');
      await seedItem(db, wordId: 1, seq: 1, shuffled: 1);
      await expectLater(
        repo.getWordsByBook(1),
        throwsA(isA<StateError>()),
      );
    });

    test('meanings JSON 损坏抛 StateError', () async {
      final (db, repo) = openRepo('corrupt_json');
      await seedWord(db, id: 1, word: 'x', frequency: 'high', meanings: '{bad');
      await seedItem(db, wordId: 1, seq: 1, shuffled: 1);
      await expectLater(
        repo.getWordsByBook(1),
        throwsA(isA<StateError>()),
      );
    });
  });
}
