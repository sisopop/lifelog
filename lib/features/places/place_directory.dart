import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';

/// Pure: every distinct location across top-level records with its usage
/// count, most-used first (ties broken alphabetically). Replies are excluded
/// so the counts mirror the timeline. Locations are grouped case-insensitively
/// (trimmed); the first-seen spelling is kept for display. Records without a
/// location are ignored.
List<MapEntry<String, int>> placeCountsSorted(List<DiaryEntry> entries) {
  final counts = <String, int>{};
  final display = <String, String>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    final loc = (e.location ?? '').trim();
    if (loc.isEmpty) continue;
    final key = loc.toLowerCase();
    counts[key] = (counts[key] ?? 0) + 1;
    display.putIfAbsent(key, () => loc);
  }
  final list = counts.entries
      .map((e) => MapEntry(display[e.key]!, e.value))
      .toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  return list;
}

/// Pure: how many distinct locations were visited in one calendar month.
/// Filters [entries] to the given [year]/[month], then reuses
/// [placeCountsSorted] (replies and blank locations excluded, grouped
/// case-insensitively). Returns 0 when that month has no located records.
int distinctPlacesOfMonth(List<DiaryEntry> entries, int year, int month) {
  final monthly = entries.where(
      (e) => e.createdAt.year == year && e.createdAt.month == month);
  return placeCountsSorted(monthly.toList()).length;
}

/// Pure: how many distinct locations were ever visited across all [entries].
/// Reuses [placeCountsSorted] (replies and blank locations excluded, grouped
/// case-insensitively). Returns 0 when nothing is located — the whole-history
/// sibling of [distinctPlacesOfMonth].
int distinctPlacesVisited(List<DiaryEntry> entries) =>
    placeCountsSorted(entries).length;

/// Pure: the most-recent top-level record date for each location, keyed by the
/// location's display spelling (matching [placeCountsSorted]). Replies and
/// blank locations are ignored. Locations are grouped case-insensitively.
Map<String, DateTime> lastVisitByPlace(List<DiaryEntry> entries) {
  final latest = <String, DateTime>{};
  final display = <String, String>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    final loc = (e.location ?? '').trim();
    if (loc.isEmpty) continue;
    final key = loc.toLowerCase();
    display.putIfAbsent(key, () => loc);
    final cur = latest[key];
    if (cur == null || e.createdAt.isAfter(cur)) latest[key] = e.createdAt;
  }
  return {for (final k in latest.keys) display[k]!: latest[k]!};
}

/// Pure: the dominant (most-recorded) mood for each location, keyed by the
/// location's display spelling (matching [placeCountsSorted]). Replies, blank
/// locations and moodless records are ignored. Locations are grouped
/// case-insensitively. A place with no mood-bearing records is omitted; ties
/// resolve to the earlier [Mood.values] entry.
Map<String, Mood> dominantMoodByPlace(List<DiaryEntry> entries) {
  final counts = <String, Map<Mood, int>>{};
  final display = <String, String>{};
  for (final e in entries) {
    if (e.replyToEntryId != null || e.mood == null) continue;
    final loc = (e.location ?? '').trim();
    if (loc.isEmpty) continue;
    final key = loc.toLowerCase();
    display.putIfAbsent(key, () => loc);
    final byMood = counts.putIfAbsent(key, () => <Mood, int>{});
    byMood.update(e.mood!, (c) => c + 1, ifAbsent: () => 1);
  }
  final result = <String, Mood>{};
  for (final entry in counts.entries) {
    Mood? best;
    var bestCount = 0;
    for (final m in Mood.values) {
      final c = entry.value[m] ?? 0;
      if (c > bestCount) {
        bestCount = c;
        best = m;
      }
    }
    if (best != null) result[display[entry.key]!] = best;
  }
  return result;
}
