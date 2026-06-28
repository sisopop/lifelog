import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/stats/lifetime_stats.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _entry({
  required String id,
  String content = 'c',
  required DateTime at,
  String? replyTo,
  List<String> tags = const [],
  Mood? mood,
  bool favorite = false,
  List<String> media = const [],
  String? location,
  String? title,
  String journalId = 'jr_default',
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: journalId,
      title: title,
      content: content,
      tags: tags,
      mood: mood,
      isFavorite: favorite,
      mediaUrls: media,
      location: location,
      replyToEntryId: replyTo,
      createdAt: at,
      updatedAt: at,
    );

void main() {
  test('empty → all zero and no first date', () {
    final s = computeLifetimeStats(const []);
    expect(s.isEmpty, true);
    expect(s.totalEntries, 0);
    expect(s.firstDate, isNull);
  });

  test('aggregates totals and excludes replies', () {
    final s = computeLifetimeStats([
      _entry(id: 'a', content: '제주', at: DateTime(2026, 6, 1)), // 2 chars
      _entry(id: 'b', content: 'hello', at: DateTime(2026, 6, 2)), // 5 chars
      _entry(id: 'r', content: 'reply', at: DateTime(2026, 6, 3), replyTo: 'a'),
    ]);
    expect(s.totalEntries, 2);
    expect(s.totalChars, 7);
    expect(s.recordedDays, 2);
  });

  test('firstDate is the earliest top-level day (time stripped)', () {
    final s = computeLifetimeStats([
      _entry(id: 'late', at: DateTime(2026, 6, 10, 9)),
      _entry(id: 'early', at: DateTime(2026, 6, 2, 23, 59)),
    ]);
    expect(s.firstDate, DateTime(2026, 6, 2));
  });

  test('longestStreak counts consecutive recorded days', () {
    final s = computeLifetimeStats([
      _entry(id: '1', at: DateTime(2026, 6, 1)),
      _entry(id: '2', at: DateTime(2026, 6, 2)),
      _entry(id: '3', at: DateTime(2026, 6, 3)),
      _entry(id: '5', at: DateTime(2026, 6, 5)),
    ]);
    expect(s.longestStreak, 3);
  });

  group('daysSinceFirstEntry', () {
    test('null when there is no first date', () {
      expect(daysSinceFirstEntry(null, DateTime(2026, 6, 21)), isNull);
    });

    test('the first day counts as day 1', () {
      expect(
          daysSinceFirstEntry(DateTime(2026, 6, 21), DateTime(2026, 6, 21, 23)),
          1);
    });

    test('counts inclusive calendar days, ignoring time', () {
      // 6/1 → 6/21 spans 20 days, inclusive of the first → 21
      expect(daysSinceFirstEntry(DateTime(2026, 6, 1, 23), DateTime(2026, 6, 21)),
          21);
    });

    test('null when the first date is in the future', () {
      expect(daysSinceFirstEntry(DateTime(2026, 6, 25), DateTime(2026, 6, 21)),
          isNull);
    });
  });

  group('recordingConsistency', () {
    test('null when span is null or below 2', () {
      expect(recordingConsistency(1, null), isNull);
      expect(recordingConsistency(1, 1), isNull);
    });

    test('percent of the span that has a record', () {
      expect(recordingConsistency(5, 10), 50);
      expect(recordingConsistency(3, 8), 38); // 37.5 rounds to 38
    });

    test('clamps to 100 when recorded days exceed the span', () {
      expect(recordingConsistency(12, 10), 100);
    });

    test('every day recorded reads as 100', () {
      expect(recordingConsistency(7, 7), 100);
    });
  });

  group('avgCharsPerEntry', () {
    test('zero when there are no records', () {
      expect(computeLifetimeStats(const []).avgCharsPerEntry, 0);
    });

    test('rounds the mean body length, excluding replies', () {
      final s = computeLifetimeStats([
        _entry(id: 'a', content: '12345', at: DateTime(2026, 6, 1)), // 5
        _entry(id: 'b', content: '12', at: DateTime(2026, 6, 2)), // 2
        _entry(id: 'r', content: 'xxxx', at: DateTime(2026, 6, 3), replyTo: 'a'),
      ]);
      // (5 + 2) / 2 = 3.5 → rounds to 4
      expect(s.avgCharsPerEntry, 4);
    });
  });

  group('topTags', () {
    test('empty when no tags', () {
      expect(topTags(const []), isEmpty);
      expect(topTags([_entry(id: 'a', at: DateTime(2026, 6, 1))]), isEmpty);
    });

    test('sorts by frequency desc, ties alphabetically', () {
      final tags = topTags([
        _entry(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행', '가족']),
        _entry(id: 'b', at: DateTime(2026, 6, 2), tags: ['여행', '일상']),
        _entry(id: 'c', at: DateTime(2026, 6, 3), tags: ['여행']),
      ]);
      expect(tags.map((e) => e.key).toList(), ['여행', '가족', '일상']);
      expect(tags.first.value, 3);
      // 가족 vs 일상 both count 1 → alphabetical (가 < 일)
      expect(tags[1].key, '가족');
    });

    test('excludes replies', () {
      final tags = topTags([
        _entry(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행']),
        _entry(id: 'r', at: DateTime(2026, 6, 2), tags: ['여행'], replyTo: 'a'),
      ]);
      expect(tags.single.value, 1);
    });

    test('respects the limit', () {
      final tags = topTags([
        _entry(id: 'a', at: DateTime(2026, 6, 1), tags: ['a', 'b', 'c', 'd']),
      ], limit: 2);
      expect(tags.length, 2);
    });
  });

  group('longestEntry', () {
    test('null when there is no text', () {
      expect(longestEntry(const []), isNull);
      expect(
          longestEntry(
              [_entry(id: 'a', content: '   ', at: DateTime(2026, 6, 1))]),
          isNull);
    });

    test('picks the top-level entry with the most graphemes', () {
      final e = longestEntry([
        _entry(id: 'a', content: '짧다', at: DateTime(2026, 6, 1)),
        _entry(id: 'b', content: '아주 긴 기록이다', at: DateTime(2026, 6, 2)),
        _entry(id: 'c', content: '중간', at: DateTime(2026, 6, 3)),
      ]);
      expect(e!.entryId, 'b');
    });

    test('excludes replies', () {
      final e = longestEntry([
        _entry(id: 'a', content: '본문', at: DateTime(2026, 6, 1)),
        _entry(
            id: 'r',
            content: '이 답장이 더 길지만 제외',
            at: DateTime(2026, 6, 2),
            replyTo: 'a'),
      ]);
      expect(e!.entryId, 'a');
    });

    test('ties resolve to the most recent', () {
      final e = longestEntry([
        _entry(id: 'old', content: '1234', at: DateTime(2026, 6, 1)),
        _entry(id: 'new', content: 'abcd', at: DateTime(2026, 6, 5)),
      ]);
      expect(e!.entryId, 'new');
    });
  });

  group('busiestWeekday', () {
    test('null when there are no top-level entries', () {
      expect(busiestWeekday(const []), isNull);
      expect(
        busiestWeekday(
            [_entry(id: 'r', at: DateTime(2026, 6, 1), replyTo: 'a')]),
        isNull,
      );
    });

    test('picks the most-recorded weekday and labels it in Korean', () {
      // 2026-06-13 & 20 are Saturdays; 2026-06-15 is a Monday.
      final w = busiestWeekday([
        _entry(id: 'a', at: DateTime(2026, 6, 13)),
        _entry(id: 'b', at: DateTime(2026, 6, 20)),
        _entry(id: 'c', at: DateTime(2026, 6, 15)),
      ]);
      expect(w!.key, '토요일');
      expect(w.value, 2);
    });

    test('excludes replies from the count', () {
      // Two Mondays, but one is a reply → Monday counts once.
      final w = busiestWeekday([
        _entry(id: 'a', at: DateTime(2026, 6, 15)), // Mon
        _entry(id: 'r', at: DateTime(2026, 6, 15), replyTo: 'a'),
        _entry(id: 'b', at: DateTime(2026, 6, 16)), // Tue
      ]);
      // Mon=1, Tue=1 → tie resolves to earlier weekday (Mon).
      expect(w!.key, '월요일');
      expect(w.value, 1);
    });
  });

  group('recentMonthlyCounts', () {
    test('returns the trailing N months oldest-first ending in now', () {
      final t = recentMonthlyCounts(const [], DateTime(2026, 6, 15), months: 3);
      expect(t.map((m) => '${m.year}-${m.month}').toList(),
          ['2026-4', '2026-5', '2026-6']);
      expect(t.every((m) => m.count == 0), true);
    });

    test('crosses the year boundary correctly', () {
      final t = recentMonthlyCounts(const [], DateTime(2026, 2, 1), months: 4);
      expect(t.map((m) => '${m.year}-${m.month}').toList(),
          ['2025-11', '2025-12', '2026-1', '2026-2']);
    });

    test('counts top-level entries per month, excludes replies & old months',
        () {
      final t = recentMonthlyCounts([
        _entry(id: 'a', at: DateTime(2026, 6, 3)),
        _entry(id: 'b', at: DateTime(2026, 6, 20)),
        _entry(id: 'r', at: DateTime(2026, 6, 21), replyTo: 'a'),
        _entry(id: 'c', at: DateTime(2026, 5, 9)),
        _entry(id: 'old', at: DateTime(2025, 1, 1)), // outside window
      ], DateTime(2026, 6, 30), months: 6);
      final june = t.firstWhere((m) => m.month == 6);
      final may = t.firstWhere((m) => m.month == 5);
      expect(june.count, 2);
      expect(may.count, 1);
    });

    test('months <= 0 gives empty', () {
      expect(recentMonthlyCounts(const [], DateTime(2026, 6, 1), months: 0),
          isEmpty);
    });
  });

  group('averageEntryGapDays', () {
    test('null with fewer than two distinct days', () {
      expect(averageEntryGapDays(const []), isNull);
      expect(
          averageEntryGapDays(
              [_entry(id: 'a', at: DateTime(2026, 6, 1, 9))]),
          isNull);
      // same calendar day twice still counts as one day
      expect(
          averageEntryGapDays([
            _entry(id: 'a', at: DateTime(2026, 6, 1, 9)),
            _entry(id: 'b', at: DateTime(2026, 6, 1, 20)),
          ]),
          isNull);
    });

    test('averages the gaps between distinct recorded days', () {
      // days 6/1, 6/4, 6/10 → span 9 over 2 gaps → 4.5 → rounds to 5
      final r = averageEntryGapDays([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'b', at: DateTime(2026, 6, 4)),
        _entry(id: 'c', at: DateTime(2026, 6, 10)),
      ]);
      expect(r, 5);
    });

    test('ignores replies', () {
      // top-level on 6/1 and 6/3 → span 2 / 1 gap = 2; reply on 6/30 ignored
      final r = averageEntryGapDays([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'b', at: DateTime(2026, 6, 3)),
        _entry(id: 'r', at: DateTime(2026, 6, 30), replyTo: 'a'),
      ]);
      expect(r, 2);
    });
  });

  group('busiestDayPartOfMonth', () {
    test('null when the month has no record', () {
      expect(
          busiestDayPartOfMonth(
              [_entry(id: 'a', at: DateTime(2026, 5, 1, 9))], 2026, 6),
          isNull);
    });

    test('picks the busiest part within the month, ignoring other months', () {
      final r = busiestDayPartOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1, 20)), // evening
        _entry(id: 'b', at: DateTime(2026, 6, 2, 21)), // evening
        _entry(id: 'c', at: DateTime(2026, 6, 3, 9)), // morning
        _entry(id: 'd', at: DateTime(2026, 7, 1, 9)), // other month, ignored
      ], 2026, 6);
      expect(r!.key, DayPart.evening);
      expect(r.value, 2);
    });

    test('ignores replies', () {
      final r = busiestDayPartOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1, 9)), // morning
        _entry(id: 'r', at: DateTime(2026, 6, 1, 20), replyTo: 'a'), // ignored
      ], 2026, 6);
      expect(r!.key, DayPart.morning);
      expect(r.value, 1);
    });
  });

  group('firstEntry', () {
    test('null when empty', () {
      expect(firstEntry(const []), isNull);
    });

    test('returns the earliest top-level entry', () {
      final e = firstEntry([
        _entry(id: 'late', at: DateTime(2026, 6, 10, 9)),
        _entry(id: 'early', at: DateTime(2026, 6, 2, 23, 59)),
        _entry(id: 'mid', at: DateTime(2026, 6, 5)),
      ]);
      expect(e!.entryId, 'early');
    });

    test('ignores replies even when a reply is older', () {
      final e = firstEntry([
        _entry(id: 'top', at: DateTime(2026, 6, 10)),
        _entry(id: 'r', at: DateTime(2026, 6, 1), replyTo: 'top'),
      ]);
      expect(e!.entryId, 'top');
    });
  });

  group('distinctMonthsRecorded', () {
    test('counts distinct year-months of top-level entries', () {
      // 2026-05 (one), 2026-06 (two records → still one month), 2025-06
      // (different year → distinct) = 3 distinct months.
      final n = distinctMonthsRecorded([
        _entry(id: 'a', at: DateTime(2026, 5, 3)),
        _entry(id: 'b', at: DateTime(2026, 6, 1)),
        _entry(id: 'c', at: DateTime(2026, 6, 20)),
        _entry(id: 'd', at: DateTime(2025, 6, 9)),
      ]);
      expect(n, 3);
    });

    test('excludes replies', () {
      // top-level only in 2026-06; reply in 2026-05 ignored → 1 month.
      final n = distinctMonthsRecorded([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'r', at: DateTime(2026, 5, 1), replyTo: 'a'),
      ]);
      expect(n, 1);
    });

    test('zero when empty', () {
      expect(distinctMonthsRecorded(const []), 0);
    });
  });

  group('photoEntryCount', () {
    test('counts top-level entries with at least one photo', () {
      final n = photoEntryCount([
        _entry(id: 'a', at: DateTime(2026, 6, 1), media: ['u1']),
        _entry(id: 'b', at: DateTime(2026, 6, 2), media: ['u2', 'u3']),
        _entry(id: 'c', at: DateTime(2026, 6, 3)), // no photo
      ]);
      expect(n, 2);
    });

    test('excludes replies even with photos', () {
      final n = photoEntryCount([
        _entry(id: 'a', at: DateTime(2026, 6, 1), media: ['u1']),
        _entry(id: 'r', at: DateTime(2026, 6, 2), replyTo: 'a', media: ['u2']),
      ]);
      expect(n, 1);
    });

    test('zero when empty', () {
      expect(photoEntryCount(const []), 0);
    });
  });

  group('mostUsedTag', () {
    test('returns the most frequent tag with its count', () {
      final t = mostUsedTag([
        _entry(id: 'a', at: DateTime(2026, 6, 1), tags: ['가족', '일상']),
        _entry(id: 'b', at: DateTime(2026, 6, 2), tags: ['가족']),
        _entry(id: 'c', at: DateTime(2026, 6, 3), tags: ['일상']),
      ]);
      expect(t!.key, '가족');
      expect(t.value, 2);
    });

    test('excludes replies', () {
      final t = mostUsedTag([
        _entry(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행']),
        _entry(id: 'r', at: DateTime(2026, 6, 2), replyTo: 'a', tags: ['여행', '여행']),
      ]);
      expect(t!.key, '여행');
      expect(t.value, 1);
    });

    test('null when no tag exists', () {
      expect(mostUsedTag(const []), isNull);
      expect(
        mostUsedTag([_entry(id: 'a', at: DateTime(2026, 6, 1))]),
        isNull,
      );
    });
  });

  group('photoEntryCountOfMonth', () {
    test('counts only the given month\'s top-level photo records', () {
      final n = photoEntryCountOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), media: ['u1']),
        _entry(id: 'b', at: DateTime(2026, 6, 2), media: ['u2']),
        _entry(id: 'c', at: DateTime(2026, 6, 3)), // no photo
        _entry(id: 'd', at: DateTime(2026, 5, 9), media: ['u4']), // other month
      ], 2026, 6);
      expect(n, 2);
    });

    test('excludes replies even with photos', () {
      final n = photoEntryCountOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), media: ['u1']),
        _entry(id: 'r', at: DateTime(2026, 6, 2), replyTo: 'a', media: ['u2']),
      ], 2026, 6);
      expect(n, 1);
    });

    test('zero when month has no photo record', () {
      expect(photoEntryCountOfMonth(const [], 2026, 6), 0);
    });
  });

  group('taggedEntryShare', () {
    test('rounds the share of top-level entries that carry a tag', () {
      // 2 of 3 tagged → 67%.
      final pct = taggedEntryShare([
        _entry(id: 'a', at: DateTime(2026, 6, 1), tags: ['가족']),
        _entry(id: 'b', at: DateTime(2026, 6, 2), tags: ['일상', '육아']),
        _entry(id: 'c', at: DateTime(2026, 6, 3)), // no tags
      ]);
      expect(pct, 67);
    });

    test('excludes replies from numerator and denominator', () {
      // top-level: 1 tagged of 1 → 100%; reply ignored.
      final pct = taggedEntryShare([
        _entry(id: 'a', at: DateTime(2026, 6, 1), tags: ['가족']),
        _entry(id: 'r', at: DateTime(2026, 6, 2), replyTo: 'a', tags: ['x']),
      ]);
      expect(pct, 100);
    });

    test('null when no top-level entries', () {
      expect(taggedEntryShare(const []), isNull);
    });
  });

  group('taggedEntryShareOfMonth', () {
    test('filters to the month, then reuses taggedEntryShare', () {
      // June: 1 tagged of 2 → 50%. May entry (tagged) is excluded.
      final pct = taggedEntryShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), tags: ['가족']),
        _entry(id: 'b', at: DateTime(2026, 6, 2)),
        _entry(id: 'c', at: DateTime(2026, 5, 9), tags: ['x']),
      ], 2026, 6);
      expect(pct, 50);
    });

    test('null when that month has no top-level records', () {
      final pct = taggedEntryShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 5, 1), tags: ['가족']),
      ], 2026, 6);
      expect(pct, isNull);
    });
  });

  group('titleEntryShareOfMonth', () {
    test('filters to the month, then reuses titleEntryShare', () {
      // June: 1 titled of 2 → 50%. May entry (titled) is excluded.
      final pct = titleEntryShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), title: '제목'),
        _entry(id: 'b', at: DateTime(2026, 6, 2)),
        _entry(id: 'c', at: DateTime(2026, 5, 9), title: 'x'),
      ], 2026, 6);
      expect(pct, 50);
    });

    test('replies are excluded from the month share', () {
      final pct = titleEntryShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), title: '제목'),
        _entry(id: 'b', at: DateTime(2026, 6, 2), replyTo: 'a', title: '답'),
      ], 2026, 6);
      expect(pct, 100);
    });

    test('null when that month has no top-level records', () {
      final pct = titleEntryShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 5, 1), title: '제목'),
      ], 2026, 6);
      expect(pct, isNull);
    });
  });

  group('longestStreakOfMonth', () {
    test('longest consecutive in-month run, clipped to the month', () {
      // June: 1,2,3 consecutive (=3), then gap, then 10. May 31 ignored.
      final n = longestStreakOfMonth([
        _entry(id: 'm', at: DateTime(2026, 5, 31)),
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'b', at: DateTime(2026, 6, 2)),
        _entry(id: 'c', at: DateTime(2026, 6, 3)),
        _entry(id: 'd', at: DateTime(2026, 6, 10)),
      ], 2026, 6);
      expect(n, 3);
    });

    test('replies are excluded', () {
      // Only day 1 has a top-level record; the day-2 reply does not extend it.
      final n = longestStreakOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'b', at: DateTime(2026, 6, 2), replyTo: 'a'),
      ], 2026, 6);
      expect(n, 1);
    });

    test('0 when that month has no records', () {
      final n = longestStreakOfMonth([
        _entry(id: 'a', at: DateTime(2026, 5, 1)),
      ], 2026, 6);
      expect(n, 0);
    });
  });

  group('distinctTagsOfMonth', () {
    test('counts distinct in-month tags, ignoring other months', () {
      // June: 가족, 여행, 가족(dup) → 2 distinct. May 운동 excluded.
      final n = distinctTagsOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), tags: ['가족']),
        _entry(id: 'b', at: DateTime(2026, 6, 2), tags: ['여행', '가족']),
        _entry(id: 'c', at: DateTime(2026, 5, 9), tags: ['운동']),
      ], 2026, 6);
      expect(n, 2);
    });

    test('replies are excluded', () {
      final n = distinctTagsOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), tags: ['가족']),
        _entry(id: 'b', at: DateTime(2026, 6, 2), replyTo: 'a', tags: ['여행']),
      ], 2026, 6);
      expect(n, 1);
    });

    test('0 when that month has no tagged records', () {
      final n = distinctTagsOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'b', at: DateTime(2026, 5, 1), tags: ['가족']),
      ], 2026, 6);
      expect(n, 0);
    });
  });

  group('distinctTagsUsed', () {
    test('counts distinct tags across all months, ignoring duplicates', () {
      // 가족, 여행, 가족(dup), 운동 → 3 distinct, spanning two months.
      final n = distinctTagsUsed([
        _entry(id: 'a', at: DateTime(2026, 6, 1), tags: ['가족']),
        _entry(id: 'b', at: DateTime(2026, 6, 2), tags: ['여행', '가족']),
        _entry(id: 'c', at: DateTime(2026, 5, 9), tags: ['운동']),
      ]);
      expect(n, 3);
    });

    test('replies are excluded', () {
      final n = distinctTagsUsed([
        _entry(id: 'a', at: DateTime(2026, 6, 1), tags: ['가족']),
        _entry(id: 'b', at: DateTime(2026, 6, 2), replyTo: 'a', tags: ['여행']),
      ]);
      expect(n, 1);
    });

    test('0 when nothing is tagged', () {
      final n = distinctTagsUsed([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
      ]);
      expect(n, 0);
    });
  });

  group('photoEntryShare', () {
    test('percent of top-level records that carry a photo, rounded', () {
      // 1 of 3 top-level records has media → 33%.
      final pct = photoEntryShare([
        _entry(id: 'a', at: DateTime(2026, 6, 1), media: ['u1']),
        _entry(id: 'b', at: DateTime(2026, 6, 2)),
        _entry(id: 'c', at: DateTime(2026, 6, 3)),
      ]);
      expect(pct, 33);
    });

    test('replies are excluded from both numerator and denominator', () {
      // Only the top-level 'a' (with photo) counts → 100%.
      final pct = photoEntryShare([
        _entry(id: 'a', at: DateTime(2026, 6, 1), media: ['u1']),
        _entry(id: 'r', at: DateTime(2026, 6, 1), replyTo: 'a', media: ['u2']),
      ]);
      expect(pct, 100);
    });

    test('null when there are no top-level records', () {
      final pct = photoEntryShare([
        _entry(id: 'r', at: DateTime(2026, 6, 1), replyTo: 'a', media: ['u1']),
      ]);
      expect(pct, isNull);
    });
  });

  group('favoriteEntryShare', () {
    test('percent of top-level records that are starred, rounded', () {
      // 1 of 3 top-level records is favorite → 33%.
      final pct = favoriteEntryShare([
        _entry(id: 'a', at: DateTime(2026, 6, 1), favorite: true),
        _entry(id: 'b', at: DateTime(2026, 6, 2)),
        _entry(id: 'c', at: DateTime(2026, 6, 3)),
      ]);
      expect(pct, 33);
    });

    test('replies are excluded from both numerator and denominator', () {
      // Only the top-level 'a' (starred) counts → 100%.
      final pct = favoriteEntryShare([
        _entry(id: 'a', at: DateTime(2026, 6, 1), favorite: true),
        _entry(id: 'r', at: DateTime(2026, 6, 1), replyTo: 'a', favorite: true),
      ]);
      expect(pct, 100);
    });

    test('null when there are no top-level records', () {
      final pct = favoriteEntryShare([
        _entry(id: 'r', at: DateTime(2026, 6, 1), replyTo: 'a', favorite: true),
      ]);
      expect(pct, isNull);
    });
  });

  group('positiveMoodShare', () {
    test('share of "good" among records that carry a mood, rounded', () {
      // 1 good of 2 mood-bearing records → 50%. The 3rd record has no mood and
      // is excluded from the denominator.
      final pct = positiveMoodShare([
        _entry(id: 'a', at: DateTime(2026, 6, 1), mood: Mood.good),
        _entry(id: 'b', at: DateTime(2026, 6, 2), mood: Mood.neutral),
        _entry(id: 'c', at: DateTime(2026, 6, 3)),
      ]);
      expect(pct, 50);
    });

    test('replies are excluded from the denominator', () {
      // Only the top-level good mood counts → 100%.
      final pct = positiveMoodShare([
        _entry(id: 'a', at: DateTime(2026, 6, 1), mood: Mood.good),
        _entry(id: 'r', at: DateTime(2026, 6, 1), replyTo: 'a', mood: Mood.hard),
      ]);
      expect(pct, 100);
    });

    test('null when no top-level record carries a mood', () {
      final pct = positiveMoodShare([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'r', at: DateTime(2026, 6, 1), replyTo: 'a', mood: Mood.good),
      ]);
      expect(pct, isNull);
    });
  });

  group('busiestJournal', () {
    test('returns the journalId with the most top-level records', () {
      final busy = busiestJournal([
        _entry(id: 'a', at: DateTime(2026, 6, 1), journalId: 'j1'),
        _entry(id: 'b', at: DateTime(2026, 6, 2), journalId: 'j2'),
        _entry(id: 'c', at: DateTime(2026, 6, 3), journalId: 'j2'),
      ]);
      expect(busy?.key, 'j2');
      expect(busy?.value, 2);
    });

    test('replies are excluded from the per-journal counts', () {
      final busy = busiestJournal([
        _entry(id: 'a', at: DateTime(2026, 6, 1), journalId: 'j1'),
        _entry(id: 'b', at: DateTime(2026, 6, 2), journalId: 'j1'),
        _entry(id: 'c', at: DateTime(2026, 6, 3), journalId: 'j2'),
        // Three replies in j2 must NOT make it the busiest.
        _entry(id: 'r1', at: DateTime(2026, 6, 3), replyTo: 'c', journalId: 'j2'),
        _entry(id: 'r2', at: DateTime(2026, 6, 3), replyTo: 'c', journalId: 'j2'),
      ]);
      expect(busy?.key, 'j1');
      expect(busy?.value, 2);
    });

    test('null when fewer than two distinct journals carry a record', () {
      expect(busiestJournal(const []), isNull);
      final single = busiestJournal([
        _entry(id: 'a', at: DateTime(2026, 6, 1), journalId: 'j1'),
        _entry(id: 'b', at: DateTime(2026, 6, 2), journalId: 'j1'),
      ]);
      expect(single, isNull);
    });

    test('ties resolve to the first-appearing journalId', () {
      final busy = busiestJournal([
        _entry(id: 'a', at: DateTime(2026, 6, 1), journalId: 'j1'),
        _entry(id: 'b', at: DateTime(2026, 6, 2), journalId: 'j2'),
      ]);
      expect(busy?.key, 'j1');
      expect(busy?.value, 1);
    });
  });

  group('replyCount', () {
    test('counts only reply records, ignoring top-level ones', () {
      final n = replyCount([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'r1', at: DateTime(2026, 6, 1), replyTo: 'a'),
        _entry(id: 'r2', at: DateTime(2026, 6, 2), replyTo: 'a'),
      ]);
      expect(n, 2);
    });

    test('zero when there are no replies', () {
      final n = replyCount([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'b', at: DateTime(2026, 6, 2)),
      ]);
      expect(n, 0);
    });

    test('zero for an empty list', () {
      expect(replyCount(const []), 0);
    });
  });

  group('replyCountOfMonth', () {
    test('filters to the month, then reuses replyCount', () {
      // June: 2 replies. The May reply is excluded.
      final n = replyCountOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'r1', at: DateTime(2026, 6, 1), replyTo: 'a'),
        _entry(id: 'r2', at: DateTime(2026, 6, 2), replyTo: 'a'),
        _entry(id: 'r3', at: DateTime(2026, 5, 9), replyTo: 'a'),
      ], 2026, 6);
      expect(n, 2);
    });

    test('zero when that month has no replies', () {
      final n = replyCountOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'r', at: DateTime(2026, 5, 1), replyTo: 'a'),
      ], 2026, 6);
      expect(n, 0);
    });
  });

  group('favoriteCount', () {
    test('counts starred top-level records, excludes replies', () {
      final n = favoriteCount([
        _entry(id: 'a', at: DateTime(2026, 6, 1), favorite: true),
        _entry(id: 'b', at: DateTime(2026, 6, 2)),
        _entry(id: 'c', at: DateTime(2026, 6, 3), favorite: true),
        _entry(
            id: 'd', at: DateTime(2026, 6, 4), replyTo: 'a', favorite: true),
      ]);
      expect(n, 2);
    });

    test('zero when none starred or empty', () {
      expect(favoriteCount(const []), 0);
      expect(
        favoriteCount([_entry(id: 'a', at: DateTime(2026, 6, 1))]),
        0,
      );
    });
  });

  group('locationEntryShare', () {
    test('rounds the located share to a percent', () {
      // 1 located of 3 → 33%.
      final pct = locationEntryShare([
        _entry(id: 'a', at: DateTime(2026, 6, 1), location: '제주'),
        _entry(id: 'b', at: DateTime(2026, 6, 2)),
        _entry(id: 'c', at: DateTime(2026, 6, 3), location: '   '),
      ]);
      expect(pct, 33);
    });

    test('excludes replies', () {
      final pct = locationEntryShare([
        _entry(id: 'a', at: DateTime(2026, 6, 1), location: '제주'),
        _entry(
            id: 'b', at: DateTime(2026, 6, 2), replyTo: 'a', location: '서울'),
      ]);
      expect(pct, 100);
    });

    test('null when there are no top-level records', () {
      expect(locationEntryShare(const []), isNull);
    });
  });

  group('locationEntryShareOfMonth', () {
    test('filters to the month, then reuses locationEntryShare', () {
      // June: 1 located of 2 → 50%. May entry is excluded.
      final pct = locationEntryShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), location: '제주'),
        _entry(id: 'b', at: DateTime(2026, 6, 2)),
        _entry(id: 'c', at: DateTime(2026, 5, 9), location: '서울'),
      ], 2026, 6);
      expect(pct, 50);
    });

    test('null when that month has no top-level records', () {
      final pct = locationEntryShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 5, 1), location: '서울'),
      ], 2026, 6);
      expect(pct, isNull);
    });
  });

  group('moodEntryShare', () {
    test('rounds the mood-carrying share to a percent', () {
      // 2 of 5 carry a mood → 40%.
      final pct = moodEntryShare([
        _entry(id: 'a', at: DateTime(2026, 6, 1), mood: Mood.good),
        _entry(id: 'b', at: DateTime(2026, 6, 2), mood: Mood.neutral),
        _entry(id: 'c', at: DateTime(2026, 6, 3)),
        _entry(id: 'd', at: DateTime(2026, 6, 4)),
        _entry(id: 'e', at: DateTime(2026, 6, 5)),
      ]);
      expect(pct, 40);
    });

    test('excludes replies', () {
      final pct = moodEntryShare([
        _entry(id: 'a', at: DateTime(2026, 6, 1), mood: Mood.good),
        _entry(
            id: 'b', at: DateTime(2026, 6, 2), replyTo: 'a', mood: Mood.hard),
      ]);
      expect(pct, 100);
    });

    test('null when there are no top-level records', () {
      expect(moodEntryShare(const []), isNull);
    });
  });

  group('moodEntryShareOfMonth', () {
    test('filters to the month, then reuses moodEntryShare', () {
      // June: 1 mood of 2 → 50%. May entry is excluded.
      final pct = moodEntryShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), mood: Mood.good),
        _entry(id: 'b', at: DateTime(2026, 6, 2)),
        _entry(id: 'c', at: DateTime(2026, 5, 9), mood: Mood.hard),
      ], 2026, 6);
      expect(pct, 50);
    });

    test('excludes replies', () {
      final pct = moodEntryShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), mood: Mood.good),
        _entry(
            id: 'r', at: DateTime(2026, 6, 2), replyTo: 'a', mood: Mood.hard),
      ], 2026, 6);
      expect(pct, 100);
    });

    test('null when that month has no top-level records', () {
      final pct = moodEntryShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 5, 1), mood: Mood.good),
      ], 2026, 6);
      expect(pct, isNull);
    });
  });

  group('favoriteEntryShareOfMonth', () {
    test('filters to the month, then reuses favoriteEntryShare', () {
      // June: 1 favorite of 2 → 50%. May entry is excluded.
      final pct = favoriteEntryShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), favorite: true),
        _entry(id: 'b', at: DateTime(2026, 6, 2)),
        _entry(id: 'c', at: DateTime(2026, 5, 9), favorite: true),
      ], 2026, 6);
      expect(pct, 50);
    });

    test('excludes replies', () {
      final pct = favoriteEntryShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), favorite: true),
        _entry(
            id: 'r', at: DateTime(2026, 6, 2), replyTo: 'a', favorite: true),
      ], 2026, 6);
      expect(pct, 100);
    });

    test('null when that month has no top-level records', () {
      final pct = favoriteEntryShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 5, 1), favorite: true),
      ], 2026, 6);
      expect(pct, isNull);
    });
  });

  group('photoEntryShareOfMonth', () {
    test('filters to the month, then reuses photoEntryShare', () {
      // June: 1 photo of 2 → 50%. May entry is excluded.
      final pct = photoEntryShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), media: ['u1']),
        _entry(id: 'b', at: DateTime(2026, 6, 2)),
        _entry(id: 'c', at: DateTime(2026, 5, 9), media: ['u2']),
      ], 2026, 6);
      expect(pct, 50);
    });

    test('excludes replies', () {
      final pct = photoEntryShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), media: ['u1']),
        _entry(
            id: 'r', at: DateTime(2026, 6, 2), replyTo: 'a', media: ['u2']),
      ], 2026, 6);
      expect(pct, 100);
    });

    test('null when that month has no top-level records', () {
      final pct = photoEntryShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 5, 1), media: ['u1']),
      ], 2026, 6);
      expect(pct, isNull);
    });
  });

  group('busiestJournalOfMonth', () {
    test('filters to the month, then reuses busiestJournal', () {
      // June: j2 has 2, j1 has 1 → j2. May entries are excluded.
      final busy = busiestJournalOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), journalId: 'j1'),
        _entry(id: 'b', at: DateTime(2026, 6, 2), journalId: 'j2'),
        _entry(id: 'c', at: DateTime(2026, 6, 3), journalId: 'j2'),
        _entry(id: 'd', at: DateTime(2026, 5, 9), journalId: 'j1'),
      ], 2026, 6);
      expect(busy?.key, 'j2');
      expect(busy?.value, 2);
    });

    test('null when the month has fewer than two distinct journals', () {
      final busy = busiestJournalOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), journalId: 'j1'),
        _entry(id: 'b', at: DateTime(2026, 6, 2), journalId: 'j1'),
      ], 2026, 6);
      expect(busy, isNull);
    });

    test('excludes replies from the per-journal counts', () {
      final busy = busiestJournalOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1), journalId: 'j1'),
        _entry(id: 'b', at: DateTime(2026, 6, 2), journalId: 'j1'),
        _entry(id: 'c', at: DateTime(2026, 6, 3), journalId: 'j2'),
        _entry(id: 'r', at: DateTime(2026, 6, 3), replyTo: 'c', journalId: 'j2'),
      ], 2026, 6);
      expect(busy?.key, 'j1');
      expect(busy?.value, 2);
    });
  });

  group('dayPartBreakdown', () {
    test('empty → empty map', () {
      expect(dayPartBreakdown(const []), isEmpty);
    });

    test('counts by day-part and excludes replies', () {
      final m = dayPartBreakdown([
        _entry(id: 'a', at: DateTime(2026, 6, 1, 2)), // dawn
        _entry(id: 'b', at: DateTime(2026, 6, 2, 9)), // morning
        _entry(id: 'c', at: DateTime(2026, 6, 3, 14)), // afternoon
        _entry(id: 'd', at: DateTime(2026, 6, 4, 20)), // evening
        _entry(id: 'e', at: DateTime(2026, 6, 5, 21)), // evening
        _entry(id: 'r', at: DateTime(2026, 6, 6, 9), replyTo: 'a'), // ignored
      ]);
      expect(m[DayPart.dawn], 1);
      expect(m[DayPart.morning], 1);
      expect(m[DayPart.afternoon], 1);
      expect(m[DayPart.evening], 2);
    });

    test('only present day-parts appear, ordered by DayPart.values', () {
      final m = dayPartBreakdown([
        _entry(id: 'a', at: DateTime(2026, 6, 1, 20)), // evening
        _entry(id: 'b', at: DateTime(2026, 6, 2, 2)), // dawn
      ]);
      expect(m.keys.toList(), [DayPart.dawn, DayPart.evening]);
    });
  });

  group('dayPartBreakdownOfMonth', () {
    test('empty when the month has no record', () {
      expect(
          dayPartBreakdownOfMonth(
              [_entry(id: 'a', at: DateTime(2026, 5, 1, 9))], 2026, 6),
          isEmpty);
    });

    test('counts only the given month, by day-part', () {
      final m = dayPartBreakdownOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1, 2)), // dawn, in
        _entry(id: 'b', at: DateTime(2026, 6, 2, 20)), // evening, in
        _entry(id: 'c', at: DateTime(2026, 7, 1, 9)), // other month, out
      ], 2026, 6);
      expect(m[DayPart.dawn], 1);
      expect(m[DayPart.evening], 1);
      expect(m.containsKey(DayPart.morning), isFalse);
    });
  });

  group('weekendRecordShare', () {
    test('percent of top-level records on Sat/Sun', () {
      // 2026-06-13 Sat, 2026-06-14 Sun, 2026-06-15 Mon, 2026-06-16 Tue
      // → 2 of 4 on weekend = 50%
      final r = weekendRecordShare([
        _entry(id: 'a', at: DateTime(2026, 6, 13)),
        _entry(id: 'b', at: DateTime(2026, 6, 14)),
        _entry(id: 'c', at: DateTime(2026, 6, 15)),
        _entry(id: 'd', at: DateTime(2026, 6, 16)),
      ]);
      expect(r, 50);
    });

    test('excludes replies', () {
      // top-level: 6/15 Mon (weekday). reply on 6/13 Sat ignored → 0%
      final r = weekendRecordShare([
        _entry(id: 'a', at: DateTime(2026, 6, 15)),
        _entry(id: 'r', at: DateTime(2026, 6, 13), replyTo: 'a'),
      ]);
      expect(r, 0);
    });

    test('null when no top-level records', () {
      expect(weekendRecordShare(const []), isNull);
      expect(
          weekendRecordShare([
            _entry(id: 'r', at: DateTime(2026, 6, 13), replyTo: 'a'),
          ]),
          isNull);
    });
  });

  group('weekendRecordShareOfMonth', () {
    test('only counts the target month', () {
      // June: 6/13 Sat + 6/15 Mon → 1 of 2 weekend = 50%.
      // July entry on a Saturday is ignored.
      final r = weekendRecordShareOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 13)),
        _entry(id: 'b', at: DateTime(2026, 6, 15)),
        _entry(id: 'c', at: DateTime(2026, 7, 4)),
      ], 2026, 6);
      expect(r, 50);
    });

    test('null when the month has no top-level records', () {
      expect(
          weekendRecordShareOfMonth([
            _entry(id: 'a', at: DateTime(2026, 7, 4)),
          ], 2026, 6),
          isNull);
    });
  });

  group('longestGapDays', () {
    test('null with fewer than two distinct days', () {
      expect(longestGapDays(const []), isNull);
      expect(
          longestGapDays([
            _entry(id: 'a', at: DateTime(2026, 6, 1, 9)),
            _entry(id: 'b', at: DateTime(2026, 6, 1, 20)),
          ]),
          isNull);
    });

    test('returns the largest gap between consecutive recorded days', () {
      // days 6/1, 6/3, 6/10 → gaps 2 and 7 → 7
      final r = longestGapDays([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'b', at: DateTime(2026, 6, 3)),
        _entry(id: 'c', at: DateTime(2026, 6, 10)),
      ]);
      expect(r, 7);
    });

    test('ignores replies', () {
      // top-level on 6/1 and 6/5 → gap 4; reply on 6/30 ignored
      final r = longestGapDays([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'b', at: DateTime(2026, 6, 5)),
        _entry(id: 'r', at: DateTime(2026, 6, 30), replyTo: 'a'),
      ]);
      expect(r, 4);
    });
  });

  group('monthlyRecordingRate', () {
    test('past month uses full month length as denominator', () {
      // May has 31 days; 10 recorded → 10/31 ≈ 32%
      final r = monthlyRecordingRate(10, 2026, 5, DateTime(2026, 6, 23));
      expect(r, 32);
    });

    test('current month uses days elapsed so far', () {
      // June, today = 23rd; 4 recorded → 4/23 ≈ 17%
      final r = monthlyRecordingRate(4, 2026, 6, DateTime(2026, 6, 23));
      expect(r, 17);
    });

    test('null when nothing recorded', () {
      expect(monthlyRecordingRate(0, 2026, 6, DateTime(2026, 6, 23)), isNull);
    });

    test('clamps to 100', () {
      final r = monthlyRecordingRate(40, 2026, 6, DateTime(2026, 6, 23));
      expect(r, 100);
    });
  });

  group('longestGapDaysOfMonth', () {
    test('only considers the given month', () {
      // June: 6/1, 6/5 → gap 4. July entry ignored.
      final r = longestGapDaysOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'b', at: DateTime(2026, 6, 5)),
        _entry(id: 'c', at: DateTime(2026, 7, 20)),
      ], 2026, 6);
      expect(r, 4);
    });

    test('null when the month has fewer than two distinct days', () {
      final r = longestGapDaysOfMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
      ], 2026, 6);
      expect(r, isNull);
    });
  });

  group('mostActiveMonth', () {
    test('returns the month with the most top-level records', () {
      final m = mostActiveMonth([
        _entry(id: '1', at: DateTime(2026, 5, 3)),
        _entry(id: '2', at: DateTime(2026, 6, 1)),
        _entry(id: '3', at: DateTime(2026, 6, 10)),
        _entry(id: '4', at: DateTime(2026, 6, 20)),
      ]);
      expect(m, isNotNull);
      expect(m!.year, 2026);
      expect(m.month, 6);
      expect(m.count, 3);
    });

    test('excludes replies from the count', () {
      final m = mostActiveMonth([
        _entry(id: '1', at: DateTime(2026, 6, 1)),
        _entry(id: 'r1', at: DateTime(2026, 6, 2), replyTo: '1'),
        _entry(id: 'r2', at: DateTime(2026, 6, 3), replyTo: '1'),
        _entry(id: '2', at: DateTime(2026, 7, 1)),
        _entry(id: '3', at: DateTime(2026, 7, 2)),
      ]);
      // June has 1 real record, July has 2 → July wins.
      expect(m!.month, 7);
      expect(m.count, 2);
    });

    test('ties resolve to the earlier month', () {
      final m = mostActiveMonth([
        _entry(id: '1', at: DateTime(2026, 6, 1)),
        _entry(id: '2', at: DateTime(2026, 8, 1)),
      ]);
      expect(m!.year, 2026);
      expect(m.month, 6);
      expect(m.count, 1);
    });

    test('null when there are no records', () {
      expect(mostActiveMonth(const []), isNull);
      expect(
          mostActiveMonth(
              [_entry(id: 'r', at: DateTime(2026, 6, 1), replyTo: 'x')]),
          isNull);
    });
  });

  group('longestEntryOfMonth', () {
    test('returns the longest top-level record in that month', () {
      final e = longestEntryOfMonth([
        _entry(id: 'a', content: '짧다', at: DateTime(2026, 6, 1)),
        _entry(id: 'b', content: '훨씬 더 긴 기록', at: DateTime(2026, 6, 2)),
        _entry(id: 'c', content: '다른 달의 아주 긴 기록', at: DateTime(2026, 7, 1)),
      ], 2026, 6);
      expect(e!.entryId, 'b');
    });

    test('ignores replies', () {
      final e = longestEntryOfMonth([
        _entry(id: 'a', content: '본문', at: DateTime(2026, 6, 1)),
        _entry(
            id: 'r',
            content: '아주 긴 답장 본문입니다',
            at: DateTime(2026, 6, 2),
            replyTo: 'a'),
      ], 2026, 6);
      expect(e!.entryId, 'a');
    });

    test('null when the month has no record with text', () {
      expect(longestEntryOfMonth(const [], 2026, 6), isNull);
      expect(
          longestEntryOfMonth(
              [_entry(id: 'a', content: '6월', at: DateTime(2026, 5, 1))],
              2026,
              6),
          isNull);
    });
  });

  group('dominantMood', () {
    test('returns the most-recorded mood', () {
      final m = dominantMood([
        _entry(id: '1', at: DateTime(2026, 6, 1), mood: Mood.good),
        _entry(id: '2', at: DateTime(2026, 6, 2), mood: Mood.good),
        _entry(id: '3', at: DateTime(2026, 6, 3), mood: Mood.hard),
      ]);
      expect(m, Mood.good);
    });

    test('ignores replies and moodless records', () {
      final m = dominantMood([
        _entry(id: '1', at: DateTime(2026, 6, 1), mood: Mood.hard),
        _entry(
            id: '2', at: DateTime(2026, 6, 2), mood: Mood.good, replyTo: '1'),
        _entry(
            id: '3', at: DateTime(2026, 6, 3), mood: Mood.good, replyTo: '1'),
        _entry(id: '4', at: DateTime(2026, 6, 4)),
      ]);
      expect(m, Mood.hard);
    });

    test('ties resolve to the earlier Mood.values', () {
      final m = dominantMood([
        _entry(id: '1', at: DateTime(2026, 6, 1), mood: Mood.hard),
        _entry(id: '2', at: DateTime(2026, 6, 2), mood: Mood.good),
      ]);
      expect(m, Mood.good);
    });

    test('null when nothing carries a mood', () {
      expect(dominantMood([_entry(id: '1', at: DateTime(2026, 6, 1))]), isNull);
      expect(dominantMood(const []), isNull);
    });
  });

  group('favoriteCountOfMonth', () {
    test('counts starred top-level records in the month', () {
      final n = favoriteCountOfMonth([
        _entry(id: '1', at: DateTime(2026, 6, 1), favorite: true),
        _entry(id: '2', at: DateTime(2026, 6, 20), favorite: true),
        _entry(id: '3', at: DateTime(2026, 6, 5)), // not starred
      ], 2026, 6);
      expect(n, 2);
    });

    test('excludes other months and replies', () {
      final n = favoriteCountOfMonth([
        _entry(id: 'in', at: DateTime(2026, 6, 3), favorite: true),
        _entry(id: 'may', at: DateTime(2026, 5, 30), favorite: true),
        _entry(
            id: 'reply',
            at: DateTime(2026, 6, 4),
            favorite: true,
            replyTo: 'in'),
      ], 2026, 6);
      expect(n, 1);
    });

    test('zero when none starred', () {
      expect(
          favoriteCountOfMonth(
              [_entry(id: '1', at: DateTime(2026, 6, 1))], 2026, 6),
          0);
      expect(favoriteCountOfMonth(const [], 2026, 6), 0);
    });
  });

  group('entriesThisYear', () {
    final now = DateTime(2026, 6, 27);

    test('counts only this year, excludes replies', () {
      final n = entriesThisYear([
        _entry(id: 'a', at: DateTime(2026, 1, 5)),
        _entry(id: 'b', at: DateTime(2026, 6, 1)),
        _entry(id: 'old', at: DateTime(2025, 12, 31)),
        _entry(id: 'r', at: DateTime(2026, 3, 3), replyTo: 'a'),
      ], now);
      expect(n, 2);
    });

    test('zero when nothing this year', () {
      final n = entriesThisYear(
          [_entry(id: 'old', at: DateTime(2025, 6, 1))], now);
      expect(n, 0);
    });

    test('zero when empty', () {
      expect(entriesThisYear(const [], now), 0);
    });
  });

  group('averageEntriesPerMonth', () {
    test('rounds total over distinct months, excludes replies', () {
      // 5 top-level across 2 months (3 in June, 2 in May) -> 5/2 = 2.5 -> 3.
      final n = averageEntriesPerMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'b', at: DateTime(2026, 6, 2)),
        _entry(id: 'c', at: DateTime(2026, 6, 3)),
        _entry(id: 'd', at: DateTime(2026, 5, 1)),
        _entry(id: 'e', at: DateTime(2026, 5, 2)),
        _entry(id: 'r', at: DateTime(2026, 6, 4), replyTo: 'a'),
      ]);
      expect(n, 3);
    });

    test('null when only one distinct month', () {
      final n = averageEntriesPerMonth([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'b', at: DateTime(2026, 6, 20)),
      ]);
      expect(n, isNull);
    });

    test('null when empty', () {
      expect(averageEntriesPerMonth(const []), isNull);
    });
  });

  group('maxEntriesInOneDay', () {
    test('counts the busiest single day, excludes replies', () {
      // June 2: 3 records; June 3: 1; replies on June 2 ignored.
      final n = maxEntriesInOneDay([
        _entry(id: 'a', at: DateTime(2026, 6, 2, 8)),
        _entry(id: 'b', at: DateTime(2026, 6, 2, 12)),
        _entry(id: 'c', at: DateTime(2026, 6, 2, 20)),
        _entry(id: 'd', at: DateTime(2026, 6, 3, 9)),
        _entry(id: 'r', at: DateTime(2026, 6, 2, 21), replyTo: 'a'),
      ]);
      expect(n, 3);
    });

    test('1 when each day has a single record', () {
      final n = maxEntriesInOneDay([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'b', at: DateTime(2026, 6, 2)),
      ]);
      expect(n, 1);
    });

    test('0 when empty', () {
      expect(maxEntriesInOneDay(const []), 0);
    });
  });

  group('titleEntryShare', () {
    test('rounds titled share, excludes replies and blank titles', () {
      // 4 top-level: 2 titled (incl. one trimmed), 1 blank, 1 null -> 50%.
      final n = titleEntryShare([
        _entry(id: 'a', at: DateTime(2026, 6, 1), title: '제주도에서의 하루'),
        _entry(id: 'b', at: DateTime(2026, 6, 2), title: '  봄 '),
        _entry(id: 'c', at: DateTime(2026, 6, 3), title: '   '),
        _entry(id: 'd', at: DateTime(2026, 6, 4)),
        _entry(id: 'r', at: DateTime(2026, 6, 5), replyTo: 'a', title: '답장'),
      ]);
      expect(n, 50);
    });

    test('null when no top-level records', () {
      expect(titleEntryShare(const []), isNull);
      expect(
        titleEntryShare([
          _entry(id: 'r', at: DateTime(2026, 6, 1), replyTo: 'a', title: 't'),
        ]),
        isNull,
      );
    });

    test('0 when no record has a title', () {
      final n = titleEntryShare([
        _entry(id: 'a', at: DateTime(2026, 6, 1)),
        _entry(id: 'b', at: DateTime(2026, 6, 2), title: ''),
      ]);
      expect(n, 0);
    });
  });
}
