import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/about/about_page.dart';
import '../features/home/home_page.dart';
import '../features/learn/learn_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/onboarding/skip_known_words_page.dart';
import '../features/onboarding/splash_page.dart';
import '../features/results/results_page.dart';
import '../features/review/review_page.dart';
import '../features/settings/settings_page.dart';

/// 路由装配（TECH_DOC §4 补充说明 4/8）：splash/onboarding/home/learn/review/
/// results/settings/about 八路由。启动经 `/splash` 首帧判定（§5.1）：首启未完成 → `/onboarding`
/// （选词书 → 设每日目标 → 开始），已完成 → `/`（今日任务页）；会话页参数经
/// `extra` 传入（LearnRouteArgs/ReviewRouteArgs）。
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // Splash 兜住异步首启判定（读设置），避免今日页在标记就绪前闪屏/重复初始化。
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/onboarding/skip',
        name: 'skip-known-words',
        builder: (context, state) =>
            SkipKnownWordsPage(wordbookId: state.extra as int),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/learn',
        name: 'learn',
        builder: (context, state) =>
            LearnPage(args: state.extra as LearnRouteArgs),
      ),
      GoRoute(
        path: '/review',
        name: 'review',
        builder: (context, state) =>
            ReviewPage(args: state.extra as ReviewRouteArgs),
      ),
      GoRoute(
        path: '/results',
        name: 'results',
        builder: (context, state) => const ResultsPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutPage(),
      ),
    ],
  );
});
