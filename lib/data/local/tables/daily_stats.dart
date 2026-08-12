import 'package:drift/drift.dart';

/// 每日统计表（TECH_DOC §8.1）：打卡与统计页数据，按天 upsert。
@DataClassName('DailyStatRow')
class DailyStats extends Table {
  TextColumn get day => text()();
  IntColumn get newCount => integer().withDefault(const Constant(0))();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get completed => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {day};
}
