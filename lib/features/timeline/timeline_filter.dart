import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../auth/session.dart';
import '../entries/entries_provider.dart';

/// A quick date-range preset for the timeline. [all] applies no date filter.
enum DatePreset {
  all('전체'),
  week('이번 주'),
  month('이번 달'),
  year('올해');

  const DatePreset(this.label);
  final String label;
}

/// Active timeline filter. Null mood / null tag means "no filter on that axis";
/// [favorite] true scopes the list to starred entries; [period] limits to a
/// recent date range ([DatePreset.all] = no date filter).
class TimelineFilter {
  const TimelineFilter({
    this.mood,
    this.tag,
    this.favorite = false,
    this.period = DatePreset.all,
  });

  final Mood? mood;
  final String? tag;
  final bool favorite;
  final DatePreset period;

  bool get isActive =>
      mood != null || tag != null || favorite || period != DatePreset.all;

  TimelineFilter copyWith({
    Mood? mood,
    String? tag,
    bool? favorite,
    DatePreset? period,
    bool clearMood = false,
    bool clearTag = false,
  }) {
    return TimelineFilter(
      mood: clearMood ? null : (mood ?? this.mood),
      tag: clearTag ? null : (tag ?? this.tag),
      favorite: favorite ?? this.favorite,
      period: period ?? this.period,
    );
  }
}

/// Filters top-level entries by mood, tag and/or favorite. Replies are always
/// excluded. Results keep the input order (caller sorts as needed).
List<DiaryEntry> filterEntries(List<DiaryEntry> entries, TimelineFilter filter) {
  return entries.where((e) {
    if (e.replyToEntryId != null) return false;
    if (filter.mood != null && e.mood != filter.mood) return false;
    if (filter.tag != null && !e.tags.contains(filter.tag)) return false;
    if (filter.favorite && !e.isFavorite) return false;
    return true;
  }).toList();
}

/// Keeps only entries on/after the start of [preset] relative to [now].
/// [DatePreset.all] returns the list unchanged. Week starts Monday; month and
/// year start on the 1st. Does not mutate the input.
List<DiaryEntry> filterByPeriod(
    List<DiaryEntry> entries, DatePreset preset, DateTime now) {
  if (preset == DatePreset.all) return entries;
  final today = DateTime(now.year, now.month, now.day);
  final DateTime start;
  switch (preset) {
    case DatePreset.week:
      start = today.subtract(Duration(days: today.weekday - 1));
    case DatePreset.month:
      start = DateTime(now.year, now.month, 1);
    case DatePreset.year:
      start = DateTime(now.year, 1, 1);
    case DatePreset.all:
      return entries;
  }
  return entries.where((e) => !e.createdAt.isBefore(start)).toList();
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

  void toggleFavorite() => state = state.copyWith(favorite: !state.favorite);

  /// Sets the date preset, or returns to [DatePreset.all] when the currently
  /// active preset is tapped again.
  void togglePeriod(DatePreset preset) {
    state = state.copyWith(
        period: state.period == preset ? DatePreset.all : preset);
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
  final byAxes = filterEntries(all, filter);
  final byDate = filterByPeriod(byAxes, filter.period, DateTime.now());
  return sortByDate(byDate, ascending: ascending);
});

final availableTagsProvider = Provider<List<String>>((ref) {
  final all = ref.watch(entriesProvider).asData?.value ?? const <DiaryEntry>[];
  return availableTags(all);
});
