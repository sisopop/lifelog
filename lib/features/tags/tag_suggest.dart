/// Suggests existing tags for the write screen's tag input.
/// [allTags] is expected to already be ordered by usage (see availableTags).
/// Filters out tags already added ([exclude]) and, when [query] is non-empty,
/// keeps only tags containing it (case-insensitive). Capped at [limit].
List<String> suggestTags(
  List<String> allTags,
  String query,
  List<String> exclude, {
  int limit = 8,
}) {
  final q = query.trim().toLowerCase();
  return allTags
      .where((t) => !exclude.contains(t))
      .where((t) => q.isEmpty || t.toLowerCase().contains(q))
      .take(limit)
      .toList();
}

/// Cleans a raw tag string typed by the user into a storable tag, or null when
/// nothing usable remains. Trims, drops any leading `#` marks (so "#여행" and
/// "여행" are the same), and collapses internal whitespace runs to single
/// spaces. Returns null for empty/blank or hash-only input. Pure & top-level so
/// it is unit-testable; the tag input sheet returns its result.
String? normalizeTag(String raw) {
  final t = raw
      .trim()
      .replaceFirst(RegExp(r'^#+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return t.isEmpty ? null : t;
}

/// A gentle nudge shown when an entry carries a lot of tags: past [max]
/// (default 6) each tag becomes less useful for finding the entry later.
/// Returns null at or below the threshold so most entries never see it.
/// Pure & top-level so it is unit-testable; the tag chips widget renders it.
String? tagCountHint(int count, {int max = 6}) {
  if (count <= max) return null;
  return '태그가 많아요 · 핵심만 남겨도 찾기 좋아요';
}
