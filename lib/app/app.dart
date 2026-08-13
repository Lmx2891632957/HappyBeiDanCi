import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../domain/models/app_settings.dart';
import 'l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

/// 应用根组件：装配主题、路由、国际化与全局 Provider（TECH_DOC §4 app/）。
///
/// 界面语言与深色模式由设置驱动（§4 补充说明 8）：`language` 非空时用
/// `Locale(language)` 覆盖系统语言；`themeMode` 默认跟随系统。
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings =
        ref.watch(appSettingsProvider).valueOrNull ?? const AppSettings();
    return MaterialApp.router(
      title: AppConstants.appDisplayName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (settings.themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      locale: settings.language.isEmpty ? null : Locale(settings.language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
