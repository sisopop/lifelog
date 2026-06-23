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

/// Top-level records tagged with [mood], newest first. 답장(reply) records are
/// excluded so the list mirrors the timeline.
List<DiaryEntry> entriesWithMood(List<DiaryEntry> entries, Mood mood) {
  final result = entries
      .where((e) => e.replyToEntryId == null && e.mood == mood)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}
