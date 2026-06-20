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
