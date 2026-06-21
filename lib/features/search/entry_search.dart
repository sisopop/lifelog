import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
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

/// Pure: keep only entries whose mood equals [mood]. A null [mood] means
/// "all moods" and returns the list unchanged.
List<DiaryEntry> filterByMood(List<DiaryEntry> entries, Mood? mood) {
  if (mood == null) return entries;
  return entries.where((e) => e.mood == mood).toList();
}

/// Pure: keep only entries from [journalId]. A null [journalId] means
/// "all journals" and returns the list unchanged.
List<DiaryEntry> filterByJournal(List<DiaryEntry> entries, String? journalId) {
  if (journalId == null) return entries;
  return entries.where((e) => e.journalId == journalId).toList();
}

/// Pure: when [onlyFavorites] is true keep only starred entries; otherwise
/// returns the list unchanged.
List<DiaryEntry> filterByFavorite(
    List<DiaryEntry> entries, bool onlyFavorites) {
  if (!onlyFavorites) return entries;
  return entries.where((e) => e.isFavorite).toList();
}

/// Current search query (updated as the user types).
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Optional mood filter applied on top of the text results (null = 전체).
class SearchMoodNotifier extends Notifier<Mood?> {
  @override
  Mood? build() => null;

  /// Selects [mood], or clears the filter when the same mood is tapped again.
  void toggle(Mood mood) => state = state == mood ? null : mood;

  void clear() => state = null;
}

final searchMoodProvider =
    NotifierProvider<SearchMoodNotifier, Mood?>(SearchMoodNotifier.new);

/// Optional journal filter applied on top of the text results (null = 전체).
class SearchJournalNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Selects [journalId], or clears the filter when the same one is tapped.
  void toggle(String journalId) =>
      state = state == journalId ? null : journalId;

  void clear() => state = null;
}

final searchJournalProvider =
    NotifierProvider<SearchJournalNotifier, String?>(SearchJournalNotifier.new);

/// Whether results are scoped to favorites only (false = 전체).
class SearchFavoriteNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;

  void clear() => state = false;
}

final searchFavoriteProvider =
    NotifierProvider<SearchFavoriteNotifier, bool>(SearchFavoriteNotifier.new);

/// Search results derived from [entriesProvider], the current query and the
/// optional mood, journal and favorite filters.
final searchResultsProvider = Provider<List<DiaryEntry>>((ref) {
  final all = ref.watch(entriesProvider).asData?.value ?? const <DiaryEntry>[];
  final query = ref.watch(searchQueryProvider);
  final mood = ref.watch(searchMoodProvider);
  final journalId = ref.watch(searchJournalProvider);
  final onlyFavorites = ref.watch(searchFavoriteProvider);
  return filterByFavorite(
    filterByJournal(filterByMood(searchEntries(all, query), mood), journalId),
    onlyFavorites,
  );
});
