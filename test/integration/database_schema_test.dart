import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('happy_beidanci_db_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('v1 schema 创建全部表、索引并启用 WAL', () async {
    final db = AppDatabase.forTesting(
      NativeDatabase(File('${tempDir.path}/test.db')),
    );
    addTearDown(db.close);

    // TECH_DOC §8.1 的十张表均可查询（空表不抛错）。
    expect(await db.select(db.audioPacks).get(), isEmpty);
    expect(await db.select(db.dailyStats).get(), isEmpty);
    expect(await db.select(db.reviewLogs).get(), isEmpty);
    expect(await db.select(db.sessionItems).get(), isEmpty);
    expect(await db.select(db.sessions).get(), isEmpty);
    expect(await db.select(db.settings).get(), isEmpty);
    expect(await db.select(db.userWords).get(), isEmpty);
    expect(await db.select(db.wordbookItems).get(), isEmpty);
    expect(await db.select(db.wordbooks).get(), isEmpty);
    expect(await db.select(db.words).get(), isEmpty);

    // §8.1 定义的三条索引。
    final indexes = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'",
        )
        .get();
    final indexNames = indexes.map((row) => row.data['name']).toSet();
    expect(indexNames, containsAll(['idx_user_words_due', 'idx_review_logs_time', 'idx_session_items']));

    // beforeOpen 已执行 PRAGMA journal_mode=WAL（TECH_DOC §8.2）。
    final journalMode = await db.customSelect('PRAGMA journal_mode').getSingle();
    expect(journalMode.data['journal_mode'], 'wal');
  });
}
