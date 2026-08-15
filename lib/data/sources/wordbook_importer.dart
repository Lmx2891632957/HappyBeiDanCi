/// 发布版词库导入器（TECH_DOC §8.2）。
///
/// 校验发布版 DB（meta.schema_version / wordlist_version）后，在同一事务内
/// 整体替换 wordbooks/words/wordbook_items，并按「word 文本」映射 remap 用户
/// 行（user_words / session_items / review_logs），升级前把用户表导出为 JSON
/// 备份（生产环境写应用私有目录，测试注入临时目录）。
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../core/constants.dart';
import '../local/app_database.dart';

/// 词库导入结果（幂等 no-op 时 [changed] 为 false）。
class WordbookImportResult {
  const WordbookImportResult({
    required this.version,
    required this.wordCount,
    required this.changed,
    required this.userWordsPreserved,
    required this.userWordsDropped,
  });

  /// 发布包内容版本（meta.wordlist_version）。
  final String version;
  final int wordCount;

  /// 是否实际替换内容（同版本重复导入为 false）。
  final bool changed;

  /// 升级时保留/移除的 user_words 行数（首次导入恒为 0）。
  final int userWordsPreserved;
  final int userWordsDropped;
}

/// 升级备份写入接口：生产用应用私有目录，测试注入临时目录（保持可测性）。
abstract interface class BackupWriter {
  Future<File> write({required String name, required String content});
}

/// 默认备份写入器：应用私有支持目录 `backups/`（不暴露给系统相册/下载）。
class AppSupportBackupWriter implements BackupWriter {
  @override
  Future<File> write({required String name, required String content}) async {
    final dir = await getApplicationSupportDirectory();
    final backups = Directory('${dir.path}/backups');
    await backups.create(recursive: true);
    final file = File('${backups.path}/$name');
    return file.writeAsString(content, flush: true);
  }
}

/// 发布版词库 DB 校验异常（缺 meta / schema 版本不符时抛出，拒绝导入）。
class WordbookPackException implements Exception {
  const WordbookPackException(this.message);
  final String message;

  @override
  String toString() => 'WordbookPackException: $message';
}

/// 发布版词库导入器（TECH_DOC §8.2 实现口径）。
class WordbookImporter {
  WordbookImporter(this._db, {BackupWriter? backupWriter})
    : _backupWriter = backupWriter ?? AppSupportBackupWriter();

  final AppDatabase _db;
  final BackupWriter _backupWriter;

  /// 导入发布版词库 DB 文件；同版本幂等 no-op。
  Future<WordbookImportResult> importFromFile(File packFile) async {
    final pack = _PackDb.open(packFile);
    try {
      final current = await _readWordbookVersion();
      if (current == pack.version) {
        return WordbookImportResult(
          version: pack.version,
          wordCount: pack.words.length,
          changed: false,
          userWordsPreserved: 0,
          userWordsDropped: 0,
        );
      }

      // 先备份用户表再动内容表；备份失败中止，避免"内容已换、进度无备份"。
      final backup = await _collectUserTables();
      final backupName =
          'wordbook_upgrade_backup_${current ?? 'none'}_'
          '${DateTime.now().millisecondsSinceEpoch}.json';
      await _backupWriter.write(
        name: backupName,
        content: const JsonEncoder.withIndent('  ').convert(backup),
      );

      return await _db.transaction(() async {
        final oldWordMap = await _readWordMap();
        await _db.delete(_db.wordbookItems).go();
        await _db.delete(_db.words).go();
        await _db.delete(_db.wordbooks).go();
        await _insertPack(pack);
        final newWordMap = await _readWordMap();
        final preserved = await _remapUserWords(oldWordMap, newWordMap, pack);
        await _remapSessionItems(oldWordMap, newWordMap);
        await _remapReviewLogs(oldWordMap, newWordMap);
        await _writeWordbookVersion(pack.version);
        return WordbookImportResult(
          version: pack.version,
          wordCount: pack.words.length,
          changed: true,
          userWordsPreserved: preserved.preserved,
          userWordsDropped: preserved.dropped,
        );
      });
    } finally {
      pack.close();
    }
  }

  Future<String?> _readWordbookVersion() async {
    final row = await (_db.select(
      _db.settings,
    )..where((t) => t.key.equals(AppSettingKeys.wordbookVersion)))
        .getSingleOrNull();
    final raw = row?.value;
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  Future<void> _writeWordbookVersion(String version) {
    return _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(
            key: AppSettingKeys.wordbookVersion,
            value: version,
          ),
        );
  }

