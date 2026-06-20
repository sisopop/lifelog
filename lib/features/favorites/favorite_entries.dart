import '../../shared/models/diary_entry.dart';

/// Returns starred (즐겨찾기) top-level records, newest first.
/// Replies are excluded so the list mirrors the timeline.
List<DiaryEntry> favoriteEntries(List<DiaryEntry> entries) {
  final result = entries
      .where((e) => e.replyToEntryId == null && e.isFavorite)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}
