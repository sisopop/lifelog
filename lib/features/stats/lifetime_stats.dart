import 'package:characters/characters.dart';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import 'stats_provider.dart';
import 'streak.dart';

// Pure insight helpers (day-part, weekday, gaps, shares, counts, moods, tags,
// monthly trends) live in the part file to keep each file under 500 lines.
part 'lifetime_insights.dart';

/// A whole-history summary shown on the "내 기록 요약" screen.
class LifetimeStats {
  const LifetimeStats({
    required this.totalEntries,
    required this.totalChars,
    required this.recordedDays,
    required this.longestStreak,
    this.firstDate,
  });

  final int totalEntries; // top-level records only
  final int totalChars; // grapheme-aware sum of bodies
  final int recordedDays; // distinct calendar days with a record
  final int longestStreak; // best consecutive-day run, ever
  final DateTime? firstDate; // earliest top-level record, null when none

  bool get isEmpty => totalEntries == 0;

  /// Average body length per record (graphemes), rounded to the nearest whole
  /// number. 0 when there are no records.
  int get avgCharsPerEntry =>
      totalEntries == 0 ? 0 : (totalChars / totalEntries).round();
}

/// Pure: how many days the journaling habit spans, counting the first day as
/// day 1 (so the day of [firstDate] returns 1). Returns null when [firstDate]
/// is null or lies in the future relative to [now]. Time is ignored.
int? daysSinceFirstEntry(DateTime? firstDate, DateTime now) {
  if (firstDate == null) return null;
  final first = DateTime(firstDate.year, firstDate.month, firstDate.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(first).inDays;
  if (diff < 0) return null;
  return diff + 1;
}

/// Pure: what share of the days since the first record actually have a record,
/// as an integer percent (0..100). [recordedDays] is the count of distinct
/// calendar days with a record; [spanDays] is the inclusive day count since the
/// first entry (i.e. [daysSinceFirstEntry]). Returns null when [spanDays] is
/// null or below 2 (a single-day span has no meaningful ratio). Clamped to 100.
int? recordingConsistency(int recordedDays, int? spanDays) {
  if (spanDays == null || spanDays < 2) return null;
  final pct = (recordedDays / spanDays * 100).round();
  return pct > 100 ? 100 : pct;
}

/// Pure: aggregate every [entries] into lifetime totals. 답장(reply) records
/// are excluded so the figures match the timeline.
LifetimeStats computeLifetimeStats(List<DiaryEntry> entries) {
  final tops = entries.where((e) => e.replyToEntryId == null).toList();
  if (tops.isEmpty) {
    return const LifetimeStats(
      totalEntries: 0,
      totalChars: 0,
      recordedDays: 0,
      longestStreak: 0,
    );
  }
  final days = recordedDates(tops);
  final first = tops
      .map((e) => e.createdAt)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  return LifetimeStats(
    totalEntries: tops.length,
    totalChars: totalChars(tops),
    recordedDays: days.length,
    longestStreak: longestStreak(days),
    firstDate: DateTime(first.year, first.month, first.day),
  );
}

/// Pure: the average number of top-level records per month the user actually
/// recorded in, rounded to the nearest whole number. Reuses
/// [distinctMonthsRecorded]. Replies are excluded. Returns null when fewer than
/// two distinct months carry a record (a single month's average is just its
/// total, so it is not a meaningful pace).
int? averageEntriesPerMonth(List<DiaryEntry> entries) {
  final tops = entries.where((e) => e.replyToEntryId == null).length;
  final months = distinctMonthsRecorded(entries);
  if (months < 2) return null;
  return (tops / months).round();
}

/// Pure: the most top-level records written on any single calendar day. Replies
/// are excluded. Returns 0 when there are no records. Time is ignored — records
/// are grouped by their [DateTime] year/month/day.
int maxEntriesInOneDay(List<DiaryEntry> entries) {
  final perDay = <String, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    final d = e.createdAt;
    final key = '${d.year}-${d.month}-${d.day}';
    perDay[key] = (perDay[key] ?? 0) + 1;
  }
  if (perDay.isEmpty) return 0;
  return perDay.values.reduce((a, b) => a > b ? a : b);
}