  /// 读取 words 表 id → word 文本映射（升级 remap 的旧/新侧）。
  Future<Map<int, String>> _readWordMap() async {
    final rows = await _db.select(_db.words).get();
    return {for (final r in rows) r.id: r.word};
  }

  Future<Map<String, Object>> _collectUserTables() async {
    final userWords = await _db.select(_db.userWords).get();
    final reviewLogs = await _db.select(_db.reviewLogs).get();
    final sessions = await _db.select(_db.sessions).get();
    final sessionItems = await _db.select(_db.sessionItems).get();
    final dailyStats = await _db.select(_db.dailyStats).get();
    return {
      'user_words': [
        for (final r in userWords)
          {
            'user_id': r.userId,
            'wordbook_id': r.wordbookId,
            'word_id': r.wordId,
            'state': r.state,
            'status': r.status,
            'due_date': r.dueDate,
            'stability': r.stability,
            'difficulty': r.difficulty,
            'reps': r.reps,
            'lapses': r.lapses,
            'last_review_at': r.lastReviewAt,
            'last_rating': r.lastRating,
            'elapsed_days': r.elapsedDays,
            'scheduled_days': r.scheduledDays,
          },
      ],
      'review_logs': [
        for (final r in reviewLogs)
          {
            'id': r.id,
            'user_id': r.userId,
            'wordbook_id': r.wordbookId,
            'word_id': r.wordId,
            'rating': r.rating,
            'reviewed_at': r.reviewedAt,
            'interval_days': r.intervalDays,
            'stability': r.stability,
            'difficulty': r.difficulty,
            'session_id': r.sessionId,
            'session_type': r.sessionType,
          },
      ],
      'sessions': [
        for (final r in sessions)
          {
            'id': r.id,
            'session_type': r.sessionType,
            'created_at': r.createdAt,
            'updated_at': r.updatedAt,
            'position': r.position,
          },
      ],
      'session_items': [
        for (final r in sessionItems)
          {
            'session_id': r.sessionId,
            'word_id': r.wordId,
            'seq': r.seq,
            'requeue_left': r.requeueLeft,
          },
      ],
      'daily_stats': [
        for (final r in dailyStats)
          {
            'day': r.day,
            'new_count': r.newCount,
            'review_count': r.reviewCount,
            'correct_count': r.correctCount,
            'completed': r.completed,
          },
      ],
    };
  }

  Future<void> _insertPack(_PackDb pack) {
    return _db.batch((batch) {
      for (final b in pack.wordbooks) {
        batch.insert(
          _db.wordbooks,
          WordbooksCompanion.insert(
            id: Value(b['id'] as int),
            name: b['name'] as String,
            level: b['level'] as String,
            totalCount: b['total_count'] as int,
            source: b['source'] as String,
            sortOrder: Value(b['sort_order'] as int),
            createdAt: b['created_at'] as int,
          ),
        );
      }
      for (final w in pack.words) {
        batch.insert(
          _db.words,
          WordsCompanion.insert(
            id: Value(w['id'] as int),
            word: w['word'] as String,
            phonetic: w['phonetic'] as String,
            phoneticUk: Value(w['phonetic_uk'] as String?),
            meanings: w['meanings'] as String,
            examples: w['examples'] as String,
            frequency: w['frequency'] as String,
            rootAffix: Value(w['root_affix'] as String?),
            audioKey: w['audio_key'] as String,
            audioUrl: Value(w['audio_url'] as String?),
            createdAt: w['created_at'] as int,
          ),
        );
      }
      for (final item in pack.items) {
        batch.insert(
          _db.wordbookItems,
          WordbookItemsCompanion.insert(
            wordbookId: item['wordbook_id'] as int,
            wordId: item['word_id'] as int,
            seq: item['seq'] as int,
            shuffled: item['shuffled'] as int,
            isSkipped: Value((item['is_skipped'] as int) != 0),
          ),
        );
      }
    });
  }

