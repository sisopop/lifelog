import '../../shared/models/diary_entry.dart';

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
