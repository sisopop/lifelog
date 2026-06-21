import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../auth/session.dart';
import '../entries/entries_provider.dart';

/// Active timeline filter. Null mood / null tag means "no filter on that axis".
class TimelineFilter {
  const TimelineFilter({this.mood, this.tag});

  final Mood? mood;
  final String? tag;

  bool get isActive => mood != null || tag != null;

  TimelineFilter copyWith({Mood? mood, String? tag, bool clearMood = false, bool clearTag = false}) {
    return TimelineFilter(
      mood: clearMood ? null : (mood ?? this.mood),
      tag: clearTag ? null : (tag ?? this.tag),
    );
  }
}

/// Filters top-level entries by mood and/or tag. Replies are always excluded.
/// Results keep the input order (caller sorts as needed).
List<DiaryEntry> filterEntries(List<DiaryEntry> entries, TimelineFilter filter) {
  return entries.where((e) {
    if (e.replyToEntryId != null) return false;
    if (filter.mood != null && e.mood != filter.mood) return false;
    if (filter.tag != null && !e.tags.contains(filter.tag)) return false;
    return true;
  }).toList();
}

/// Counts how many replies each parent entry has, keyed by the parent's
/// entryId. Only entries with a [replyToEntryId] contribute. Parents with no
/// replies are absent from the map.
Map<String, int> replyCountsByParent(List<DiaryEntry> entries) {
  final counts = <String, int>{};
  for (final e in entries) {
    final parent = e.replyToEntryId;
    if (parent != null) counts[parent] = (counts[parent] ?? 0) + 1;
  }
  return counts;
}

/// Returns [entries] sorted by creation date. Newest-first by default;
/// [ascending] true gives oldest-first. Does not mutate the input.
List<DiaryEntry> sortByDate(List<DiaryEntry> entries, {bool ascending = false}) {
  final sorted = [...entries];
  sorted.sort((a, b) => ascending
      ? a.createdAt.compareTo(b.createdAt)
      : b.createdAt.compareTo(a.createdAt));
  return sorted;
}

/// A run of consecutive entries that fall in the same calendar month.
class TimelineMonthGroup {
  const TimelineMonthGroup({
    required this.year,
    required this.month,
    required this.entries,
  });

  final int year;
  final int month;
  final List<DiaryEntry> entries;
}

/// Groups already-ordered [entries] into consecutive same-month runs,
/// preserving the input order (so it works for both newest- and oldest-first).
List<TimelineMonthGroup> groupByMonth(List<DiaryEntry> entries) {
  final groups = <TimelineMonthGroup>[];
  for (final e in entries) {
    final y = e.createdAt.year;
    final m = e.createdAt.month;
    final last = groups.isEmpty ? null : groups.last;
    if (last != null && last.year == y && last.month == m) {
      last.entries.add(e);
    } else {
      groups.add(TimelineMonthGroup(year: y, month: m, entries: [e]));
    }
  }
  return groups;
}

/// Distinct tags across all top-level entries, most-used first.
List<String> availableTags(List<DiaryEntry> entries) {
  final counts = <String, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    for (final t in e.tags) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
  }
  final tags = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });
  return tags;
}

class TimelineFilterNotifier extends Notifier<TimelineFilter> {
  @override
  TimelineFilter build() => const TimelineFilter();

  void toggleMood(Mood mood) {
    state = state.mood == mood
        ? state.copyWith(clearMood: true)
        : state.copyWith(mood: mood);
  }

  void toggleTag(String tag) {
    state = state.tag == tag
        ? state.copyWith(clearTag: true)
        : state.copyWith(tag: tag);
  }

  void clear() => state = const TimelineFilter();
}

final timelineFilterProvider =
    NotifierProvider<TimelineFilterNotifier, TimelineFilter>(
  TimelineFilterNotifier.new,
);

const _kTimelineSortAscKey = 'timeline_sort_ascending';

/// Timeline sort order, persisted across launches.
/// false (default) = newest-first, true = oldest-first.
class TimelineSortNotifier extends Notifier<bool> {
  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  bool build() => _p.getBool(_kTimelineSortAscKey) ?? false;

  Future<void> toggle() async {
    state = !state;
    await _p.setBool(_kTimelineSortAscKey, state);
  }
}

final timelineSortProvider =
    NotifierProvider<TimelineSortNotifier, bool>(TimelineSortNotifier.new);

/// Top-level entries after applying the active filter, sorted by the
/// current order (newest-first by default).
final filteredTimelineProvider = Provider<List<DiaryEntry>>((ref) {
  final all = ref.watch(entriesProvider).asData?.value ?? const <DiaryEntry>[];
  final filter = ref.watch(timelineFilterProvider);
  final ascending = ref.watch(timelineSortProvider);
  return sortByDate(filterEntries(all, filter), ascending: ascending);
});

final availableTagsProvider = Provider<List<String>>((ref) {
  final all = ref.watch(entriesProvider).asData?.value ?? const <DiaryEntry>[];
  return availableTags(all);
});
