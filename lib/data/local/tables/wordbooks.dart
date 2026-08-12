import 'package:drift/drift.dart';

/// 词书表（TECH_DOC §8.1）。
///
/// 词库静态数据随发布版词库 DB 导入，不在源码仓库内维护。
@DataClassName('WordbookRow')
class Wordbooks extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get level => text().withLength(min: 1, max: 20)();
  IntColumn get totalCount => integer()();
  TextColumn get source => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
