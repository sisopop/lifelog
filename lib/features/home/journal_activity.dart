import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/journal.dart';

/// The most recent top-level entry creation time within [journalId], or null
/// when the journal has no (non-reply) entries. Replies are ignored so the
/// "last activity" matches what the timeline shows.
DateTime? lastEntryDate(List<DiaryEntry> entries, String journalId) {
  DateTime? latest;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (e.journalId != journalId) continue;
    if (latest == null || e.createdAt.isAfter(latest)) latest = e.createdAt;
  }
  return latest;
}

/// Pure: calendar days since the most recent top-level entry across ALL
/// journals, or null when there are no (non-reply) entries yet. Replies are
/// ignored. A record made today (or a future-dated one) reads as 0.
int? daysSinceLastEntry(List<DiaryEntry> entries, DateTime now) {
  DateTime? latest;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (latest == null || e.createdAt.isAfter(latest)) latest = e.createdAt;
  }
  if (latest == null) return null;
  final d0 = DateTime(latest.year, latest.month, latest.day);
  final n0 = DateTime(now.year, now.month, now.day);
  final days = n0.difference(d0).inDays;
  return days < 0 ? 0 : days;
}

/// A short Korean relative-day label comparing [date] to [now], by calendar
/// day: 오늘 / 어제 / N일 전 / N주 전 / N개월 전 / N년 전. Future or same-day
/// dates read as "오늘".
String relativeDayLabel(DateTime date, DateTime now) {
  final d0 = DateTime(date.year, date.month, date.day);
  final n0 = DateTime(now.year, now.month, now.day);
  final days = n0.difference(d0).inDays;
  if (days <= 0) return '오늘';
  if (days == 1) return '어제';
  if (days < 7) return '$days일 전';
  if (days < 30) return '${days ~/ 7}주 전';
  if (days < 365) return '${days ~/ 30}개월 전';
  return '${days ~/ 365}년 전';
}

/// The same relative-day label as [relativeDayLabel] but only for *back-dated*
/// entries: returns null when [date] is today or in the future, so the write
/// screen surfaces an "어제 / 3일 전 …" hint only when the entry is for a past
/// day (staying silent for the common today case). Pure & top-level so it is
/// unit-testable; the date row appends the non-null result.
String? backdatedDayLabel(DateTime date, DateTime now) {
  final d0 = DateTime(date.year, date.month, date.day);
  final n0 = DateTime(now.year, now.month, now.day);
  if (!d0.isBefore(n0)) return null;
  return relativeDayLabel(date, now);
}

/// Pure: the mood recorded most often among [journalId]'s top-level records,
/// or null when none of them carry a mood. Ties resolve to the earlier mood
/// in [Mood.values] order.
Mood? dominantMoodForJournal(List<DiaryEntry> entries, String journalId) {
  final counts = <Mood, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null || e.mood == null) continue;
    if (e.journalId != journalId) continue;
    counts.update(e.mood!, (c) => c + 1, ifAbsent: () => 1);
  }
  Mood? best;
  var bestCount = 0;
  for (final m in Mood.values) {
    final c = counts[m] ?? 0;
    if (c > bestCount) {
      bestCount = c;
      best = m;
    }
  }
  return best;
}

/// Returns [journals] reordered so the one with the most recent (non-reply)
/// entry comes first. Journals with no entries fall to the end, keeping their
/// original relative order. Ties also keep original order (stable). Does not
/// mutate the input.
List<Journal> sortJournalsByActivity(
    List<Journal> journals, List<DiaryEntry> entries) {
  final lastByJournal = <String, DateTime>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    final cur = lastByJournal[e.journalId];
    if (cur == null || e.createdAt.isAfter(cur)) {
      lastByJournal[e.journalId] = e.createdAt;
    }
  }
  final indexed = [
    for (var i = 0; i < journals.length; i++) (i, journals[i]),
  ];
  indexed.sort((a, b) {
    final la = lastByJournal[a.$2.journalId];
    final lb = lastByJournal[b.$2.journalId];
    if (la == null && lb == null) return a.$1.compareTo(b.$1);
    if (la == null) return 1;
    if (lb == null) return -1;
    final byDate = lb.compareTo(la); // newest activity first
    return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

/// Pure: the mood recorded most often among top-level entries in the last
/// 7 calendar days (today-6 .. today, inclusive — matching weekEntryCount),
/// or null when none carry a mood. Ties resolve to the earlier [Mood.values].
Mood? weekDominantMood(List<DiaryEntry> entries, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(const Duration(days: 6));
  final counts = <Mood, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null || e.mood == null) continue;
    final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
    if (d.isBefore(start) || d.isAfter(today)) continue;
    counts.update(e.mood!, (c) => c + 1, ifAbsent: () => 1);
  }
  Mood? best;
  var bestCount = 0;
  for (final m in Mood.values) {
    final c = counts[m] ?? 0;
    if (c > bestCount) {
      bestCount = c;
      best = m;
    }
  }
  return best;
}

/// Whether the home journal list is ordered by recent activity. false (default)
/// keeps the journals' own order; true sorts by most recent entry first.
class HomeJournalSortNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final homeJournalSortProvider =
    NotifierProvider<HomeJournalSortNotifier, bool>(
        HomeJournalSortNotifier.new);
