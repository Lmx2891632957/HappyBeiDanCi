import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_page.dart';
import '../features/learn/learn_page.dart';
import '../features/results/results_page.dart';
import '../features/review/review_page.dart';

/// 路由装配（TECH_DOC §4 补充说明 4）：home/learn/review/results 四路由，
/// 路由命名与页面归属一一对应；Onboarding 直通首页（§4 补充说明 6），
/// 会话页参数经 `extra` 传入（LearnRouteArgs/ReviewRouteArgs）。
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/learn',
        name: 'learn',
        builder: (context, state) => LearnPage(
          args: state.extra as LearnRouteArgs,
        ),
      ),
      GoRoute(
        path: '/review',
        name: 'review',
        builder: (context, state) => ReviewPage(
          args: state.extra as ReviewRouteArgs,
        ),
      ),
      GoRoute(
        path: '/results',
        name: 'results',
        builder: (context, state) => const ResultsPage(),
      ),
    ],
  );
});
