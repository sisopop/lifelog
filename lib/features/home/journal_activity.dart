import '../../shared/models/diary_entry.dart';

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
