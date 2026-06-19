import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/diary_entry.dart';
import '../entries/entries_provider.dart';

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

class StreakInfo {
  const StreakInfo({required this.current, required this.longest});
  final int current;
  final int longest;
}

/// Streak across the entire history (independent of the reviewed month).
final streakProvider = Provider<StreakInfo>((ref) {
  final entries = ref.watch(entriesProvider).asData?.value ?? const [];
  final days = recordedDates(entries);
  return StreakInfo(
    current: currentStreak(days, DateTime.now()),
    longest: longestStreak(days),
  );
});
