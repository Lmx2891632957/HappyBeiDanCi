/// 词书领域模型（TECH_DOC §8.1 wordbooks 表）。
///
/// 词书与词条属于词库静态数据，随发布版词库 DB 导入，与用户数据表分离
/// （TECH_DOC §8.2：词库升级整体替换 words，不破坏 user_words 进度）。
class Wordbook {
  const Wordbook({
    required this.id,
    required this.name,
    required this.level,
    required this.totalCount,
    required this.source,
    required this.sortOrder,
    required this.createdAt,
  });

  final int id;
  final String name;

  /// 词书级别：gaokao（高考大纲）/ xkb（新课标）。
  final String level;
  final int totalCount;

  /// 内容来源，如 "ECDICT + 考纲"。
  final String source;
  final int sortOrder;
  final DateTime createdAt;
}
