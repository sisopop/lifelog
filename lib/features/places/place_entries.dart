import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';

/// Top-level records whose location matches [location] (case-insensitive,
/// trimmed), newest first. 답장(reply) records are excluded so the list
/// mirrors the timeline. A blank [location] matches nothing.
List<DiaryEntry> entriesAtLocation(List<DiaryEntry> entries, String location) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return const [];
  final result = entries
      .where((e) =>
          e.replyToEntryId == null &&
          (e.location ?? '').trim().toLowerCase() == target)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}

/// The earliest and latest record dates (date-only) among top-level records at
/// [location] (case-insensitive, trimmed; replies excluded), or null when none
/// match or [location] is blank. `first <= last`. Lets the place view show the
/// span of days that place was visited.
({DateTime first, DateTime last})? placeDateSpan(
    List<DiaryEntry> entries, String location) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return null;
  DateTime? first;
  DateTime? last;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if ((e.location ?? '').trim().toLowerCase() != target) continue;
    final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
    if (first == null || d.isBefore(first)) first = d;
    if (last == null || d.isAfter(last)) last = d;
  }
  return first == null ? null : (first: first, last: last!);
}

/// Tags most often recorded at [location] (case-insensitive, trimmed;
/// replies excluded), most-frequent first with ties resolved alphabetically.
/// Capped at [limit]. Empty when the place carries no tags or [location] is
/// blank. Lets the place view surface what the visits are usually about.
List<MapEntry<String, int>> tagsAtLocation(
  List<DiaryEntry> entries,
  String location, {
  int limit = 8,
}) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return const [];
  final counts = <String, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if ((e.location ?? '').trim().toLowerCase() != target) continue;
    for (final t in e.tags) {
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

/// The mood most often recorded at [location] (case-insensitive, trimmed;
/// replies excluded), or null when no matching record carries a mood or
/// [location] is blank. Ties resolve to the earlier mood in [Mood.values].
/// Lets the place view show how that place usually feels.
Mood? placeMood(List<DiaryEntry> entries, String location) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return null;
  final counts = <Mood, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if ((e.location ?? '').trim().toLowerCase() != target) continue;
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
