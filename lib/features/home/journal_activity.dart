import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/diary_entry.dart';
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
