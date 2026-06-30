import '../../shared/models/diary_entry.dart';

/// The chronological neighbours of an entry within its journal.
class EntryNeighbors {
  const EntryNeighbors(this.previous, this.next);

  /// The older entry (written just before), or null at the start.
  final DiaryEntry? previous;

  /// The newer entry (written just after), or null at the end.
  final DiaryEntry? next;
}

/// An entry's 1-based chronological position within its journal, with the
/// journal's top-level total. e.g. position 3 of total 10.
class EntryOrdinal {
  const EntryOrdinal(this.position, this.total);
  final int position;
  final int total;
}

/// The chronological (oldest-first) 1-based position of [currentId] among the
/// top-level entries of its journal, plus that journal's total count. Replies
/// are ignored. Returns null when the entry isn't found.
EntryOrdinal? entryOrdinal(List<DiaryEntry> entries, String currentId) {
  final current = entries.where((e) => e.entryId == currentId).firstOrNull;
  if (current == null) return null;

  final siblings = entries
      .where((e) =>
          e.replyToEntryId == null && e.journalId == current.journalId)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  final idx = siblings.indexWhere((e) => e.entryId == currentId);
  if (idx < 0) return null;
  return EntryOrdinal(idx + 1, siblings.length);
}

/// The 1-based position a brand-new top-level entry would take in [journalId]
/// — one past the journal's current top-level count. Replies are ignored, and
/// entries in other journals don't count. Always >= 1 (an empty journal's first
/// entry is the 1st). Pure & top-level so it is unit-testable; the write screen
/// shows it as a gentle "이 일기장의 N번째 기록" nudge while composing.
int nextEntryOrdinal(List<DiaryEntry> entries, String journalId) {
  final count = entries
      .where((e) => e.replyToEntryId == null && e.journalId == journalId)
      .length;
  return count + 1;
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
