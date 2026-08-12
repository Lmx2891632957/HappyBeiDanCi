import 'package:drift/drift.dart';

/// 词条表（TECH_DOC §8.1）：内容静态数据，词库升级时整体替换。
@DataClassName('WordRow')
class Words extends Table {
  IntColumn get id => integer()();
  TextColumn get word => text().unique()();
  TextColumn get phonetic => text()();
  TextColumn get phoneticUk => text().nullable()();
  TextColumn get meanings => text()();
  TextColumn get examples => text()();
  TextColumn get frequency => text()();
  TextColumn get rootAffix => text().nullable()();
  TextColumn get audioKey => text()();
  TextColumn get audioUrl => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
