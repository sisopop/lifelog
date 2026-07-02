import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';

/// Top-level records tagged with [tag], newest first.
/// 답장(reply) records are excluded so the list mirrors the timeline.
List<DiaryEntry> entriesWithTag(List<DiaryEntry> entries, String tag) {
  final result = entries
      .where((e) => e.replyToEntryId == null && e.tags.contains(tag))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}

/// The earliest and latest record dates (date-only) among top-level records
/// carrying [tag] (replies excluded), or null when the tag has no records.
/// `first <= last`. Lets the tag view show how long the tag has been in use.
({DateTime first, DateTime last})? tagDateSpan(
    List<DiaryEntry> entries, String tag) {
  DateTime? first;
  DateTime? last;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (!e.tags.contains(tag)) continue;
    final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
    if (first == null || d.isBefore(first)) first = d;
    if (last == null || d.isAfter(last)) last = d;
  }
  return first == null ? null : (first: first, last: last!);
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

/// The mood most often attached to top-level records carrying [tag] (replies
/// excluded), or null when no such record has a mood. Ties resolve to the
/// earlier mood in [Mood.values]. Lets the tag view show how that theme feels.
Mood? tagMood(List<DiaryEntry> entries, String tag) {
  final counts = <Mood, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (!e.tags.contains(tag)) continue;
    if (e.mood == null) continue;
    counts.update(e.mood!, (c) => c + 1, ifAbsent: () => 1);
  }
  Mood? best;
  var bestCount = 0;
  for (final m in Mood.values) {
    final c = counts[m] ?? 0;
    if (c > bestCount) {
      bestCount = c;
      best = m;
    }
  }
  return best;
}
