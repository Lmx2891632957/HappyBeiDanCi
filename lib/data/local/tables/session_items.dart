import 'package:drift/drift.dart';

/// 会话队列项表（TECH_DOC §8.1）：队列顺序与剩余重排次数。
@TableIndex(name: 'idx_session_items', columns: {#sessionId, #seq})
@DataClassName('SessionItemRow')
class SessionItems extends Table {
  TextColumn get sessionId => text()();
  IntColumn get wordId => integer()();
  IntColumn get seq => integer()();
  IntColumn get requeueLeft => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {sessionId, wordId};
}
