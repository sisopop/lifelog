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
