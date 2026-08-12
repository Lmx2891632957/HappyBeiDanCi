import 'package:drift/drift.dart';

/// 离线音频包下载状态表（TECH_DOC §8.1 / §9.2）。
@DataClassName('AudioPackRow')
class AudioPacks extends Table {
  IntColumn get wordbookId => integer()();
  TextColumn get version => text()();
  TextColumn get status => text()();
  IntColumn get totalSize => integer().nullable()();
  IntColumn get downloadedSize => integer().nullable()();
  IntColumn get fileCount => integer().nullable()();
  IntColumn get updatedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {wordbookId};
}
