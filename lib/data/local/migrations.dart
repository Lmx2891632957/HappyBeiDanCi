import 'package:drift/drift.dart';

/// 数据库 schema 版本常量。
abstract final class AppSchemaVersion {
  AppSchemaVersion._();

  /// v1：TECH_DOC §8.1 全量表结构与索引（2026-08-12 初始版本）。
  static const int current = 1;
}

/// 构建迁移策略：开启 WAL 并提供版本化升级入口。
///
/// 为什么单独成文件：每次 schema 变更在此追加“变更原因 + 影响范围”注释与
/// 迁移步骤（AGENTS §6.3 数据库变更必须带迁移脚本与降级说明），
/// 避免把迁移历史堆进数据库类。
MigrationStrategy buildMigrationStrategy(GeneratedDatabase db) {
  return MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // v1 为初始 schema，暂无历史迁移；后续按版本递增追加：
      // if (from < 2) { await m.addColumn(...); }。
      // 注意：词库升级（words 整体替换）不走 schema 迁移，而走内容版本替换
      // 流程（TECH_DOC §8.2：word_id 以 word 文本 + 版本映射，升级前备份用户表）。
    },
    beforeOpen: (details) async {
      // WAL：读多写少场景避免读写互相阻塞，并保证批量事务的崩溃一致性
      //（TECH_DOC §8.2 / §12 性能设计）。
      await db.customStatement('PRAGMA journal_mode=WAL');
    },
  );
}