/// Pure: the most top-level records written on any single calendar day within
/// [year]/[month]. Filters [entries] to the month, then reuses
/// [maxEntriesInOneDay] (replies excluded). Returns 0 when that month has no
/// top-level records — the monthly sibling of [maxEntriesInOneDay].
int maxEntriesInOneDayOfMonth(List<DiaryEntry> entries, int year, int month) {
  final monthly = entries.where(
      (e) => e.createdAt.year == year && e.createdAt.month == month);
  return maxEntriesInOneDay(monthly.toList());
}

/// Pure: what share of top-level records carry an AI summary (a non-empty
/// [DiaryEntry.aiSummary]), as a 0–100 percent. Replies are excluded. A summary
/// counts only when it has non-whitespace text. Returns null when there are no
/// top-level records — a member of the share family ([titleEntryShare] etc.)
/// surfacing how often the AI summary feature was used.
int? aiSummaryShare(List<DiaryEntry> entries) {
  var total = 0;
  var summarized = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    total++;
    if (e.aiSummary?.trim().isNotEmpty ?? false) summarized++;
  }
  if (total == 0) return null;
  return (summarized * 100 / total).round();
}

/// Pure: the AI-summary share (0–100) for one calendar month. Filters to the
/// given [year]/[month], then reuses [aiSummaryShare]. Returns null when that
/// month has no top-level records.
int? aiSummaryShareOfMonth(List<DiaryEntry> entries, int year, int month) {
  final monthly = entries.where(
      (e) => e.createdAt.year == year && e.createdAt.month == month);
  return aiSummaryShare(monthly.toList());
}

/// Pure: what share of top-level records were shared beyond private — i.e.
/// [EntryVisibility.link] or [EntryVisibility.public] — as a 0–100 percent.
/// Replies are excluded. Returns null when there are no top-level records — a
/// member of the share family ([aiSummaryShare] etc.) surfacing how often
/// records were opened up rather than kept "나만 보기".
int? sharedEntryShare(List<DiaryEntry> entries) {
  var total = 0;
  var shared = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    total++;
    if (e.visibility != EntryVisibility.private) shared++;
  }
  if (total == 0) return null;
  return (shared * 100 / total).round();
}

/// Pure: what share of top-level records carry a non-empty title, as a 0–100
/// percent. Replies are excluded. A title counts only when it has non-whitespace
/// text. Returns null when there are no top-level records.
int? titleEntryShare(List<DiaryEntry> entries) {
  var total = 0;
  var titled = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    total++;
    if ((e.title?.trim().isNotEmpty ?? false)) titled++;
  }
  if (total == 0) return null;
  return (titled * 100 / total).round();
}

/// Pure: the longest consecutive-day recording run within one calendar month.
/// Filters [entries] to the given [year]/[month], then reuses [recordedDates]
/// and [longestStreak] (both replies-excluded). Returns 0 when that month has
/// no top-level records. A run is counted only within the month — a streak
/// spanning the month boundary is clipped to its in-month days.
int longestStreakOfMonth(List<DiaryEntry> entries, int year, int month) {
  final monthly = entries.where(
      (e) => e.createdAt.year == year && e.createdAt.month == month);
  return longestStreak(recordedDates(monthly.toList()));
}

/// Pure: how many distinct tags were used in one calendar month. Filters
/// [entries] to the given [year]/[month], then reuses [topTags] (replies
/// excluded; tags compared exactly as stored). Returns 0 when that month has no
/// tagged top-level records.
int distinctTagsOfMonth(List<DiaryEntry> entries, int year, int month) {
  final monthly = entries.where(
      (e) => e.createdAt.year == year && e.createdAt.month == month);
  return topTags(monthly.toList(), limit: 0).length;
}

/// Pure: what share of one calendar month's top-level records carry a mood, as
/// a 0–100 percent. Filters [entries] to the given [year]/[month], then reuses
/// [moodEntryShare] (replies excluded). Returns null when that month has no
/// top-level records — the monthly sibling of [moodEntryShare].
int? moodEntryShareOfMonth(List<DiaryEntry> entries, int year, int month) {
  final monthly = entries.where(
      (e) => e.createdAt.year == year && e.createdAt.month == month);
  return moodEntryShare(monthly.toList());
}

