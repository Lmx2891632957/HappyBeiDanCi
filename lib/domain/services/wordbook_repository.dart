import '../models/word.dart';
import '../models/wordbook.dart';
import '../models/wordbook_item.dart';

/// 词书/词条仓储契约。
///
/// 设计意图：接口定义在 domain（数据契约向上），实现放在 data/repositories，
/// 保证 domain 不依赖 data 层（AGENTS §3.2）；UI 只通过本接口读写词库。
abstract interface class WordbookRepository {
  Future<Wordbook?> getWordbookById(int id);

  Future<List<Wordbook>> getWordbooks();

  Future<WordbookItem?> getItem({required int wordbookId, required int wordId});

  /// 按学习顺序分页取**尚未学习**的词（TECH_DOC §8.3）。
  ///
  /// 排序：同频段内（high→medium→low）按 `shuffled` 递增；仅返回无 `user_words`
  /// 行且 `is_skipped = 0` 的词，[offset]/[limit] 作用于过滤后的新词序列——
  /// 学习会话按“待学新词数”直接取前 N 个即得到下次要学的词，进度不漂移。
  Future<List<Word>> getWordsByBook(int wordbookId, {int limit = 50, int offset = 0});

  /// 词书剩余新词数（与 [getWordsByBook] 同一过滤口径），供今日任务页
  /// “词书剩余新词”展示与每日计划计算（TECH_DOC §5.1/§6.1）。
  Future<int> countRemainingNewWords(int wordbookId);

  /// 批量按 ID 取词，返回顺序与 [wordIds] 一致（缺失的 ID 跳过）。
  ///
  /// 会话页卡片展示用：复习队列的词已学习、不在 [getWordsByBook] 结果内，
  /// 需要按任意 ID 取词，避免逐词查询（TECH_DOC §12 性能）。
  Future<List<Word>> getWordsByIds(List<int> wordIds);

  /// 按词书返回**全量**词条（含已学/已跳过），供熟词快筛页分页加载
  /// （TECH_DOC §8.3 熟词跳过口径）。
  Future<List<Word>> getAllWordsByBook(
    int wordbookId, {
    int limit = 100,
    int offset = 0,
  });

  /// 按单词包含匹配搜索词书内词条（`%`/`_` 按字面转义），供快筛搜索。
  Future<List<Word>> searchWordsByBook(
    int wordbookId,
    String query, {
    int limit = 100,
  });

  /// 已标记已掌握词的 ID 集合（PRD F1 熟词跳过）。
  Future<Set<int>> getSkippedWordIds(int wordbookId);

  /// 单词写入熟词跳过标记（不影响 user_words 与复习队列，§8.3）。
  Future<void> setSkipped({
    required int wordbookId,
    required int wordId,
    required bool skipped,
  });

  /// 批量标记/清除整本词书（快筛页「全部标记/清除」）。
  Future<void> setAllSkipped(int wordbookId, {required bool skipped});
}
