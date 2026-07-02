import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/diary_entry.dart';
import '../entries/entries_provider.dart';
import 'stats_provider.dart';

/// Distinct calendar dates (time stripped) that have a top-level record.
Set<DateTime> recordedDates(List<DiaryEntry> entries) => {
      for (final e in entries)
        if (e.replyToEntryId == null)
          DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day),
    };

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Consecutive days of records ending today (or yesterday, so a streak that
/// hasn't been broken yet still counts before today's entry is written).
/// Returns 0 if neither today nor yesterday has a record.
int currentStreak(Set<DateTime> days, DateTime today) {
  if (days.isEmpty) return 0;
  final t = _dayOnly(today);
  final y = t.subtract(const Duration(days: 1));
  DateTime anchor;
  if (days.contains(t)) {
    anchor = t;
  } else if (days.contains(y)) {
    anchor = y;
  } else {
    return 0;
  }
  var count = 0;
  var d = anchor;
  while (days.contains(d)) {
    count++;
    d = d.subtract(const Duration(days: 1));
  }
  return count;
}

/// The longest run of consecutive recorded days, anywhere in the history.
int longestStreak(Set<DateTime> days) {
  if (days.isEmpty) return 0;
  final sorted = days.toList()..sort();
  var best = 1;
  var run = 1;
  for (var i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1];
    final cur = sorted[i];
    if (cur.difference(prev).inDays == 1) {
      run++;
      if (run > best) best = run;
    } else {
      run = 1;
    }
  }
  return best;
}

/// How many of the last [windowDays] calendar days (ending on [today],
/// inclusive) carry a record — a measure of very recent consistency that
/// complements the streak (which needs the days to be *consecutive*). Result is
/// clamped to 0..windowDays. Replies are already excluded by [recordedDates].
/// Returns 0 when [windowDays] <= 0.
int recordedDaysInWindow(Set<DateTime> days, DateTime today,
    {int windowDays = 7}) {
  if (windowDays <= 0) return 0;
  final t = _dayOnly(today);
  var count = 0;
  for (var i = 0; i < windowDays; i++) {
    if (days.contains(t.subtract(Duration(days: i)))) count++;
  }
  return count;
}

class StreakInfo {
  const StreakInfo(
      {required this.current, required this.longest, this.recentActive = 0});
  final int current;
  final int longest;

  /// Distinct recorded days within the last 7 (see [recordedDaysInWindow]).
  final int recentActive;
}

/// Streak across the entire history of the selected review journal
/// (independent of the reviewed month).
final streakProvider = Provider<StreakInfo>((ref) {
  final entries = ref.watch(reviewEntriesProvider);
  final days = recordedDates(entries);
  final now = DateTime.now();
  return StreakInfo(
    current: currentStreak(days, now),
    longest: longestStreak(days),
    recentActive: recordedDaysInWindow(days, now),
  );
});

/// Current streak across every journal (used by the home screen badge),
/// so the home nudge reflects the whole habit, not one journal's scope.
final homeStreakProvider = Provider<int>((ref) {
  final entries = ref.watch(entriesProvider).asData?.value ?? const [];
  return currentStreak(recordedDates(entries), DateTime.now());
});

/// Current and longest streak across every journal (used by the home screen
/// to nudge the user toward beating their personal best).
final homeStreakInfoProvider = Provider<StreakInfo>((ref) {
  final entries = ref.watch(entriesProvider).asData?.value ?? const [];
  final days = recordedDates(entries);
  return StreakInfo(
    current: currentStreak(days, DateTime.now()),
    longest: longestStreak(days),
  );
});
