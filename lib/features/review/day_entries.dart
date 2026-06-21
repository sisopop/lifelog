import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';

/// Top-level records created on [day] (ignores time), newest first.
/// 답장(reply) records are excluded so the list mirrors the timeline.
List<DiaryEntry> entriesOfDay(List<DiaryEntry> entries, DateTime day) {
  final result = entries
      .where((e) =>
          e.replyToEntryId == null &&
          e.createdAt.year == day.year &&
          e.createdAt.month == day.month &&
          e.createdAt.day == day.day)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}

/// Pure: a shareable plain-text summary of one day's [entries] (already
/// filtered to that day by the caller). [dateLabel] is a pre-formatted date
/// string. Mood emoji + title head, content, then #tags per record.
String dayShareText(List<DiaryEntry> entries, String dateLabel) {
  if (entries.isEmpty) {
    return '📔 $dateLabel\n\n이 날의 기록이 없어요\n\n— lifelog';
  }
  final blocks = <String>['📔 $dateLabel · 기록 ${entries.length}개'];
  for (final e in entries) {
    final lines = <String>[];
    final emoji = e.mood?.emoji;
    final title = (e.title ?? '').trim();
    final head = [
      ?emoji,
      if (title.isNotEmpty) title,
    ].join(' ');
    if (head.isNotEmpty) lines.add(head);
    final content = e.content.trim();
    if (content.isNotEmpty) lines.add(content);
    if (e.tags.isNotEmpty) lines.add(e.tags.map((t) => '#$t').join(' '));
    if (lines.isEmpty) lines.add('(내용 없음)');
    blocks.add(lines.join('\n'));
  }
  blocks.add('— lifelog');
  return blocks.join('\n\n');
}

/// The nearest recorded days immediately before/after [day], for browsing
/// between days that actually have records. Time is ignored.
class AdjacentDays {
  const AdjacentDays({this.previous, this.next});
  final DateTime? previous;
  final DateTime? next;
}

/// Distinct days (date-only) carrying at least one top-level record, ascending.
List<DateTime> recordedDaysSorted(List<DiaryEntry> entries) {
  final set = <DateTime>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    set.add(DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day));
  }
  final list = set.toList()..sort();
  return list;
}

/// Pure: the recorded day right before and right after [day] (ignoring time).
/// Either side is null when there is no such recorded day.
AdjacentDays adjacentRecordedDays(List<DiaryEntry> entries, DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  DateTime? prev;
  DateTime? next;
  for (final cur in recordedDaysSorted(entries)) {
    if (cur.isBefore(d)) {
      prev = cur; // keep the latest day before
    } else if (cur.isAfter(d) && next == null) {
      next = cur; // first day after
    }
  }
  return AdjacentDays(previous: prev, next: next);
}

/// Pure: the mood that appears most across [entries], or null when none carry
/// a mood. Ties resolve to the earlier mood in [Mood.values] order. Operates
/// on whatever list is passed (caller decides whether replies are included).
Mood? dominantMoodOf(List<DiaryEntry> entries) {
  final counts = <Mood, int>{};
  for (final e in entries) {
    if (e.mood == null) continue;
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
