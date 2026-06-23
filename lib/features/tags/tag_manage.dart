import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';

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

/// Pure: the most-recent date each tag was used on, across every entry that
/// carries it (top-level and replies alike, matching [tagCountsSorted]).
Map<String, DateTime> lastUseByTag(List<DiaryEntry> entries) {
  final latest = <String, DateTime>{};
  for (final e in entries) {
    for (final t in e.tags) {
      final cur = latest[t];
      if (cur == null || e.createdAt.isAfter(cur)) latest[t] = e.createdAt;
    }
  }
  return latest;
}

/// Pure: the dominant (most-recorded) mood for each tag. Replies and moodless
/// records are excluded (mirroring the other "dominant mood" stats), so a tag
/// only used on replies/moodless entries is omitted. Ties resolve to the
/// earlier [Mood.values] entry.
Map<String, Mood> dominantMoodByTag(List<DiaryEntry> entries) {
  final counts = <String, Map<Mood, int>>{};
  for (final e in entries) {
    if (e.replyToEntryId != null || e.mood == null) continue;
    for (final t in e.tags) {
      final byMood = counts.putIfAbsent(t, () => <Mood, int>{});
      byMood.update(e.mood!, (c) => c + 1, ifAbsent: () => 1);
    }
  }
  final result = <String, Mood>{};
  for (final entry in counts.entries) {
    Mood? best;
    var bestCount = 0;
    for (final m in Mood.values) {
      final c = entry.value[m] ?? 0;
      if (c > bestCount) {
        bestCount = c;
        best = m;
      }
    }
    if (best != null) result[entry.key] = best;
  }
  return result;
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