/// Pure: what share of one calendar month's top-level records are starred
/// (favorite), as a 0–100 percent. Filters [entries] to the given
/// [year]/[month], then reuses [favoriteEntryShare] (replies excluded). Returns
/// null when that month has no top-level records — the monthly sibling of
/// [favoriteEntryShare] and the share companion of [favoriteCountOfMonth].
int? favoriteEntryShareOfMonth(List<DiaryEntry> entries, int year, int month) {
  final monthly = entries.where(
      (e) => e.createdAt.year == year && e.createdAt.month == month);
  return favoriteEntryShare(monthly.toList());
}

/// Pure: what share of one calendar month's top-level records carry at least one
/// photo, as a 0–100 percent. Filters [entries] to the given [year]/[month],
/// then reuses [photoEntryShare] (replies excluded). Returns null when that
/// month has no top-level records — the monthly sibling of [photoEntryShare]
/// and the share companion of [photoEntryCountOfMonth].
int? photoEntryShareOfMonth(List<DiaryEntry> entries, int year, int month) {
  final monthly = entries.where(
      (e) => e.createdAt.year == year && e.createdAt.month == month);
  return photoEntryShare(monthly.toList());
}

/// Pure: which journal holds the most top-level records in [year]/[month], as a
/// `MapEntry(journalId, count)`. Filters [entries] to the month, then reuses
/// [busiestJournal] (replies excluded; null when fewer than two distinct
/// journals carry a record that month; ties → first-appearing journalId). The
/// monthly sibling of [busiestJournal].
MapEntry<String, int>? busiestJournalOfMonth(
    List<DiaryEntry> entries, int year, int month) {
  final monthly = entries.where(
      (e) => e.createdAt.year == year && e.createdAt.month == month);
  return busiestJournal(monthly.toList());
}

/// Pure: how many distinct tags were ever used across all [entries]. Reuses
/// [topTags] with no limit (replies excluded; tags compared exactly as stored).
/// Returns 0 when nothing is tagged — the whole-history sibling of
/// [distinctTagsOfMonth].
int distinctTagsUsed(List<DiaryEntry> entries) =>
    topTags(entries, limit: 0).length;

/// Pure: what share of top-level records carry at least one photo
/// ([DiaryEntry.mediaUrls] non-empty), as a 0–100 percent. Replies are
/// excluded. Returns null when there are no top-level records — the photo
/// member of the share family ([taggedEntryShare]/[locationEntryShare]/
/// [moodEntryShare]/[titleEntryShare]) and the share sibling of
/// [photoEntryCount].
int? photoEntryShare(List<DiaryEntry> entries) {
  var total = 0;
  var withPhoto = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    total++;
    if (e.mediaUrls.isNotEmpty) withPhoto++;
  }
  if (total == 0) return null;
  return (withPhoto * 100 / total).round();
}

/// Pure: which journal holds the most top-level records, as a
/// `MapEntry(journalId, count)`. Replies are excluded. Returns null when fewer
/// than two distinct journals carry a top-level record (a single journal is
/// self-evident, so the insight is hidden). Ties resolve to the journalId that
/// first appears in [entries] (insertion order is preserved by the map).
MapEntry<String, int>? busiestJournal(List<DiaryEntry> entries) {
  final counts = <String, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    counts[e.journalId] = (counts[e.journalId] ?? 0) + 1;
  }
  if (counts.length < 2) return null;
  MapEntry<String, int>? best;
  counts.forEach((id, n) {
    if (best == null || n > best!.value) best = MapEntry(id, n);
  });
  return best;
}

/// Pure: how many 답장(reply) records exist across all [entries] — records
/// whose [DiaryEntry.replyToEntryId] is non-null. This is the one figure that
/// COUNTS replies instead of excluding them (every other stat drops them).
/// Returns 0 when there are none.
int replyCount(List<DiaryEntry> entries) {
  var count = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) count++;
  }
  return count;
}

