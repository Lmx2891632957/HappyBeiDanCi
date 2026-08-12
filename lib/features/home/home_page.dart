import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';

/// 今日任务页占位：仅用于验证主题/路由/国际化装配链路。
/// 今日计划计算（新词 + 复习软上限）属于业务逻辑，在 home 功能开发时实现。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(child: Text(l10n.homeSkeletonReady)),
    );
  }
}
