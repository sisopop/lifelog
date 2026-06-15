import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/session.dart';
import '../../features/entry_detail/entry_detail_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/people/people_screen.dart';
import '../../features/review/review_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/share/share_screen.dart';
import '../../features/timeline/timeline_screen.dart';
import '../../features/write/write_screen.dart';
import '../../shared/widgets/scaffold_with_nav.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final loggedIn = ref.read(sessionProvider).loggedIn;
      final atLogin = state.matchedLocation == '/login';
      if (!loggedIn) return atLogin ? null : '/login';
      if (atLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/write',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const WriteScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/entry/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => EntryDetailScreen(entryId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'share',
            parentNavigatorKey: _rootKey,
            builder: (_, state) => ShareScreen(entryId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'edit',
            parentNavigatorKey: _rootKey,
            builder: (_, state) => WriteScreen(editId: state.pathParameters['id']!),
          ),
        ],
      ),

      // Branches behind the bottom nav (4 tabs + center +).
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ScaffoldWithNav(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/timeline', builder: (_, _) => const TimelineScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/review', builder: (_, _) => const ReviewScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/people', builder: (_, _) => const PeopleScreen()),
          ]),
        ],
      ),
    ],
  );
});
