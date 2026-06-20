import '../../shared/models/diary_entry.dart';

/// "그날의 추억" / On This Day — top-level entries written on the same calendar
/// day (month + day) as [today] in *earlier years*. Today's own year is
/// excluded (these are memories, not today's records). Most recent first.
List<DiaryEntry> entriesOnThisDay(List<DiaryEntry> entries, DateTime today) {
  final out = entries
      .where((e) =>
          e.replyToEntryId == null &&
          e.createdAt.month == today.month &&
          e.createdAt.day == today.day &&
          e.createdAt.year < today.year)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return out;
}

/// Whole-year difference between [from] and [today] (e.g. 1 → "1년 전").
int yearsAgo(DateTime from, DateTime today) => today.year - from.year;
