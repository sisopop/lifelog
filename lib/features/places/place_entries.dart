import 'package:characters/characters.dart';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../decorate/page_canvas.dart';
import '../stats/lifetime_stats.dart';

/// Top-level records whose location matches [location] (case-insensitive,
/// trimmed), newest first. 답장(reply) records are excluded so the list
/// mirrors the timeline. A blank [location] matches nothing.
List<DiaryEntry> entriesAtLocation(List<DiaryEntry> entries, String location) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return const [];
  final result = entries
      .where((e) =>
          e.replyToEntryId == null &&
          (e.location ?? '').trim().toLowerCase() == target)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}

/// The weekday (DateTime.monday=1 .. sunday=7) that the most top-level records
/// at [location] (case-insensitive, trimmed; replies excluded) fall on, or null
/// when none match or [location] is blank. Ties resolve to the earlier weekday
/// (Mon first). Lets the place view show which day of the week visits tend to
/// land on (mirrors busiestWeekdayWithMood/WithTag).
int? busiestWeekdayAtLocation(List<DiaryEntry> entries, String location) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return null;
  final counts = <int, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if ((e.location ?? '').trim().toLowerCase() != target) continue;
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

/// The part of day (0=새벽 00–05, 1=아침 06–11, 2=오후 12–17, 3=저녁 18–23) that
/// the most top-level records at [location] (case-insensitive, trimmed; replies
/// excluded) fall in, or null when none match or [location] is blank. Ties
/// resolve to the earlier bucket. Lets the place view show when visits tend to
/// be recorded (completes the 🕘 dimension: mood/tag/place).
int? busiestDayPartAtLocation(List<DiaryEntry> entries, String location) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return null;
  final counts = <int, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if ((e.location ?? '').trim().toLowerCase() != target) continue;
    counts.update(e.createdAt.hour ~/ 6, (c) => c + 1, ifAbsent: () => 1);
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

/// The earliest and latest record dates (date-only) among top-level records at
/// [location] (case-insensitive, trimmed; replies excluded), or null when none
/// match or [location] is blank. `first <= last`. Lets the place view show the
/// span of days that place was visited.
({DateTime first, DateTime last})? placeDateSpan(
    List<DiaryEntry> entries, String location) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return null;
  DateTime? first;
  DateTime? last;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if ((e.location ?? '').trim().toLowerCase() != target) continue;
    final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
    if (first == null || d.isBefore(first)) first = d;
    if (last == null || d.isAfter(last)) last = d;
  }
  return first == null ? null : (first: first, last: last!);
}

/// Tags most often recorded at [location] (case-insensitive, trimmed;
/// replies excluded), most-frequent first with ties resolved alphabetically.
/// Capped at [limit]. Empty when the place carries no tags or [location] is
/// blank. Lets the place view surface what the visits are usually about.
List<MapEntry<String, int>> tagsAtLocation(
  List<DiaryEntry> entries,
  String location, {
  int limit = 8,
}) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return const [];
  final counts = <String, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if ((e.location ?? '').trim().toLowerCase() != target) continue;
    for (final t in e.tags) {
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

/// The mood most often recorded at [location] (case-insensitive, trimmed;
/// replies excluded), or null when no matching record carries a mood or
/// [location] is blank. Ties resolve to the earlier mood in [Mood.values].
/// Lets the place view show how that place usually feels.
Mood? placeMood(List<DiaryEntry> entries, String location) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return null;
  final counts = <Mood, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if ((e.location ?? '').trim().toLowerCase() != target) continue;
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

/// Average content length (grapheme count) across top-level records at
/// [location] (case-insensitive, trimmed; replies excluded), rounded to the
/// nearest whole number. Returns 0 when no matching record exists or
/// [location] is blank. Lets the place view hint how much tends to get
/// written there.
int averageCharsAtLocation(List<DiaryEntry> entries, String location) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return 0;
  var total = 0;
  var n = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if ((e.location ?? '').trim().toLowerCase() != target) continue;
    total += e.content.trim().characters.length;
    n++;
  }
  return n == 0 ? 0 : (total / n).round();
}

