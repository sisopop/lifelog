import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/diary_entry.dart';
import '../entries/entries_provider.dart';

/// Pure, case-insensitive search over top-level entries.
///
/// Matches the [query] against the title, content, AI summary and tags.
/// Replies (entries with a [DiaryEntry.replyToEntryId]) are excluded so the
/// results mirror the timeline. Results are sorted newest-first.
/// An empty/blank query returns an empty list.
List<DiaryEntry> searchEntries(List<DiaryEntry> entries, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final matches = entries.where((e) {
    if (e.replyToEntryId != null) return false;
    if ((e.title ?? '').toLowerCase().contains(q)) return true;
    if (e.content.toLowerCase().contains(q)) return true;
    if ((e.aiSummary ?? '').toLowerCase().contains(q)) return true;
    if (e.tags.any((t) => t.toLowerCase().contains(q))) return true;
    return false;
  }).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return matches;
}

/// Current search query (updated as the user types).
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Search results derived from [entriesProvider] and the current query.
final searchResultsProvider = Provider<List<DiaryEntry>>((ref) {
  final all = ref.watch(entriesProvider).asData?.value ?? const <DiaryEntry>[];
  final query = ref.watch(searchQueryProvider);
  return searchEntries(all, query);
});
