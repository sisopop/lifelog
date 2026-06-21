import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/diary_entry.dart';

/// Count of entries carrying each tag. Defaults to most-used first (ties →
/// name asc); pass [byName] true to sort alphabetically (ties → higher count
/// first). Considers every entry that has tags (top-level and replies alike).
List<MapEntry<String, int>> tagCountsSorted(List<DiaryEntry> entries,
    {bool byName = false}) {
  final counts = <String, int>{};
  for (final e in entries) {
    for (final t in e.tags) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
  }
  final list = counts.entries.toList()
    ..sort((a, b) {
      if (byName) {
        final byKey = a.key.compareTo(b.key);
        return byKey != 0 ? byKey : b.value.compareTo(a.value);
      }
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  return list;
}

/// Toggles the tag-management list between count-order (false) and name-order.
class TagSortNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final tagSortByNameProvider =
    NotifierProvider<TagSortNotifier, bool>(TagSortNotifier.new);

/// Returns the entries that change when renaming tag [from] → [to], each with
/// its tag list updated (order preserved, duplicates collapsed when [to]
/// already exists). Entries without [from] are omitted. A no-op rename
/// (from == to, or blank [to]) returns an empty list.
List<DiaryEntry> renameTagInEntries(
    List<DiaryEntry> entries, String from, String to) {
  final target = to.trim();
  if (target.isEmpty || from == target) return const [];
  final changed = <DiaryEntry>[];
  for (final e in entries) {
    if (!e.tags.contains(from)) continue;
    final next = <String>[];
    for (final t in e.tags) {
      final mapped = t == from ? target : t;
      if (!next.contains(mapped)) next.add(mapped);
    }
    changed.add(e.copyWith(tags: next));
  }
  return changed;
}

/// Returns the entries that change when [tag] is removed, each with the tag
/// stripped from its list. Entries without [tag] are omitted.
List<DiaryEntry> removeTagFromEntries(List<DiaryEntry> entries, String tag) {
  final changed = <DiaryEntry>[];
  for (final e in entries) {
    if (!e.tags.contains(tag)) continue;
    changed.add(e.copyWith(tags: e.tags.where((t) => t != tag).toList()));
  }
  return changed;
}
