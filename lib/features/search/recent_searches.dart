import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/session.dart';

const _kRecentSearchesKey = 'recent_searches';

/// Max number of recent search terms kept.
const recentSearchesMax = 8;

/// Returns a new list with [query] pushed to the front (most-recent first).
///
/// - Blank/whitespace queries are ignored (returns the list unchanged).
/// - Case-insensitive de-dupe: an existing equal term (ignoring case) is
///   removed first so the freshly typed term — with its own casing — leads.
/// - Capped at [max] entries (oldest dropped).
List<String> addRecentSearch(
  List<String> current,
  String query, {
  int max = recentSearchesMax,
}) {
  final q = query.trim();
  if (q.isEmpty) return current;
  final lower = q.toLowerCase();
  final next = [
    q,
    ...current.where((e) => e.toLowerCase() != lower),
  ];
  if (next.length > max) return next.sublist(0, max);
  return next;
}

/// Returns a new list with [query] removed (case-insensitive).
List<String> removeRecentSearch(List<String> current, String query) {
  final lower = query.trim().toLowerCase();
  return current.where((e) => e.toLowerCase() != lower).toList();
}

/// Persisted list of recent search terms (most-recent first).
class RecentSearchesNotifier extends Notifier<List<String>> {
  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  List<String> build() => _p.getStringList(_kRecentSearchesKey) ?? const [];

  Future<void> add(String query) async {
    final next = addRecentSearch(state, query);
    if (identical(next, state)) return;
    state = next;
    await _p.setStringList(_kRecentSearchesKey, next);
  }

  Future<void> remove(String query) async {
    state = removeRecentSearch(state, query);
    await _p.setStringList(_kRecentSearchesKey, state);
  }

  Future<void> clear() async {
    state = const [];
    await _p.remove(_kRecentSearchesKey);
  }
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
  RecentSearchesNotifier.new,
);
