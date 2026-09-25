import 'package:go_router/go_router.dart';

import '../features/shell/presentation/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => const AppShell(tab: 'home'),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) =>
          AppShell(tab: 'search', searchQuery: state.uri.queryParameters['q']),
    ),
    GoRoute(
      path: '/library',
      builder: (context, state) => const AppShell(tab: 'library'),
    ),
    GoRoute(
      path: '/feed',
      builder: (context, state) => const AppShell(tab: 'feed'),
    ),
    GoRoute(path: '/', redirect: (_, __) => '/home'),
  ],
);