/// Pure: how many 답장(reply) records fall in [year]/[month]. Filters [entries]
/// to the month, then reuses [replyCount] — the monthly sibling of [replyCount]
/// and the one monthly figure that counts replies instead of excluding them.
/// Returns 0 when that month has none.
int replyCountOfMonth(List<DiaryEntry> entries, int year, int month) {
  final monthly = entries.where(
      (e) => e.createdAt.year == year && e.createdAt.month == month);
  return replyCount(monthly.toList());
}

/// Pure: what share of top-level records are starred (favorite), as a 0–100
/// percent. Replies are excluded. Returns null when there are no top-level
/// records — the favorite member of the share family ([taggedEntryShare]/
/// [locationEntryShare]/[moodEntryShare]/[titleEntryShare]/[photoEntryShare])
/// and the share sibling of [favoriteCount].
int? favoriteEntryShare(List<DiaryEntry> entries) {
  var total = 0;
  var starred = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    total++;
    if (e.isFavorite) starred++;
  }
  if (total == 0) return null;
  return (starred * 100 / total).round();
}

/// Pure: among top-level records that carry a mood, what share are the "good"
/// mood, as a 0–100 percent. Replies and mood-less records are excluded from the
/// denominator (so this measures positivity *within* the moods that were
/// recorded, not across all records). Returns null when no top-level record
/// carries a mood. The positivity companion to [moodEntryShare] (how many
/// records carry ANY mood) and to dominantMood (which mood is most common).
int? positiveMoodShare(List<DiaryEntry> entries) {
  var withMood = 0;
  var good = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (e.mood == null) continue;
    withMood++;
    if (e.mood == Mood.good) good++;
  }
  if (withMood == 0) return null;
  return (good * 100 / withMood).round();
}

/// Pure: the "good"-mood share (0–100) among one calendar month's mood-bearing
/// top-level records. Filters [entries] to the given [year]/[month], then reuses
/// [positiveMoodShare] (replies and mood-less records excluded from the
/// denominator). Returns null when that month has no mood-bearing record — the
/// monthly sibling of [positiveMoodShare] and the positivity companion of
/// [moodEntryShareOfMonth].
int? positiveMoodShareOfMonth(List<DiaryEntry> entries, int year, int month) {
  final monthly = entries.where(
      (e) => e.createdAt.year == year && e.createdAt.month == month);
  return positiveMoodShare(monthly.toList());
}

/// Pure: the average grapheme-aware body length across top-level records,
/// rounded to a whole number. Replies are excluded. Uses the same trimmed,
/// grapheme-counted measure as [totalChars] (Korean syllables and emoji count
/// as one) but divided by the record count — a typical-length companion to
/// [totalChars] (the running total) and to longestEntry (the single longest).
/// Returns null when there are no top-level records.
int? averageEntryLength(List<DiaryEntry> entries) {
  var total = 0;
  var chars = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    total++;
    chars += e.content.trim().characters.length;
  }
  if (total == 0) return null;
  return (chars / total).round();
}

/// Pure: the average grapheme-aware body length across one calendar month's
/// top-level records, rounded. Filters [entries] to the given [year]/[month],
/// then reuses [averageEntryLength] (replies excluded). Returns null when that
/// month has no top-level record — the monthly sibling of [averageEntryLength]
/// (and the 회고 counterpart of the summary's avgCharsPerEntry).
int? averageEntryLengthOfMonth(List<DiaryEntry> entries, int year, int month) {
  final monthly = entries.where(
      (e) => e.createdAt.year == year && e.createdAt.month == month);
  return averageEntryLength(monthly.toList());
}

/// Pure: how many distinct calendar days in [now]'s year carry a top-level
/// record. Replies are excluded; multiple records on the same day count once.
/// Returns 0 when nothing was recorded this year. The days-based companion to
/// [entriesThisYear] (which counts records, not days).
int recordedDaysThisYear(List<DiaryEntry> entries, DateTime now) {
  final days = <String>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    final d = e.createdAt;
    if (d.year != now.year) continue;
    days.add('${d.year}-${d.month}-${d.day}');
  }
  return days.length;
}