  /// 按 word 文本 remap user_words：新版本仍存在的词保留进度并更新 word_id，
  /// 已删除的词移除对应行（记录计数）；同事务内完成（§8.2 映射策略）。
  Future<({int preserved, int dropped})> _remapUserWords(
    Map<int, String> oldWordMap,
    Map<int, String> newWordMap,
    _PackDb pack,
  ) async {
    final newByText = {
      for (final e in newWordMap.entries) e.value: e.key,
    };
    final bookId = pack.wordbooks.first['id'] as int;
    var preserved = 0;
    var dropped = 0;
    final rows = await _db.select(_db.userWords).get();
    for (final r in rows) {
      final oldText = oldWordMap[r.wordId];
      final newId = oldText == null ? null : newByText[oldText];
      if (newId == null) {
        await (_db.delete(
          _db.userWords,
        )..where(
          (t) =>
              t.userId.equals(r.userId) &
              t.wordbookId.equals(r.wordbookId) &
              t.wordId.equals(r.wordId),
        )).go();
        dropped++;
        continue;
      }
      if (newId != r.wordId) {
        await (_db.update(
          _db.userWords,
        )..where(
          (t) =>
              t.userId.equals(r.userId) &
              t.wordbookId.equals(r.wordbookId) &
              t.wordId.equals(r.wordId),
        )).write(
          UserWordsCompanion(
            wordbookId: Value(bookId),
            wordId: Value(newId),
          ),
        );
      }
      preserved++;
    }
    return (preserved: preserved, dropped: dropped);
  }

  /// 会话快照队列项同样按文本 remap；词已删除则丢弃该项（该会话其余卡保留）。
  Future<void> _remapSessionItems(
    Map<int, String> oldWordMap,
    Map<int, String> newWordMap,
  ) async {
    final newByText = {
      for (final e in newWordMap.entries) e.value: e.key,
    };
    final rows = await _db.select(_db.sessionItems).get();
    for (final r in rows) {
      final oldText = oldWordMap[r.wordId];
      final newId = oldText == null ? null : newByText[oldText];
      if (newId == null) {
        await (_db.delete(
          _db.sessionItems,
        )..where(
          (t) => t.sessionId.equals(r.sessionId) & t.wordId.equals(r.wordId),
        )).go();
        continue;
      }
      if (newId == r.wordId) {
        continue;
      }
      await (_db.update(
        _db.sessionItems,
      )..where(
        (t) => t.sessionId.equals(r.sessionId) & t.wordId.equals(r.wordId),
      )).write(SessionItemsCompanion(wordId: Value(newId)));
    }
  }

  /// 复习日志为追加式历史（T-06），能解析时 remap，不删除（导出可追溯）。
  Future<void> _remapReviewLogs(
    Map<int, String> oldWordMap,
    Map<int, String> newWordMap,
  ) async {
    final newByText = {
      for (final e in newWordMap.entries) e.value: e.key,
    };
    final rows = await _db.select(_db.reviewLogs).get();
    for (final r in rows) {
      final oldText = oldWordMap[r.wordId];
      final newId = oldText == null ? null : newByText[oldText];
      if (newId == null || newId == r.wordId) {
        continue;
      }
      await (_db.update(
        _db.reviewLogs,
      )..where((t) => t.id.equals(r.id))).write(
        ReviewLogsCompanion(wordId: Value(newId)),
      );
    }
  }
}

/// 发布版词库 DB 的只读视图（sqlite3 原生连接，导入后立即关闭）。
class _PackDb {
  _PackDb._(this._db, this.version, this.wordbooks, this.words, this.items);

  final sqlite.Database _db;
  final String version;
  final List<Map<String, Object?>> wordbooks;
  final List<Map<String, Object?>> words;
  final List<Map<String, Object?>> items;

  static _PackDb open(File file) {
    if (!file.existsSync()) {
      throw const WordbookPackException('词库包文件不存在');
    }
    final db = sqlite.sqlite3.open(
      file.path,
      mode: sqlite.OpenMode.readOnly,
    );
    try {
      final tables = {
        for (final row
            in db.select('SELECT name FROM sqlite_master WHERE type=\'table\''))
          row['name'] as String,
      };
      for (final required in const ['meta', 'wordbooks', 'words', 'wordbook_items']) {
        if (!tables.contains(required)) {
          throw WordbookPackException('词库包缺少表: $required');
        }
      }
      final meta = {
        for (final row in db.select('SELECT key, value FROM meta')) row['key'] as String: row['value'] as String,
      };
      final schemaVersion = meta['schema_version'];
      if (schemaVersion != '1') {
        throw WordbookPackException('词库包 schema_version 不兼容: $schemaVersion');
      }
      final version = meta['wordlist_version'];
      if (version == null || version.isEmpty) {
        throw const WordbookPackException('词库包缺少 wordlist_version');
      }
      final wordbooks = db.select('SELECT * FROM wordbooks').toList();
      if (wordbooks.isEmpty) {
        throw const WordbookPackException('词库包不含任何词书');
      }
      return _PackDb._(
        db,
        version,
        wordbooks,
        db.select('SELECT * FROM words').toList(),
        db.select('SELECT * FROM wordbook_items').toList(),
      );
    } catch (_) {
      db.close();
      rethrow;
    }
  }

  void close() => _db.close();
}
