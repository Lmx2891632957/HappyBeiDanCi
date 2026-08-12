import 'package:drift/drift.dart';

/// 词书-词关联表（TECH_DOC §8.1）：含词表原始顺序与首启乱序序号（TD-06）。
@DataClassName('WordbookItemRow')
class WordbookItems extends Table {
  IntColumn get wordbookId => integer()();
  IntColumn get wordId => integer()();
  IntColumn get seq => integer()();
  IntColumn get shuffled => integer()();
  BoolColumn get isSkipped => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {wordbookId, wordId};
}
