/// 词书-词关联领域模型（TECH_DOC §8.1 wordbook_items 表）。
///
/// [shuffled] 为首次进入词书时由确定性种子生成的乱序序号（TD-06），
/// 持久化后新词取用顺序稳定，不因重启/换天漂移。
class WordbookItem {
  const WordbookItem({
    required this.wordbookId,
    required this.wordId,
    required this.seq,
    required this.shuffled,
    required this.isSkipped,
  });

  final int wordbookId;
  final int wordId;

  /// 词表原始顺序。
  final int seq;

  /// 首启乱序后的学习顺序。
  final int shuffled;

  /// 熟词跳过标记（PRD F1）。
  final bool isSkipped;
}
