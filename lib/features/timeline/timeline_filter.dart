import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
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

/// Top-level entries after applying the active filter, newest-first.
final filteredTimelineProvider = Provider<List<DiaryEntry>>((ref) {
  final all = ref.watch(entriesProvider).asData?.value ?? const <DiaryEntry>[];
  final filter = ref.watch(timelineFilterProvider);
  return filterEntries(all, filter)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final availableTagsProvider = Provider<List<String>>((ref) {
  final all = ref.watch(entriesProvider).asData?.value ?? const <DiaryEntry>[];
  return availableTags(all);
});
