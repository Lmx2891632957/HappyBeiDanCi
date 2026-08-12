/// 发布版词库导入集成测试（TECH_DOC §8.2）：
/// 首次导入、同版本幂等、v1→v2 升级 remap（word 文本映射）、坏包拒绝。
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';
import 'package:happy_bei_dan_ci/data/sources/wordbook_importer.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../helpers/fixture.dart';

/// 构造发布版词库 DB（表结构与管线打包 schema 一致，TECH_DOC §10.2/§8.1）。
void writePackFile(
  File file, {
  required String version,
  required List<String> words,
}) {
  final db = sqlite.sqlite3.open(file.path);
  try {
    db.execute('''
      CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
      CREATE TABLE wordbooks (
        id INTEGER PRIMARY KEY, name TEXT NOT NULL, level TEXT NOT NULL,
        total_count INTEGER NOT NULL, source TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL
      );
      CREATE TABLE words (
        id INTEGER PRIMARY KEY, word TEXT NOT NULL UNIQUE, phonetic TEXT NOT NULL,
        phonetic_uk TEXT, meanings TEXT NOT NULL, examples TEXT NOT NULL,
        frequency TEXT NOT NULL, root_affix TEXT, audio_key TEXT NOT NULL,
        audio_url TEXT, created_at INTEGER NOT NULL
      );
      CREATE TABLE wordbook_items (
        wordbook_id INTEGER NOT NULL, word_id INTEGER NOT NULL,
        seq INTEGER NOT NULL, shuffled INTEGER NOT NULL,
        is_skipped INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (wordbook_id, word_id)
      );
    ''');
    db.execute(
      "INSERT INTO meta (key, value) VALUES ('schema_version', '1')",
    );
    db.execute(
      'INSERT INTO meta (key, value) VALUES (?, ?)',
      ['wordlist_version', version],
    );
    db.execute(
      'INSERT INTO wordbooks (id, name, level, total_count, source, '
      'sort_order, created_at) VALUES (1, ?, ?, ?, ?, 0, 1)',
      ['测试词书', 'gaokao', words.length, 'test-pack'],
    );
    final now = 1;
    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      final wid = _hashId(w);
      db.execute(
        'INSERT INTO words (id, word, phonetic, phonetic_uk, meanings, '
        'examples, frequency, root_affix, audio_key, audio_url, created_at) '
        'VALUES (?, ?, ?, NULL, ?, ?, ?, NULL, ?, NULL, ?)',
        [
          wid,
          w,
          '/phonetic/',
          jsonEncode([
            {'pos': 'n.', 'meaning': '释义$w'},
          ]),
          jsonEncode([
            {
              'en': 'I read $w.',
              'source': 'Tatoeba',
              'attribution': 'tester',
              'url': 'https://tatoeba.org/en/sentences/show/1',
            },
          ]),
          'high',
          '000001',
          now,
        ],
      );
      db.execute(
        'INSERT INTO wordbook_items (wordbook_id, word_id, seq, shuffled, '
        'is_skipped) VALUES (1, ?, ?, ?, 0)',
        [wid, i, i],
      );
    }
  } finally {
    db.close();
  }
}

int _hashId(String word) =>
    int.parse(word.codeUnits.fold('', (a, b) => '$a${b % 10}').padRight(8, '1'));

/// 测试用备份写入器：落盘到临时目录并记录文件名。
class TempBackupWriter implements BackupWriter {
  TempBackupWriter(this.dir);
  final Directory dir;
  final List<File> written = [];

