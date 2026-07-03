import 'package:characters/characters.dart';

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

/// Tags most often recorded with [mood] (top-level records; replies excluded),
/// most-frequent first with ties resolved alphabetically. Capped at [limit].
/// Empty when no such record carries a tag. Lets the mood view surface what
/// that feeling is usually about.
List<MapEntry<String, int>> tagsWithMood(
  List<DiaryEntry> entries,
  Mood mood, {
  int limit = 8,
}) {
  final counts = <String, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null || e.mood != mood) continue;
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

/// Distinct non-empty places recorded with [mood] (top-level records; replies
/// excluded), most-frequent first with ties resolved alphabetically. Capped at
/// [limit]. Empty when no matching record carries a place. Lets the mood view
/// show where that feeling tends to happen.
List<String> placesWithMood(
  List<DiaryEntry> entries,
  Mood mood, {
  int limit = 4,
}) {
  final counts = <String, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null || e.mood != mood) continue;
    final p = e.location?.trim() ?? '';
    if (p.isEmpty) continue;
    counts[p] = (counts[p] ?? 0) + 1;
  }
  final places = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });
  return limit <= 0 ? places : places.take(limit).toList();
}

/// Average content length (grapheme count) across top-level records carrying
/// [mood] (replies excluded), rounded to the nearest whole number. Returns 0
/// when the mood has no top-level records. Lets the mood view hint how much
/// tends to get written in that feeling.
int averageCharsWithMood(List<DiaryEntry> entries, Mood mood) {
  var total = 0;
  var n = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null || e.mood != mood) continue;
    total += e.content.trim().characters.length;
    n++;
  }
  return n == 0 ? 0 : (total / n).round();
}

/// How many top-level records carrying [mood] (replies excluded) are marked
/// favorite. 0 when none are starred or the mood has no records. Lets the mood
/// view show how many records of that feeling were kept as favorites.
int favoriteCountWithMood(List<DiaryEntry> entries, Mood mood) {
  var n = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null || e.mood != mood) continue;
    if (e.isFavorite) n++;
  }
  return n;
}

/// The distinct journal ids among top-level records carrying [mood] (replies
/// excluded), in first-seen order of [entries]. Empty when the mood has no
/// top-level records. Lets the mood view show which journals a feeling spans.
List<String> journalIdsWithMood(List<DiaryEntry> entries, Mood mood) {
  final seen = <String>{};
  final result = <String>[];
  for (final e in entries) {
    if (e.replyToEntryId != null || e.mood != mood) continue;
    if (seen.add(e.journalId)) result.add(e.journalId);
  }
  return result;
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
