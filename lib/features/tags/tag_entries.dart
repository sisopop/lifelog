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
