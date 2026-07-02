import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';

/// Resolves a [Mood] from its stable [Mood.name] (the value used in the
/// `/mood?m=` query param). Returns null for unknown/blank names.
Mood? moodFromName(String name) {
  for (final m in Mood.values) {
    if (m.name == name) return m;
  }
  return null;
}

/// Each recorded [Mood] with its top-level record count, sorted by count
/// descending. Reply records and moodless entries are excluded. Ties resolve
/// to the earlier [Mood.values] order (good → neutral → hard). Moods with no
/// records are omitted.
List<MapEntry<Mood, int>> moodCountsSorted(List<DiaryEntry> entries) {
  final counts = <Mood, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null || e.mood == null) continue;
    counts.update(e.mood!, (c) => c + 1, ifAbsent: () => 1);
  }
  final result = <MapEntry<Mood, int>>[
    for (final m in Mood.values)
      if ((counts[m] ?? 0) > 0) MapEntry(m, counts[m]!),
  ];
  result.sort((a, b) {
    final byCount = b.value.compareTo(a.value);
    return byCount != 0 ? byCount : a.key.index.compareTo(b.key.index);
  });
  return result;
}

/// The most recent top-level [createdAt] for each recorded [Mood]. Reply
/// records and moodless entries are excluded. Moods with no records are absent.
Map<Mood, DateTime> lastUseByMood(List<DiaryEntry> entries) {
  final result = <Mood, DateTime>{};
  for (final e in entries) {
    if (e.replyToEntryId != null || e.mood == null) continue;
    final cur = result[e.mood!];
    if (cur == null || e.createdAt.isAfter(cur)) result[e.mood!] = e.createdAt;
  }
  return result;
}

/// The earliest and latest record dates (date-only) among top-level records
/// carrying [mood] (replies excluded), or null when the mood has no records.
/// `first <= last`. Lets the mood view show the span of days that mood spans.
({DateTime first, DateTime last})? moodDateSpan(
    List<DiaryEntry> entries, Mood mood) {
  DateTime? first;
  DateTime? last;
  for (final e in entries) {
    if (e.replyToEntryId != null || e.mood != mood) continue;
    final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
    if (first == null || d.isBefore(first)) first = d;
    if (last == null || d.isAfter(last)) last = d;
  }
  return first == null ? null : (first: first, last: last!);
}

/// Top-level records tagged with [mood], newest first. 답장(reply) records are
/// excluded so the list mirrors the timeline.
List<DiaryEntry> entriesWithMood(List<DiaryEntry> entries, Mood mood) {
  final result = entries
      .where((e) => e.replyToEntryId == null && e.mood == mood)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}
