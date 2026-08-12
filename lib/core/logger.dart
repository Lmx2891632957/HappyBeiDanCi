import 'package:flutter/foundation.dart';

/// 极简日志出口：release 构建不输出 debug 日志。
/// 后续若引入崩溃收集，仅允许采集崩溃堆栈且默认关闭（TECH_DOC §13.1），在此统一接入。
abstract final class AppLogger {
  AppLogger._();

  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[debug] $message');
    }
  }

  static void info(String message) => debugPrint('[info] $message');

  static void warning(String message) => debugPrint('[warning] $message');

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[error] $message');
    if (error != null) {
      debugPrint('  cause: $error');
    }
    if (stackTrace != null) {
      debugPrint('  stack: ${stackTrace.toString().split('\n').take(8).join('\n')}');
    }
  }
}
