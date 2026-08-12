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

  /// 按学习顺序（shuffled 递增，同频段内 high→medium→low）分页取词。
  Future<List<Word>> getWordsByBook(int wordbookId, {int limit = 50, int offset = 0});
}
