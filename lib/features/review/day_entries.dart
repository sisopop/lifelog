import '../../shared/models/diary_entry.dart';

/// Top-level records created on [day] (ignores time), newest first.
/// 답장(reply) records are excluded so the list mirrors the timeline.
List<DiaryEntry> entriesOfDay(List<DiaryEntry> entries, DateTime day) {
  final result = entries
      .where((e) =>
          e.replyToEntryId == null &&
          e.createdAt.year == day.year &&
          e.createdAt.month == day.month &&
          e.createdAt.day == day.day)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}
