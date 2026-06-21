import '../../shared/models/diary_entry.dart';

/// Other top-level records that share at least one tag with [entry],
/// ranked by the number of shared tags (desc) then recency. Excludes the
/// entry itself and any replies. Returns empty when [entry] has no tags.
List<DiaryEntry> relatedEntries(
  List<DiaryEntry> all,
  DiaryEntry entry, {
  int limit = 3,
}) {
  if (entry.tags.isEmpty) return const [];
  final mine = entry.tags.toSet();
  final scored = <MapEntry<DiaryEntry, int>>[];
  for (final e in all) {
    if (e.entryId == entry.entryId) continue;
    if (e.replyToEntryId != null) continue;
    final shared = e.tags.where(mine.contains).length;
    if (shared == 0) continue;
    scored.add(MapEntry(e, shared));
  }
  scored.sort((a, b) {
    final byShared = b.value.compareTo(a.value);
    if (byShared != 0) return byShared;
    return b.key.createdAt.compareTo(a.key.createdAt);
  });
  return scored.take(limit).map((s) => s.key).toList();
}