  @override
  Future<File> write({required String name, required String content}) async {
    await dir.create(recursive: true);
    final file = File('${dir.path}/$name');
    await file.writeAsString(content);
    written.add(file);
    return file;
  }
}

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late TempBackupWriter backupWriter;
  late WordbookImporter importer;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wordbook_import_test');
    db = openTestDb(tempDir, 'app');
    backupWriter = TempBackupWriter(Directory('${tempDir.path}/backups'));
    importer = WordbookImporter(db, backupWriter: backupWriter);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('首次导入：内容入库、版本记录、仓储可读', () async {
    final pack = File('${tempDir.path}/pack.db');
    writePackFile(pack, version: '1.0', words: ['apple', 'book', 'cat']);

    final result = await importer.importFromFile(pack);

    expect(result.changed, isTrue);
    expect(result.version, '1.0');
    expect(result.wordCount, 3);
    final settings = {
      for (final r in await db.select(db.settings).get()) r.key: r.value,
    };
    expect(settings['wordbook_version'], '1.0');
    final books = await db.select(db.wordbooks).get();
    expect(books, hasLength(1));
    expect(books.single.totalCount, 3);
    final words = await db.select(db.words).get();
    expect(words.map((r) => r.word), containsAll(['apple', 'book', 'cat']));
  });

  test('同版本重复导入：幂等 no-op', () async {
    final pack = File('${tempDir.path}/pack.db');
    writePackFile(pack, version: '1.0', words: ['apple', 'book']);
    await importer.importFromFile(pack);

    final second = await importer.importFromFile(pack);

    expect(second.changed, isFalse);
    final count = await db.select(db.words).get();
    expect(count, hasLength(2));
  });

  test('v1→v2 升级：按 word 文本 remap，移除已删词进度，备份用户表', () async {
    final packV1 = File('${tempDir.path}/v1.db');
    writePackFile(packV1, version: '1.0', words: ['apple', 'book', 'cat']);
    await importer.importFromFile(packV1);

    // 预置用户进度：apple（保留）、book（v2 中删除）、cat（保留）。
    final appleId = _hashId('apple');
    final bookId = _hashId('book');
    final catId = _hashId('cat');
    for (final id in [appleId, bookId, catId]) {
      await db.into(db.userWords).insert(
        UserWordsCompanion.insert(
          userId: const Value(0),
          wordbookId: 1,
          wordId: id,
          state: 'review',
          status: 'review',
          dueDate: Value(DateTime.now().millisecondsSinceEpoch),
          reps: const Value(2),
        ),
      );
    }
    await db.into(db.reviewLogs).insert(
      ReviewLogsCompanion.insert(
        userId: const Value(0),
        wordbookId: 1,
        wordId: bookId,
        rating: 3,
        reviewedAt: DateTime.now().millisecondsSinceEpoch,
        sessionType: 'learning',
      ),
    );
    await db.into(db.sessions).insert(
      SessionsCompanion.insert(
        id: 's1',
        sessionType: 'review',
        createdAt: 1,
        updatedAt: 1,
        position: const Value(0),
      ),
    );
    await db.into(db.sessionItems).insert(
      SessionItemsCompanion.insert(
        sessionId: 's1',
        wordId: bookId,
        seq: 0,
        requeueLeft: const Value(2),
      ),
    );
    await db.into(db.dailyStats).insert(
      DailyStatsCompanion.insert(
        day: '2026-08-12',
        newCount: const Value(1),
        reviewCount: const Value(1),
        correctCount: const Value(1),
        completed: const Value(0),
      ),
    );

    final packV2 = File('${tempDir.path}/v2.db');
    writePackFile(packV2, version: '2.0', words: ['apple', 'cat', 'dog']);
    final result = await importer.importFromFile(packV2);

    expect(result.changed, isTrue);
    expect(result.version, '2.0');
    expect(result.userWordsPreserved, 2);
    expect(result.userWordsDropped, 1);

    final userWords = await db.select(db.userWords).get();
    expect(userWords.map((r) => r.wordId).toSet(), {appleId, catId});
    expect(userWords, hasLength(2));
    // 备份文件已写入且可解析（TECH_DOC §8.2 升级前备份用户表）。
    // 首次导入与升级各写一份备份；升级前那份文件名带旧版本号。
    expect(backupWriter.written, hasLength(2));
    expect(backupWriter.written.last.path, contains('backup_1.0_'));
    final backupJson = jsonDecode(
      await backupWriter.written.last.readAsString(),
    ) as Map<String, dynamic>;
    expect(backupJson['user_words'], hasLength(3));
    expect(backupJson['daily_stats'], hasLength(1));
    // 会话队列项：book 被移除，apple/cat 保留（本测试只插入了 book 项）。
    final sessionItems = await db.select(db.sessionItems).get();
    expect(sessionItems, isEmpty);
    // 复习日志是追加历史：词被移除仍保留原 word_id（T-06 导出可追溯）。
    final logs = await db.select(db.reviewLogs).get();
    expect(logs, hasLength(1));
    expect(logs.single.wordId, bookId);
  });

  test('坏包拒绝：缺 meta / schema 版本不符 / 缺表', () async {
    final bad = File('${tempDir.path}/bad.db');
    final dbc = sqlite.sqlite3.open(bad.path);
    dbc.execute('CREATE TABLE words (id INTEGER PRIMARY KEY, word TEXT)');
    dbc.close();
    await expectLater(
      importer.importFromFile(bad),
      throwsA(isA<WordbookPackException>()),
    );

    final badVersion = File('${tempDir.path}/bad_version.db');
    writePackFile(badVersion, version: '9.9', words: ['apple']);
    final dbc2 = sqlite.sqlite3.open(badVersion.path);
    dbc2.execute("UPDATE meta SET value='2' WHERE key='schema_version'");
    dbc2.close();
    await expectLater(
      importer.importFromFile(badVersion),
      throwsA(isA<WordbookPackException>()),
    );
  });
}
