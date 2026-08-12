import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';

/// 数据库实例：Provider 惰性求值，应用启动时首页先渲染骨架、
/// 不等待磁盘 IO（TECH_DOC §12 启动到首卡 < 2s）。
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
