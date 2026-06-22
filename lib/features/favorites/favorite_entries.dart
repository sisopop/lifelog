import 'package:characters/characters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/diary_entry.dart';

/// Total characters (graphemes) written across all starred top-level records.
/// Replies are excluded, mirroring [favoriteEntries]. Counts the trimmed
/// content of each entry; returns 0 when there are no favorites.
int favoriteCharTotal(List<DiaryEntry> entries) {
  var total = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null || !e.isFavorite) continue;
    total += e.content.trim().characters.length;
  }
  return total;
}

/// Returns starred (즐겨찾기) top-level records sorted by creation time.
/// Defaults to newest-first; pass [ascending] true for oldest-first.
/// Replies are excluded so the list mirrors the timeline.
List<DiaryEntry> favoriteEntries(List<DiaryEntry> entries,
    {bool ascending = false}) {
  final result = entries
      .where((e) => e.replyToEntryId == null && e.isFavorite)
      .toList()
    ..sort((a, b) => ascending
        ? a.createdAt.compareTo(b.createdAt)
        : b.createdAt.compareTo(a.createdAt));
  return result;
}

/// Toggles the favorites list between newest-first (false) and oldest-first.
class FavoriteSortNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
  void clear() => state = false;
}

final favoriteSortProvider =
    NotifierProvider<FavoriteSortNotifier, bool>(FavoriteSortNotifier.new);
