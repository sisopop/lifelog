import '../../shared/models/diary_entry.dart';

/// Top-level records tagged with [tag], newest first.
/// 답장(reply) records are excluded so the list mirrors the timeline.
List<DiaryEntry> entriesWithTag(List<DiaryEntry> entries, String tag) {
  final result = entries
      .where((e) => e.replyToEntryId == null && e.tags.contains(tag))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}

/// Tags that most often appear on the same records as [tag], most-frequent
/// first (ties alphabetical), excluding [tag] itself and replies. Capped at
/// [limit]. Empty when nothing co-occurs.
List<MapEntry<String, int>> coOccurringTags(
  List<DiaryEntry> entries,
  String tag, {
  int limit = 8,
}) {
  final counts = <String, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (!e.tags.contains(tag)) continue;
    for (final t in e.tags) {
      if (t == tag) continue;
      counts[t] = (counts[t] ?? 0) + 1;
    }
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  return limit <= 0 ? sorted : sorted.take(limit).toList();
}
