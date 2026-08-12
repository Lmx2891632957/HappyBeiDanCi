import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/providers.dart';

/// 启动页（TECH_DOC §5.1 首启判定）：等待 [onboardingGateProvider] 读取设置，
/// 未完成引导 → `/onboarding`，已完成 → `/`（今日任务页）。
///
/// 设置读取为异步，本页兜住首帧，避免今日页在标记就绪前闪屏/重复初始化
/// （TECH_DOC §12 启动到首卡 < 2s）；加载失败提供重试。
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(onboardingGateProvider);
    if (current.hasValue) {
      _go(current.value!);
    } else {
      ref.listenManual(onboardingGateProvider, (previous, next) {
        if (next.hasValue) {
          _go(next.value!);
        }
      });
    }
  }

  /// 首帧导航延后到 build 之后，避免在构建期间触发路由变更；
  /// `_navigated` 保证加载完成与监听回调不会重复导航。
  void _go(bool onboardingDone) {
    if (_navigated) {
      return;
    }
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go(onboardingDone ? '/' : '/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gate = ref.watch(onboardingGateProvider);
    return Scaffold(
      body: Center(
        child: gate.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.onboardingLoadFailed('$error'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(onboardingGateProvider),
                  child: Text(l10n.homeRetry),
                ),
              ],
            ),
          ),
          // 已就绪：导航已由 _go 触发，这里无需渲染内容。
          data: (_) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
