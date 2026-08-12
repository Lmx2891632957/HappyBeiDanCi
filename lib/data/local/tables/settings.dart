import 'package:drift/drift.dart';

/// 设置表（TECH_DOC §8.1）：通用键值对。
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
