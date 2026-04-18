import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/movie.dart';
import 'screens/detail_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'models/player_args.dart';
import 'screens/player_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';
import 'widgets/bottom_nav_bar.dart';

/// 全局路由：底部五 Tab + 全屏详情/播放页
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(shell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (c, s) =>
                    const NoTransitionPage<void>(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                pageBuilder: (c, s) =>
                    const NoTransitionPage<void>(child: SearchScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                pageBuilder: (c, s) =>
                    const NoTransitionPage<void>(child: HistoryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/downloads',
                pageBuilder: (c, s) =>
                    const NoTransitionPage<void>(child: DownloadsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (c, s) =>
                    const NoTransitionPage<void>(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/detail',
        builder: (c, s) => DetailScreen(movie: s.extra! as Movie),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/player',
        builder: (c, s) => PlayerScreen(args: s.extra! as PlayerArgs),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/favorites',
        builder: (c, s) => const FavoritesScreen(),
      ),
    ],
  );
}

/// 底部导航外壳
class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: shell.currentIndex,
        onTap: shell.goBranch,
      ),
    );
  }
}
