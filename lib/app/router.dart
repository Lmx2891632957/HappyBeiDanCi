import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_page.dart';

/// 路由装配：骨架阶段仅注册首页；Onboarding/学习/复习等页面在对应功能开发时
/// 按 `features/<feature>` 追加，路由命名与页面归属一一对应。
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
});
