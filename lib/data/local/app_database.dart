import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'migrations.dart';
import 'tables/audio_packs.dart';
import 'tables/daily_stats.dart';
import 'tables/review_logs.dart';
import 'tables/session_items.dart';
import 'tables/sessions.dart';
import 'tables/settings.dart';
import 'tables/user_words.dart';
import 'tables/wordbook_items.dart';
import 'tables/wordbooks.dart';
import 'tables/words.dart';

part 'app_database.g.dart';

/// 应用数据库：词库静态表（wordbooks/words/wordbook_items）与用户数据表分离，
/// 保证词库升级整体替换内容表时不破坏用户进度（TECH_DOC §8.2）。
@DriftDatabase(
  tables: [
    AudioPacks,
    DailyStats,
    ReviewLogs,
    SessionItems,
    Sessions,
    Settings,
    UserWords,
    WordbookItems,
    Wordbooks,
    Words,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试专用：注入内存等自定义 executor，避免触碰平台数据库目录。
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => AppSchemaVersion.current;

  @override
  MigrationStrategy get migration => buildMigrationStrategy(this);
}

/// 延迟打开连接：启动时不阻塞首帧渲染（TECH_DOC §12 启动到首卡 < 2s）。
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // drift_flutter 负责平台数据库目录与原生 sqlite3 库；Drift 内部单一
    // executor 天然满足“单写连接 + WAL”约束（TECH_DOC §8.2）。
    return driftDatabase(name: 'happy_bei_dan_ci');
  });
}
