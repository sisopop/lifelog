import 'package:characters/characters.dart';

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

/// Adds [tag] to [current] unless an equal tag (ignoring case) is already
/// present — so "Travel" won't sit next to "travel". Returns a new list (the
/// original is left untouched); the existing order is preserved and the tag is
/// appended at the end. Pure & top-level so it is unit-testable; the write
/// screen replaces its tag list with the result.
List<String> withTagAdded(List<String> current, String tag) {
  final lower = tag.toLowerCase();
  if (current.any((t) => t.toLowerCase() == lower)) return List.of(current);
  return [...current, tag];
}

/// A gentle nudge when any single tag is very long (past [max] graphemes):
/// long tags get truncated in the timeline and are awkward to scan. Returns
/// null when every tag fits, so most entries never see it. Pairs with
/// [tagCountHint] (which watches the count, not the length). Pure & top-level
/// so it is unit-testable; the tag chips widget renders it.
String? longTagHint(List<String> tags, {int max = 15}) {
  final hasLong = tags.any((t) => t.characters.length > max);
  return hasLong ? '태그가 길어요 · 짧게 줄이면 찾기 좋아요' : null;
}

/// A gentle nudge shown when an entry carries a lot of tags: past [max]
/// (default 6) each tag becomes less useful for finding the entry later.
/// Returns null at or below the threshold so most entries never see it.
/// Pure & top-level so it is unit-testable; the tag chips widget renders it.
String? tagCountHint(int count, {int max = 6}) {
  if (count <= max) return null;
  return '태그가 많아요 · 핵심만 남겨도 찾기 좋아요';
}
