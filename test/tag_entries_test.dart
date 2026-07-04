import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/tags/tag_entries.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _e({
  required String id,
  required DateTime at,
  List<String> tags = const [],
  String? replyTo,
  Mood? mood,
  String content = 'x',
  bool favorite = false,
  String journal = 'j1',
  String? location,
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: journal,
      replyToEntryId: replyTo,
      content: content,
      tags: tags,
      mood: mood,
      location: location,
      isFavorite: favorite,
      createdAt: at,
      updatedAt: at,
    );

void main() {
  final entries = [
    _e(id: '1', at: DateTime(2026, 6, 10), tags: ['여행', '가족']),
    _e(id: '2', at: DateTime(2026, 6, 15), tags: ['여행']), // newer
    _e(id: '3', at: DateTime(2026, 6, 12), tags: ['여행'], replyTo: '1'), // reply
    _e(id: '4', at: DateTime(2026, 6, 11), tags: ['일']),
  ];

  test('returns top-level entries with the tag, newest first', () {
    final r = entriesWithTag(entries, '여행');
    expect(r.map((e) => e.entryId), ['2', '1']);
  });

  test('matches any of an entry\'s tags', () {
    final r = entriesWithTag(entries, '가족');
    expect(r.map((e) => e.entryId), ['1']);
  });

  test('empty when no entry carries the tag', () {
    expect(entriesWithTag(entries, '운동'), isEmpty);
  });

  group('coOccurringTags', () {
    test('counts tags sharing a record with the target, by frequency', () {
      final r = coOccurringTags([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행', '가족']),
        _e(id: 'b', at: DateTime(2026, 6, 2), tags: ['여행', '가족']),
        _e(id: 'c', at: DateTime(2026, 6, 3), tags: ['여행', '맛집']),
        _e(id: 'd', at: DateTime(2026, 6, 4), tags: ['일상']), // no overlap
      ], '여행');
      expect(r.map((e) => e.key).toList(), ['가족', '맛집']);
      expect(r.first.value, 2);
    });

    test('excludes the target tag itself and replies', () {
      final r = coOccurringTags([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행', '가족']),
        _e(id: 'r', at: DateTime(2026, 6, 2), tags: ['여행', '가족'], replyTo: 'a'),
      ], '여행');
      expect(r.length, 1);
      expect(r.single.key, '가족');
      expect(r.single.value, 1); // reply not counted
    });

    test('ties resolve alphabetically and respect the limit', () {
      final r = coOccurringTags([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행', '다', '나', '가']),
      ], '여행', limit: 2);
      expect(r.map((e) => e.key).toList(), ['가', '나']);
    });

    test('empty when nothing co-occurs', () {
      final r = coOccurringTags([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행']),
      ], '여행');
      expect(r, isEmpty);
    });
  });

  group('tagDateSpan', () {
    test('earliest and latest date-only, replies excluded', () {
      final s = tagDateSpan(entries, '여행');
      expect(s!.first, DateTime(2026, 6, 10));
      expect(s.last, DateTime(2026, 6, 15));
    });

    test('drops the time component to date-only', () {
      final s = tagDateSpan([
        _e(id: '1', at: DateTime(2026, 6, 10, 23, 59), tags: ['여행']),
      ], '여행');
      expect(s!.first, DateTime(2026, 6, 10));
      expect(s.first, s.last);
    });

    test('null when the tag has no top-level records', () {
      expect(tagDateSpan(entries, '운동'), isNull);
      // a tag that appears only on a reply
      expect(
        tagDateSpan([
          _e(id: 'r', at: DateTime(2026, 6, 1), tags: ['답'], replyTo: 'x'),
        ], '답'),
        isNull,
      );
    });
  });

  group('tagMood', () {
    test('most frequent mood, replies excluded', () {
      final m = tagMood([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'], mood: Mood.good),
        _e(id: 'b', at: DateTime(2026, 6, 2), tags: ['여행'], mood: Mood.good),
        _e(id: 'c', at: DateTime(2026, 6, 3), tags: ['여행'], mood: Mood.hard),
        _e(
            id: 'r',
            at: DateTime(2026, 6, 4),
            tags: ['여행'],
            mood: Mood.hard,
            replyTo: 'a'),
        _e(id: 'o', at: DateTime(2026, 6, 5), tags: ['일'], mood: Mood.hard),
      ], '여행');
      expect(m, Mood.good);
    });

    test('ties resolve to the earlier Mood.values entry', () {
      final m = tagMood([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'], mood: Mood.hard),
        _e(id: 'b', at: DateTime(2026, 6, 2), tags: ['여행'], mood: Mood.good),
      ], '여행');
      expect(m, Mood.good);
    });

    test('null when the tag has no records with a mood', () {
      expect(
          tagMood([_e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'])], '여행'),
          isNull);
      expect(tagMood(entries, '운동'), isNull);
    });
  });

  group('averageCharsWithTag', () {
    test('rounds the mean grapheme length, replies excluded', () {
      final r = averageCharsWithTag([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'], content: '가나다'), // 3
        _e(
            id: 'b',
            at: DateTime(2026, 6, 2),
            tags: ['여행'],
            content: '  Diary😊  '), // trim → 6
        _e(
            id: 'r',
            at: DateTime(2026, 6, 3),
            tags: ['여행'],
            content: '길다길다',
            replyTo: 'a'), // reply
        _e(
            id: 'o',
            at: DateTime(2026, 6, 4),
            tags: ['일'],
            content: '아주아주긴글'), // other tag
      ], '여행');
      expect(r, 5); // (3 + 6) / 2 = 4.5 → 5
    });

    test('single record yields its own length', () {
      expect(
        averageCharsWithTag(
            [_e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'], content: '안녕😊')],
            '여행'),
        3,
      );
    });

    test('zero when the tag has no top-level records', () {
      expect(averageCharsWithTag(const [], '여행'), 0);
      expect(
          averageCharsWithTag(
              [_e(id: 'a', at: DateTime(2026, 6, 1), tags: ['일'])], '여행'),
          0);
      expect(
        averageCharsWithTag([
          _e(id: 'r', at: DateTime(2026, 6, 1), tags: ['여행'], replyTo: 'x'),
        ], '여행'),
        0,
      );
    });
  });

  group('favoriteCountWithTag', () {
    test('counts favorited top-level records, replies excluded', () {
      final n = favoriteCountWithTag([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'], favorite: true),
        _e(id: 'b', at: DateTime(2026, 6, 2), tags: ['여행']), // not favorite
        _e(id: 'c', at: DateTime(2026, 6, 3), tags: ['여행'], favorite: true),
        _e(
            id: 'r',
            at: DateTime(2026, 6, 4),
            tags: ['여행'],
            favorite: true,
            replyTo: 'a'), // reply ignored
        _e(id: 'o', at: DateTime(2026, 6, 5), tags: ['일'], favorite: true),
      ], '여행');
      expect(n, 2);
    });

    test('zero when none favorited, tag absent, or list empty', () {
      expect(
          favoriteCountWithTag(
              [_e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'])], '여행'),
          0);
      expect(
          favoriteCountWithTag(
              [_e(id: 'a', at: DateTime(2026, 6, 1), tags: ['일'], favorite: true)],
              '여행'),
          0);
      expect(favoriteCountWithTag(const [], '여행'), 0);
    });
  });

  group('journalIdsWithTag', () {
    test('distinct journals in first-seen order, replies & other tags excluded',
        () {
      final r = journalIdsWithTag([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'], journal: 'j1'),
        _e(id: 'b', at: DateTime(2026, 6, 2), tags: ['여행'], journal: 'j2'),
        _e(id: 'c', at: DateTime(2026, 6, 3), tags: ['여행'], journal: 'j1'), // dup
        _e(
            id: 'r',
            at: DateTime(2026, 6, 4),
            tags: ['여행'],
            journal: 'j3',
            replyTo: 'a'), // reply ignored
        _e(id: 'o', at: DateTime(2026, 6, 5), tags: ['일'], journal: 'j4'), // other
      ], '여행');
      expect(r, ['j1', 'j2']);
    });

    test('empty when the tag has no top-level records', () {
      expect(journalIdsWithTag(const [], '여행'), isEmpty);
      expect(
          journalIdsWithTag(
              [_e(id: 'a', at: DateTime(2026, 6, 1), tags: ['일'])], '여행'),
          isEmpty);
      expect(
        journalIdsWithTag([
          _e(id: 'r', at: DateTime(2026, 6, 1), tags: ['여행'], replyTo: 'x'),
        ], '여행'),
        isEmpty,
      );
    });
  });

  group('busiestWeekdayWithTag', () {
    test('picks the weekday with the most records, replies & other tag excluded',
        () {
      final r = busiestWeekdayWithTag([
        _e(id: 'a', at: DateTime(2026, 6, 13), tags: ['여행']), // Sat
        _e(id: 'b', at: DateTime(2026, 6, 20), tags: ['여행']), // Sat
        _e(id: 'c', at: DateTime(2026, 6, 8), tags: ['여행']), // Mon
        _e(id: 'r', at: DateTime(2026, 6, 8), tags: ['여행'], replyTo: 'a'),
        _e(id: 'o', at: DateTime(2026, 6, 8), tags: ['일']), // other tag
      ], '여행');
      expect(r, DateTime.saturday);
    });

    test('ties resolve to the earlier weekday (Mon first)', () {
      final r = busiestWeekdayWithTag([
        _e(id: 'a', at: DateTime(2026, 6, 13), tags: ['여행']), // Sat
        _e(id: 'b', at: DateTime(2026, 6, 8), tags: ['여행']), // Mon
      ], '여행');
      expect(r, DateTime.monday);
    });

    test('null when the tag has no top-level records', () {
      expect(busiestWeekdayWithTag(const [], '여행'), isNull);
      expect(
          busiestWeekdayWithTag(
              [_e(id: 'a', at: DateTime(2026, 6, 8), tags: ['일'])], '여행'),
          isNull);
      expect(
        busiestWeekdayWithTag([
          _e(id: 'r', at: DateTime(2026, 6, 8), tags: ['여행'], replyTo: 'x'),
        ], '여행'),
        isNull,
      );
    });
  });

  group('busiestDayPartWithTag', () {
    test('picks the busiest time bucket, replies & other tag excluded', () {
      final r = busiestDayPartWithTag([
        _e(id: 'a', at: DateTime(2026, 6, 13, 14), tags: ['여행']), // 오후=2
        _e(id: 'b', at: DateTime(2026, 6, 20, 17), tags: ['여행']), // 오후=2
        _e(id: 'c', at: DateTime(2026, 6, 8, 9), tags: ['여행']), // 아침=1
        _e(id: 'r', at: DateTime(2026, 6, 8, 14), tags: ['여행'], replyTo: 'a'),
        _e(id: 'o', at: DateTime(2026, 6, 8, 14), tags: ['일']), // other tag
      ], '여행');
      expect(r, 2); // 오후
    });

    test('ties resolve to the earlier bucket (새벽 first)', () {
      final r = busiestDayPartWithTag([
        _e(id: 'a', at: DateTime(2026, 6, 13, 3), tags: ['여행']), // 새벽=0
        _e(id: 'b', at: DateTime(2026, 6, 8, 20), tags: ['여행']), // 저녁=3
      ], '여행');
      expect(r, 0); // 새벽
    });

    test('null when the tag has no top-level records', () {
      expect(busiestDayPartWithTag(const [], '여행'), isNull);
      expect(
          busiestDayPartWithTag(
              [_e(id: 'a', at: DateTime(2026, 6, 8, 9), tags: ['일'])], '여행'),
          isNull);
      expect(
        busiestDayPartWithTag([
          _e(id: 'r', at: DateTime(2026, 6, 8, 9), tags: ['여행'], replyTo: 'x'),
        ], '여행'),
        isNull,
      );
    });
  });

  group('placesWithTag', () {
    test('counts places for the tag by frequency, replies & other tag excluded',
        () {
      final r = placesWithTag([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'], location: '제주'),
        _e(id: 'b', at: DateTime(2026, 6, 2), tags: ['여행'], location: '제주'),
        _e(id: 'c', at: DateTime(2026, 6, 3), tags: ['여행'], location: '서울'),
        _e(id: 'd', at: DateTime(2026, 6, 4), tags: ['여행'], location: '  '),
        _e(
            id: 'r',
            at: DateTime(2026, 6, 5),
            tags: ['여행'],
            location: '제주',
            replyTo: 'a'), // reply
        _e(id: 'o', at: DateTime(2026, 6, 6), tags: ['일'], location: '부산'),
      ], '여행');
      expect(r, ['제주', '서울']);
    });

    test('ties resolve alphabetically and respect the limit', () {
      final r = placesWithTag([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'], location: '다'),
        _e(id: 'b', at: DateTime(2026, 6, 2), tags: ['여행'], location: '나'),
        _e(id: 'c', at: DateTime(2026, 6, 3), tags: ['여행'], location: '가'),
      ], '여행', limit: 2);
      expect(r, ['가', '나']);
    });

    test('empty when no matching record carries a place', () {
      expect(
          placesWithTag(
              [_e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'])], '여행'),
          isEmpty);
      expect(
          placesWithTag([
            _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['일'], location: '제주'),
          ], '여행'),
          isEmpty);
    });
  });

  group('longestEntryWithTag', () {
    test('picks the tag record with the longest body, replies & other tag excluded',
        () {
      final r = longestEntryWithTag([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'], content: 'abc'),
        _e(id: 'b', at: DateTime(2026, 6, 2), tags: ['여행'], content: 'abcdefg'),
        _e(
            id: 'r',
            at: DateTime(2026, 6, 3),
            tags: ['여행'],
            content: 'abcdefghijk',
            replyTo: 'a'), // reply, longer but excluded
        _e(id: 'o', at: DateTime(2026, 6, 4), tags: ['일'], content: 'abcdefghij'),
      ], '여행');
      expect(r?.entryId, 'b');
    });

    test('ties resolve to the most recent record', () {
      final r = longestEntryWithTag([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'], content: 'abc'),
        _e(id: 'b', at: DateTime(2026, 6, 5), tags: ['여행'], content: 'xyz'),
      ], '여행');
      expect(r?.entryId, 'b');
    });

    test('null when the tag has no top-level record with text', () {
      expect(longestEntryWithTag([], '여행'), isNull);
      expect(
          longestEntryWithTag(
              [_e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'], content: '  ')],
              '여행'),
          isNull);
      expect(
          longestEntryWithTag(
              [_e(id: 'a', at: DateTime(2026, 6, 1), tags: ['일'], content: 'abc')],
              '여행'),
          isNull);
    });
  });
}
