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

/// Top-level records tagged with [mood], newest first. 답장(reply) records are
/// excluded so the list mirrors the timeline.
List<DiaryEntry> entriesWithMood(List<DiaryEntry> entries, Mood mood) {
  final result = entries
      .where((e) => e.replyToEntryId == null && e.mood == mood)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}
