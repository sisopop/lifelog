import 'package:characters/characters.dart';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../decorate/page_canvas.dart';
import '../stats/lifetime_stats.dart';

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
/// string. A header line + a meta line (active time span, places) mirroring the
/// day view, then per record: mood emoji + title head, content, and #tags.
String dayShareText(List<DiaryEntry> entries, String dateLabel) {
  if (entries.isEmpty) {
    return '📔 $dateLabel\n\n이 날의 기록이 없어요\n\n— lifelog';
  }
  final headLine = '📔 $dateLabel · 기록 ${entries.length}개';
  final span = dayTimeSpan(entries);
  final places = placesOfDay(entries);
  String hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  final meta = [
    if (span != null)
      span.first == span.last
          ? '🕘 ${hhmm(span.first)}'
          : '🕘 ${hhmm(span.first)}–${hhmm(span.last)}',
    if (places.isNotEmpty) '📍 ${places.take(4).join(' · ')}',
  ].join(' · ');
  final blocks = <String>[meta.isEmpty ? headLine : '$headLine\n$meta'];
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

/// Pure: total number of (grapheme-aware, trimmed) characters written across
/// [entries] — the caller passes a day's already-filtered records. Empty or
/// blank content contributes 0, so the sum is 0 when nothing carries text.
int totalContentChars(List<DiaryEntry> entries) {
  var n = 0;
  for (final e in entries) {
    n += e.content.trim().characters.length;
  }
  return n;
}

/// Pure: average content length (grapheme-aware, trimmed) per record across
/// [entries] (a day's already-filtered records), rounded to the nearest whole
/// number. Returns 0 when there are no records. Mirrors averageCharsWithMood /
/// averageCharsWithTag / averageCharsAtLocation — the ✍️ dimension for the day
/// view (which already shows the running total). Lets the day view hint how
/// much tends to get written per record that day.
int averageCharsOfDay(List<DiaryEntry> entries) {
  if (entries.isEmpty) return 0;
  return (totalContentChars(entries) / entries.length).round();
}

/// Pure: the earliest and latest record time among [entries] (a day's
/// already-filtered records), or null when empty. `first <= last` always.
/// Lets the day view show the span of hours the day was active.
({DateTime first, DateTime last})? dayTimeSpan(List<DiaryEntry> entries) {
  if (entries.isEmpty) return null;
  var first = entries.first.createdAt;
  var last = entries.first.createdAt;
  for (final e in entries) {
    if (e.createdAt.isBefore(first)) first = e.createdAt;
    if (e.createdAt.isAfter(last)) last = e.createdAt;
  }
  return (first: first, last: last);
}

/// Pure: the distinct tags used across [entries] (a day's already-filtered
/// records), most frequent first. Ties keep first-seen order (the caller passes
/// entries newest-first, so ties follow that display order). Empty when no
/// record carries a tag. Lets the day view surface the day's themes at a glance.
List<String> tagsOfDay(List<DiaryEntry> entries) {
  final counts = <String, int>{};
  final firstSeen = <String, int>{};
  var idx = 0;
  for (final e in entries) {
    for (final t in e.tags) {
      if (!counts.containsKey(t)) firstSeen[t] = idx++;
      counts.update(t, (c) => c + 1, ifAbsent: () => 1);
    }
  }
  final tags = counts.keys.toList();
  tags.sort((a, b) {
    final byCount = counts[b]!.compareTo(counts[a]!);
    return byCount != 0 ? byCount : firstSeen[a]!.compareTo(firstSeen[b]!);
  });
  return tags;
}

/// Pure: the distinct non-empty locations across [entries] (a day's
/// already-filtered records), most frequent first. Ties keep first-seen order
/// (caller passes entries newest-first). Empty when no record carries a place.
/// Lets the day view show where the day happened.
List<String> placesOfDay(List<DiaryEntry> entries) {
  final counts = <String, int>{};
  final firstSeen = <String, int>{};
  var idx = 0;
  for (final e in entries) {
    final p = e.location?.trim() ?? '';
    if (p.isEmpty) continue;
    if (!counts.containsKey(p)) firstSeen[p] = idx++;
    counts.update(p, (c) => c + 1, ifAbsent: () => 1);
  }
  final places = counts.keys.toList();
  places.sort((a, b) {
    final byCount = counts[b]!.compareTo(counts[a]!);
    return byCount != 0 ? byCount : firstSeen[a]!.compareTo(firstSeen[b]!);
  });
  return places;
}

/// Pure: the distinct journal ids among [entries] (a day's already-filtered
/// records), in first-seen order. The caller passes entries newest-first, so
/// the order mirrors the day view. Empty when [entries] is empty. Lets the day
/// view show which journals the day's records were spread across.
List<String> journalIdsOfDay(List<DiaryEntry> entries) {
  final seen = <String>{};
  final result = <String>[];
  for (final e in entries) {
    if (seen.add(e.journalId)) result.add(e.journalId);
  }
  return result;
}

/// Pure: how many of [entries] are marked favorite (a day's already-filtered
/// records). 0 when none are starred. Lets the day view highlight how many of
/// the day's records were kept as favorites.
int favoriteCountOfDay(List<DiaryEntry> entries) {
  var n = 0;
  for (final e in entries) {
    if (e.isFavorite) n++;
  }
  return n;
}

/// Pure: the record in [entries] (a day's already-filtered records) with the
/// longest (grapheme-aware, trimmed) body, or null when none carry text. Ties
/// resolve to the most recent record. Reuses [longestEntry] directly (no key
/// param needed — the caller already scoped [entries] to one day), mirroring
/// longestEntryWithTag/AtLocation/WithMood. Lets the day view surface a
/// tappable "가장 긴 기록" highlight.
DiaryEntry? longestEntryOfDay(List<DiaryEntry> entries) =>
    longestEntry(entries);

/// Pure: how many of [entries] (a day's already-filtered records) carry page
/// decoration — 속지/스티커/테이프/바탕색 등 ([PageCanvas.isDecorated]). Decodes
/// [DiaryEntry.pageCanvas] defensively (a stored value that decodes to a
/// plain/empty canvas — e.g. from an old backup/import — does not count),
/// mirroring how entry_card.dart decides whether to show a canvas thumbnail.
/// 0 when none. Lets the day view highlight how many of the day's records were
/// decorated, alongside [favoriteCountOfDay].
int decoratedCountOfDay(List<DiaryEntry> entries) {
  var n = 0;
  for (final e in entries) {
    if (decodePageCanvas(e.pageCanvas).isDecorated) n++;
  }
  return n;
}

/// Pure: how many of [entries] (a day's already-filtered records) carry at
/// least one attached photo ([DiaryEntry.mediaUrls] non-empty). 0 when none.
/// Mirrors [decoratedCountOfDay]'s shape but tracks a different dimension
/// (photos vs. page decoration) — lets the day view show how much of the
/// day was captured in pictures alongside the other counts.
int photoCountOfDay(List<DiaryEntry> entries) {
  var n = 0;
  for (final e in entries) {
    if (e.mediaUrls.isNotEmpty) n++;
  }
  return n;
}

/// Pure: how many of [entries] (a day's already-filtered records) carry a
/// non-empty title (non-whitespace text). 0 when none. Reuses
/// [titledEntryCount] directly — the caller already scoped [entries] to one
/// day (and excluded replies), so no extra filtering is needed. Brings the
/// title dimension already surfaced at the month/lifetime scope
/// ("📝 제목을 단 기록") down to the day view, sitting alongside
/// [photoCountOfDay]/[decoratedCountOfDay]/[favoriteCountOfDay].
int titledCountOfDay(List<DiaryEntry> entries) => titledEntryCount(entries);

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
