import 'package:flutter/material.dart';

/// 明暗两套 Material 3 主题，随系统 themeMode 切换（PRD F7 深色模式进 M1）。
abstract final class AppTheme {
  AppTheme._();

  /// 学习类应用的识别色：稳定、偏冷静的靛蓝。
  static const Color _seed = Color(0xFF4C6FFF);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
  );
}