/// How many top-level records at [location] (case-insensitive, trimmed; replies
/// excluded) are marked favorite. 0 when none are starred, nothing matches, or
/// [location] is blank. Lets the place view show how many records of that place
/// were kept as favorites.
int favoriteCountAtLocation(List<DiaryEntry> entries, String location) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return 0;
  var n = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if ((e.location ?? '').trim().toLowerCase() != target) continue;
    if (e.isFavorite) n++;
  }
  return n;
}

/// How many top-level records at [location] (case-insensitive, trimmed;
/// replies excluded) carry page decoration — 속지/스티커/테이프/바탕색 등
/// ([PageCanvas.isDecorated]). Decodes [DiaryEntry.pageCanvas] defensively (a
/// stored value that decodes to a plain/empty canvas — e.g. from an old
/// backup/import — does not count), mirroring [decoratedCountWithTag]. 0 when
/// none, nothing matches, or [location] is blank. Lets the place view show how
/// often that place's records get decorated, alongside [favoriteCountAtLocation].
int decoratedCountAtLocation(List<DiaryEntry> entries, String location) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return 0;
  var n = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if ((e.location ?? '').trim().toLowerCase() != target) continue;
    if (decodePageCanvas(e.pageCanvas).isDecorated) n++;
  }
  return n;
}

/// How many top-level records at [location] (case-insensitive, trimmed;
/// replies excluded) carry at least one attached photo ([DiaryEntry.mediaUrls]
/// non-empty). 0 when none, nothing matches, or [location] is blank. Mirrors
/// [decoratedCountAtLocation]'s shape but tracks a different dimension (photos
/// vs. page decoration), extending [photoCountWithTag] to the place scope.
/// Lets the place view show how often that place gets captured in pictures,
/// alongside [favoriteCountAtLocation].
int photoCountAtLocation(List<DiaryEntry> entries, String location) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return 0;
  var n = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if ((e.location ?? '').trim().toLowerCase() != target) continue;
    if (e.mediaUrls.isNotEmpty) n++;
  }
  return n;
}

/// How many top-level records at [location] (case-insensitive, trimmed;
/// replies excluded) carry a non-empty title (non-whitespace text). 0 when
/// none, nothing matches, or [location] is blank. Extends [titledCountOfDay]
/// to the place scope, mirroring [photoCountAtLocation]'s shape. Lets the
/// place view show how often that place got a title, alongside
/// [photoCountAtLocation].
int titledCountAtLocation(List<DiaryEntry> entries, String location) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return 0;
  var n = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if ((e.location ?? '').trim().toLowerCase() != target) continue;
    if ((e.title?.trim().isNotEmpty ?? false)) n++;
  }
  return n;
}

/// How many top-level records at [location] (case-insensitive, trimmed;
/// replies excluded) carry a non-empty AI summary ([DiaryEntry.aiSummary] with
/// non-whitespace text). 0 when none, nothing matches, or [location] is blank.
/// Extends [aiSummaryCountOfDay] to the place scope, mirroring
/// [titledCountAtLocation]'s shape.
int aiSummaryCountAtLocation(List<DiaryEntry> entries, String location) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return 0;
  var n = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if ((e.location ?? '').trim().toLowerCase() != target) continue;
    if (e.aiSummary?.trim().isNotEmpty ?? false) n++;
  }
  return n;
}

/// The top-level record at [location] (case-insensitive, trimmed; replies
/// excluded) with the longest (grapheme-aware, trimmed) body, or null when
/// nothing matches or [location] is blank. Ties resolve to the most recent
/// record. Reuses [longestEntry] scoped to this place's records, mirroring
/// longestEntryWithTag. Lets the place view surface a tappable "가장 긴 기록"
/// highlight.
DiaryEntry? longestEntryAtLocation(List<DiaryEntry> entries, String location) =>
    longestEntry(entriesAtLocation(entries, location));

/// The distinct journal ids among top-level records at [location]
/// (case-insensitive, trimmed; replies excluded), in first-seen order of
/// [entries]. Empty when nothing matches or [location] is blank. Lets the place
/// view show which journals a place spans.
List<String> journalIdsAtLocation(List<DiaryEntry> entries, String location) {
  final target = location.trim().toLowerCase();
  if (target.isEmpty) return const [];
  final seen = <String>{};
  final result = <String>[];
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if ((e.location ?? '').trim().toLowerCase() != target) continue;
    if (seen.add(e.journalId)) result.add(e.journalId);
  }
  return result;
}
