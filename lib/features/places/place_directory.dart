import '../../shared/models/diary_entry.dart';

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
