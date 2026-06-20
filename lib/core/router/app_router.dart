import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/session.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/entry_detail/entry_detail_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/journals/journal_detail_screen.dart';
import '../../features/journals/new_journal_screen.dart';
import '../../features/people/people_screen.dart';
import '../../features/places/place_entries_screen.dart';
import '../../features/review/day_entries_screen.dart';
import '../../features/review/review_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/share/share_screen.dart';
import '../../features/tags/tag_entries_screen.dart';
import '../../features/tags/tag_manage_screen.dart';
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
        builder: (_, state) {
          final qp = state.uri.queryParameters;
          return WriteScreen(
            journalId: qp['journalId'],
            authorId: qp['authorId'],
            advanceTurn: qp['advance'] == '1',
          );
        },
      ),
      GoRoute(
        path: '/journal/new',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const NewJournalScreen(),
      ),
      GoRoute(
        path: '/journal/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            JournalDetailScreen(journalId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SearchScreen(),
      ),
      GoRoute(
        path: '/favorites',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/calendar',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/day/:date', // date = yyyy-MM-dd
        parentNavigatorKey: _rootKey,
        builder: (_, state) => DayEntriesScreen(
          day: DateTime.parse(state.pathParameters['date']!),
        ),
      ),
      GoRoute(
        path: '/tag',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            TagEntriesScreen(tag: state.uri.queryParameters['t'] ?? ''),
      ),
      GoRoute(
        path: '/place',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            PlaceEntriesScreen(location: state.uri.queryParameters['l'] ?? ''),
      ),
      GoRoute(
        path: '/tags/manage',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const TagManageScreen(),
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
