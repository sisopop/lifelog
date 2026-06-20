import '../../shared/models/diary_entry.dart';

/// The chronological neighbours of an entry within its journal.
class EntryNeighbors {
  const EntryNeighbors(this.previous, this.next);

  /// The older entry (written just before), or null at the start.
  final DiaryEntry? previous;

  /// The newer entry (written just after), or null at the end.
  final DiaryEntry? next;
}

/// Previous (older) and next (newer) top-level entries in the *same journal*
/// as the entry identified by [currentId], ordered by creation time. Replies
/// are ignored. Returns nulls when the entry isn't found or sits at an edge.
EntryNeighbors adjacentEntries(List<DiaryEntry> entries, String currentId) {
  final current = entries.where((e) => e.entryId == currentId).firstOrNull;
  if (current == null) return const EntryNeighbors(null, null);

  final siblings = entries
      .where((e) =>
          e.replyToEntryId == null && e.journalId == current.journalId)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // oldest first

  final idx = siblings.indexWhere((e) => e.entryId == currentId);
  if (idx < 0) return const EntryNeighbors(null, null);

  return EntryNeighbors(
    idx > 0 ? siblings[idx - 1] : null,
    idx < siblings.length - 1 ? siblings[idx + 1] : null,
  );
}
