import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/word.dart';
import '../../domain/models/wordbook.dart';
import '../../domain/models/wordbook_item.dart';
import '../../domain/services/wordbook_repository.dart';
import '../local/app_database.dart';

/// 词书/词条仓储实现（Drift，TECH_DOC §8.1 wordbooks/words/wordbook_items）。
///
/// 词库静态数据随发布版词库 DB 导入（§8.2），本实现只读内容表。
/// [getWordsByBook] 按 §8.3 返回“尚未学习”的词（无 `user_words` 行且
/// `is_skipped = 0`），分页作用于过滤后的新词序列；meanings/examples 的 JSON
/// 在数据层解析为领域值类型，domain 不感知存储格式。
class DriftWordbookRepository implements WordbookRepository {
  DriftWordbookRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Wordbook?> getWordbookById(int id) async {
    final row = await (_db.select(
      _db.wordbooks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toWordbook(row);
  }

  @override
  Future<List<Wordbook>> getWordbooks() async {
    final rows = await (_db.select(_db.wordbooks)
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .get();
    return [for (final row in rows) _toWordbook(row)];
  }

  @override
  Future<WordbookItem?> getItem({
    required int wordbookId,
    required int wordId,
  }) async {
    final row = await (_db.select(_db.wordbookItems)
          ..where(
            (t) => t.wordbookId.equals(wordbookId) & t.wordId.equals(wordId),
          ))
        .getSingleOrNull();
    return row == null ? null : _toItem(row);
  }

  @override
  Future<List<Word>> getWordsByBook(
    int wordbookId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final query = _db.select(_db.words).join([
      innerJoin(
        _db.wordbookItems,
        _db.wordbookItems.wordId.equalsExp(_db.words.id),
      ),
      // 排除已学词：user_words 存在该词行即视为已学习（学习/复习/掌握），
      // 不再进入“新词”序列（§8.3 口径）。
      leftOuterJoin(
        _db.userWords,
        _db.userWords.userId.equals(0) &
            _db.userWords.wordbookId.equals(wordbookId) &
            _db.userWords.wordId.equalsExp(_db.words.id),
      ),
    ])
      ..where(_db.wordbookItems.wordbookId.equals(wordbookId))
      ..where(_db.wordbookItems.isSkipped.equals(false))
      ..where(_db.userWords.wordId.isNull())
      ..orderBy([
        // 同频段内优先：high → medium → low（§5.1/§8.3），频段内按 shuffled 递增。
        OrderingTerm(expression: _frequencyRank()),
        OrderingTerm(expression: _db.wordbookItems.shuffled),
      ])
      ..limit(limit, offset: offset);
    final rows = await query.get();
    return [for (final row in rows) _toWord(row.readTable(_db.words))];
  }

  @override
  Future<int> countRemainingNewWords(int wordbookId) async {
    final query = _db.selectOnly(_db.words)
      ..addColumns([countAll()])
      ..join([
        innerJoin(
          _db.wordbookItems,
          _db.wordbookItems.wordId.equalsExp(_db.words.id),
        ),
        leftOuterJoin(
          _db.userWords,
          _db.userWords.userId.equals(0) &
              _db.userWords.wordbookId.equals(wordbookId) &
              _db.userWords.wordId.equalsExp(_db.words.id),
        ),
      ])
      ..where(_db.wordbookItems.wordbookId.equals(wordbookId))
      ..where(_db.wordbookItems.isSkipped.equals(false))
      ..where(_db.userWords.wordId.isNull());
    final row = await query.getSingle();
    return row.read(countAll()) ?? 0;
  }

  @override
  Future<List<Word>> getWordsByIds(List<int> wordIds) async {
    if (wordIds.isEmpty) {
      return const [];
    }
    final rows = await (_db.select(
      _db.words,
    )..where((t) => t.id.isIn(wordIds))).get();
    final byId = {for (final row in rows) row.id: row};
    // 返回顺序与入参一致（缺失的 ID 跳过），便于调用方直接按队列顺序取词。
    return [
      for (final id in wordIds)
        if (byId[id] != null) _toWord(byId[id]!),
    ];
  }

  /// 频段排序键：high=0、medium=1、其余（low）=2。
  Expression<int> _frequencyRank() {
    return _db.words.frequency.caseMatch<int>(
      when: {
        Constant('high'): Constant(0),
        Constant('medium'): Constant(1),
      },
      orElse: const Constant(2),
    );
  }

  Wordbook _toWordbook(WordbookRow row) => Wordbook(
    id: row.id,
    name: row.name,
    level: row.level,
    totalCount: row.totalCount,
    source: row.source,
    sortOrder: row.sortOrder,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  WordbookItem _toItem(WordbookItemRow row) => WordbookItem(
    wordbookId: row.wordbookId,
    wordId: row.wordId,
    seq: row.seq,
    shuffled: row.shuffled,
    isSkipped: row.isSkipped,
  );

  Word _toWord(WordRow row) {
    final frequency = switch (row.frequency) {
      'high' => WordFrequency.high,
      'medium' => WordFrequency.medium,
      'low' => WordFrequency.low,
      _ => throw StateError('words 损坏：未知 frequency=${row.frequency}'),
    };
    return Word(
      id: row.id,
      word: row.word,
      phonetic: row.phonetic,
      phoneticUk: row.phoneticUk,
      meanings: _parseMeanings(row.id, row.meanings),
      examples: _parseExamples(row.id, row.examples),
      frequency: frequency,
      rootAffix: row.rootAffix,
      audioKey: row.audioKey,
      audioUrl: row.audioUrl,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    );
  }

  /// meanings 存储为 JSON 数组（§8.1）：[{"pos":"n.","meaning":"..."}]。
  /// 解析失败抛 StateError（与快照/枚举损坏"不静默"口径一致），避免把坏内容
  /// 当空释义展示。
  List<WordMeaning> _parseMeanings(int wordId, String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          WordMeaning(
            pos: (item as Map<String, dynamic>)['pos'] as String,
            meaning: item['meaning'] as String,
          ),
      ];
    } catch (error) {
      throw StateError('words 损坏：meanings JSON 解析失败（wordId=$wordId）');
    }
  }

  /// examples 存储为 JSON 数组（§8.1）：
  /// [{"en":"...","zh":"...","source":"Tatoeba","attribution":"..."}]。
  List<WordExample> _parseExamples(int wordId, String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          WordExample(
            en: (item as Map<String, dynamic>)['en'] as String,
            zh: item['zh'] as String?,
            source: item['source'] as String,
            attribution: item['attribution'] as String,
            url: item['url'] as String?,
          ),
      ];
    } catch (error) {
      throw StateError('words 损坏：examples JSON 解析失败（wordId=$wordId）');
    }
  }
}
