import 'package:characters/characters.dart';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../decorate/page_canvas.dart';
import '../stats/lifetime_stats.dart';

/// The weekday (DateTime.monday=1 .. sunday=7) that the most top-level records
/// carrying [tag] fall on (replies excluded), or null when the tag has no
/// records. Ties resolve to the earlier weekday (Mon first). Lets the tag view
/// show which day of the week that theme tends to land on (mirrors
/// busiestWeekdayWithMood).
int? busiestWeekdayWithTag(List<DiaryEntry> entries, String tag) {
  final counts = <int, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null || !e.tags.contains(tag)) continue;
    counts.update(e.createdAt.weekday, (c) => c + 1, ifAbsent: () => 1);
  }
  int? best;
  var bestCount = 0;
  for (var wd = DateTime.monday; wd <= DateTime.sunday; wd++) {
    final c = counts[wd] ?? 0;
    if (c > bestCount) {
      bestCount = c;
      best = wd;
    }
  }
  return best;
}

/// The time-of-day bucket the most top-level records carrying [tag] fall in
/// (replies excluded), or null when the tag has no records. Buckets: 0=새벽
/// (00–05), 1=아침 (06–11), 2=오후 (12–17), 3=저녁 (18–23). Ties resolve to the
/// earlier bucket. Lets the tag view show when in the day that theme tends to
/// be recorded (mirrors busiestDayPartWithMood — a 🕘 dimension).
int? busiestDayPartWithTag(List<DiaryEntry> entries, String tag) {
  final counts = <int, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null || !e.tags.contains(tag)) continue;
    final part = e.createdAt.hour ~/ 6;
    counts.update(part, (c) => c + 1, ifAbsent: () => 1);
  }
  int? best;
  var bestCount = 0;
  for (var p = 0; p < 4; p++) {
    final c = counts[p] ?? 0;
    if (c > bestCount) {
      bestCount = c;
      best = p;
    }
  }
  return best;
}

/// Top-level records tagged with [tag], newest first.
/// 답장(reply) records are excluded so the list mirrors the timeline.
List<DiaryEntry> entriesWithTag(List<DiaryEntry> entries, String tag) {
  final result = entries
      .where((e) => e.replyToEntryId == null && e.tags.contains(tag))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}

/// The earliest and latest record dates (date-only) among top-level records
/// carrying [tag] (replies excluded), or null when the tag has no records.
/// `first <= last`. Lets the tag view show how long the tag has been in use.
({DateTime first, DateTime last})? tagDateSpan(
    List<DiaryEntry> entries, String tag) {
  DateTime? first;
  DateTime? last;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (!e.tags.contains(tag)) continue;
    final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
    if (first == null || d.isBefore(first)) first = d;
    if (last == null || d.isAfter(last)) last = d;
  }
  return first == null ? null : (first: first, last: last!);
}

/// Tags that most often appear on the same records as [tag], most-frequent
/// first (ties alphabetical), excluding [tag] itself and replies. Capped at
/// [limit]. Empty when nothing co-occurs.
List<MapEntry<String, int>> coOccurringTags(
  List<DiaryEntry> entries,
  String tag, {
  int limit = 8,
}) {
  final counts = <String, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (!e.tags.contains(tag)) continue;
    for (final t in e.tags) {
      if (t == tag) continue;
      counts[t] = (counts[t] ?? 0) + 1;
    }
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  return limit <= 0 ? sorted : sorted.take(limit).toList();
}

/// The mood most often attached to top-level records carrying [tag] (replies
/// excluded), or null when no such record has a mood. Ties resolve to the
/// earlier mood in [Mood.values]. Lets the tag view show how that theme feels.
Mood? tagMood(List<DiaryEntry> entries, String tag) {
  final counts = <Mood, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (!e.tags.contains(tag)) continue;
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

/// Average content length (grapheme count) across top-level records carrying
/// [tag] (replies excluded), rounded to the nearest whole number. Returns 0
/// when the tag has no top-level records. Lets the tag view hint how much
/// tends to get written about that theme.
int averageCharsWithTag(List<DiaryEntry> entries, String tag) {
  var total = 0;
  var n = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (!e.tags.contains(tag)) continue;
    total += e.content.trim().characters.length;
    n++;
  }
  return n == 0 ? 0 : (total / n).round();
}

/// How many top-level records carrying [tag] are marked favorite (replies
/// excluded). 0 when none are starred or the tag has no records. Lets the tag
/// view show how many records of that theme were kept as favorites.
int favoriteCountWithTag(List<DiaryEntry> entries, String tag) {
  var n = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (!e.tags.contains(tag)) continue;
    if (e.isFavorite) n++;
  }
  return n;
}

/// How many top-level records carrying [tag] carry page decoration — 속지/
/// 스티커/테이프/바탕색 등 ([PageCanvas.isDecorated]), replies excluded. Decodes
/// [DiaryEntry.pageCanvas] defensively (a stored value that decodes to a
/// plain/empty canvas — e.g. from an old backup/import — does not count),
/// mirroring [decoratedCountOfDay]. 0 when none or the tag has no records.
/// Lets the tag view show how often that theme gets decorated, alongside
/// [favoriteCountWithTag].
int decoratedCountWithTag(List<DiaryEntry> entries, String tag) {
  var n = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (!e.tags.contains(tag)) continue;
    if (decodePageCanvas(e.pageCanvas).isDecorated) n++;
  }
  return n;
}

/// Distinct non-empty places recorded with [tag] (top-level records; replies
/// excluded), most-frequent first with ties resolved alphabetically. Capped at
/// [limit]. Empty when no matching record carries a place. Lets the tag view
/// show where that theme tends to happen (mirrors placesWithMood).
List<String> placesWithTag(
  List<DiaryEntry> entries,
  String tag, {
  int limit = 4,
}) {
  final counts = <String, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null || !e.tags.contains(tag)) continue;
    final p = e.location?.trim() ?? '';
    if (p.isEmpty) continue;
    counts[p] = (counts[p] ?? 0) + 1;
  }
  final places = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });
  return limit <= 0 ? places : places.take(limit).toList();
}

/// The top-level record carrying [tag] with the longest (grapheme-aware,
/// trimmed) body, or null when the tag has no top-level record with text.
/// Ties resolve to the most recent record. Reuses [longestEntry] scoped to
/// this tag's records, mirroring how longestEntryOfMonth scopes it to a
/// month. Lets the tag view surface a tappable "가장 긴 기록" highlight.
DiaryEntry? longestEntryWithTag(List<DiaryEntry> entries, String tag) =>
    longestEntry(entriesWithTag(entries, tag));

/// The distinct journal ids among top-level records carrying [tag] (replies
/// excluded), in first-seen order of [entries]. Empty when the tag has no
/// top-level records. Lets the tag view show which journals a theme spans.
List<String> journalIdsWithTag(List<DiaryEntry> entries, String tag) {
  final seen = <String>{};
  final result = <String>[];
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (!e.tags.contains(tag)) continue;
    if (seen.add(e.journalId)) result.add(e.journalId);
  }
  return result;
}
