import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/features/decorate/page_canvas.dart';
import 'package:lifelog/features/stats/mood_entries.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _entry(
  String id, {
  Mood? mood,
  String? replyTo,
  DateTime? created,
  List<String> tags = const [],
  String? location,
  String? title,
  String? content,
  bool favorite = false,
  String journal = 'jr_default',
  String? pageCanvas,
  List<String> mediaUrls = const [],
}) {
  final ts = created ?? DateTime(2026, 6, 1);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: journal,
    replyToEntryId: replyTo,
    title: title,
    content: content ?? id,
    mood: mood,
    tags: tags,
    location: location,
    isFavorite: favorite,
    createdAt: ts,
    updatedAt: ts,
    pageCanvas: pageCanvas,
    mediaUrls: mediaUrls,
  );
}

void main() {
  group('moodFromName', () {
    test('resolves each stable name', () {
      expect(moodFromName('good'), Mood.good);
      expect(moodFromName('neutral'), Mood.neutral);
      expect(moodFromName('hard'), Mood.hard);
    });

    test('unknown or blank yields null', () {
      expect(moodFromName(''), isNull);
      expect(moodFromName('😊'), isNull);
      expect(moodFromName('great'), isNull);
    });
  });

  group('moodCountsSorted', () {
    test('counts top-level entries per mood, most-recorded first', () {
      final entries = [
        _entry('a', mood: Mood.good),
        _entry('b', mood: Mood.good),
        _entry('c', mood: Mood.hard),
        _entry('d', mood: Mood.good),
        _entry('e', mood: Mood.hard),
      ];
      final result = moodCountsSorted(entries);
      expect(result.map((e) => e.key), [Mood.good, Mood.hard]);
      expect(result.map((e) => e.value), [3, 2]);
    });

    test('excludes replies and moodless entries', () {
      final entries = [
        _entry('a', mood: Mood.good),
        _entry('b'), // no mood
        _entry('c', mood: Mood.hard, replyTo: 'a'), // reply excluded
      ];
      final result = moodCountsSorted(entries);
      expect(result.map((e) => e.key), [Mood.good]);
      expect(result.single.value, 1);
    });

    test('ties resolve to earlier Mood.values order', () {
      final entries = [
        _entry('a', mood: Mood.hard),
        _entry('b', mood: Mood.neutral),
        _entry('c', mood: Mood.good),
      ];
      // all tied at 1 → good, neutral, hard
      expect(
        moodCountsSorted(entries).map((e) => e.key),
        [Mood.good, Mood.neutral, Mood.hard],
      );
    });

    test('empty when nothing recorded', () {
      expect(moodCountsSorted([_entry('a')]), isEmpty);
      expect(moodCountsSorted(const []), isEmpty);
    });
  });

  group('lastUseByMood', () {
    test('keeps the most recent created date per mood', () {
      final entries = [
        _entry('a', mood: Mood.good, created: DateTime(2026, 1, 1)),
        _entry('b', mood: Mood.good, created: DateTime(2026, 6, 1)),
        _entry('c', mood: Mood.hard, created: DateTime(2026, 3, 1)),
      ];
      final last = lastUseByMood(entries);
      expect(last[Mood.good], DateTime(2026, 6, 1));
      expect(last[Mood.hard], DateTime(2026, 3, 1));
    });

    test('excludes replies and moodless entries', () {
      final entries = [
        _entry('a', mood: Mood.good, created: DateTime(2026, 1, 1)),
        _entry('b', created: DateTime(2026, 6, 1)), // no mood
        _entry('c', mood: Mood.good, replyTo: 'a', created: DateTime(2026, 6, 1)),
      ];
      final last = lastUseByMood(entries);
      expect(last[Mood.good], DateTime(2026, 1, 1));
      expect(last.length, 1);
    });

    test('empty when nothing recorded', () {
      expect(lastUseByMood(const []), isEmpty);
    });
  });

  group('moodSharePercent', () {
    test('rounds each mood share of the mood-carrying records', () {
      final entries = [
        _entry('a', mood: Mood.good),
        _entry('b', mood: Mood.good),
        _entry('c', mood: Mood.good),
        _entry('d', mood: Mood.hard),
      ];
      expect(moodSharePercent(entries, Mood.good), 75); // 3/4
      expect(moodSharePercent(entries, Mood.hard), 25); // 1/4
    });

    test('excludes replies and moodless entries from the denominator', () {
      final entries = [
        _entry('a', mood: Mood.good),
        _entry('b'), // no mood — ignored
        _entry('c', mood: Mood.hard, replyTo: 'a'), // reply — ignored
      ];
      expect(moodSharePercent(entries, Mood.good), 100); // only 'a' counts
      expect(moodSharePercent(entries, Mood.hard), 0);
    });

    test('zero when nothing carries a mood', () {
      expect(moodSharePercent(const [], Mood.good), 0);
      expect(moodSharePercent([_entry('a')], Mood.good), 0);
    });
  });

  group('entriesWithMood', () {
    test('keeps only top-level entries of the given mood', () {
      final entries = [
        _entry('a', mood: Mood.good),
        _entry('b', mood: Mood.hard),
        _entry('c', mood: Mood.good),
        _entry('d'), // no mood
        _entry('e', mood: Mood.good, replyTo: 'a'), // reply excluded
      ];
      final good = entriesWithMood(entries, Mood.good);
      expect(good.map((e) => e.entryId), ['a', 'c']);
    });

    test('returns newest first', () {
      final entries = [
        _entry('old', mood: Mood.good, created: DateTime(2026, 1, 1)),
        _entry('new', mood: Mood.good, created: DateTime(2026, 6, 1)),
        _entry('mid', mood: Mood.good, created: DateTime(2026, 3, 1)),
      ];
      expect(
        entriesWithMood(entries, Mood.good).map((e) => e.entryId),
        ['new', 'mid', 'old'],
      );
    });

    test('empty when no entry matches', () {
      final entries = [_entry('a', mood: Mood.good)];
      expect(entriesWithMood(entries, Mood.hard), isEmpty);
    });
  });

  group('moodDateSpan', () {
    test('earliest and latest date-only, replies & other moods excluded', () {
      final s = moodDateSpan([
        _entry('a', mood: Mood.good, created: DateTime(2026, 6, 10, 23, 59)),
        _entry('b', mood: Mood.good, created: DateTime(2026, 6, 20, 1, 0)),
        _entry('r',
            mood: Mood.good, replyTo: 'a', created: DateTime(2026, 6, 25)),
        _entry('h', mood: Mood.hard, created: DateTime(2026, 6, 5)),
      ], Mood.good);
      expect(s!.first, DateTime(2026, 6, 10));
      expect(s.last, DateTime(2026, 6, 20));
    });

    test('single record spans that one date', () {
      final s = moodDateSpan(
          [_entry('a', mood: Mood.good, created: DateTime(2026, 6, 13))],
          Mood.good);
      expect(s!.first, DateTime(2026, 6, 13));
      expect(s.first, s.last);
    });

    test('null when the mood has no top-level records', () {
      expect(
          moodDateSpan([_entry('a', mood: Mood.good)], Mood.hard), isNull);
      expect(
        moodDateSpan([
          _entry('r', mood: Mood.good, replyTo: 'x'),
        ], Mood.good),
        isNull,
      );
    });
  });

  group('tagsWithMood', () {
    test('counts tags for the mood by frequency, replies & other mood excluded',
        () {
      final r = tagsWithMood([
        _entry('a', mood: Mood.good, tags: ['여행', '가족']),
        _entry('b', mood: Mood.good, tags: ['여행']),
        _entry('r', mood: Mood.good, tags: ['여행'], replyTo: 'a'), // reply
        _entry('h', mood: Mood.hard, tags: ['일']), // other mood
      ], Mood.good);
      expect(r.map((e) => e.key).toList(), ['여행', '가족']);
      expect(r.first.value, 2);
    });

    test('ties resolve alphabetically and respect the limit', () {
      final r = tagsWithMood([
        _entry('a', mood: Mood.good, tags: ['다', '나', '가']),
      ], Mood.good, limit: 2);
      expect(r.map((e) => e.key).toList(), ['가', '나']);
    });

    test('empty when no matching record carries a tag', () {
      expect(tagsWithMood([_entry('a', mood: Mood.good)], Mood.good), isEmpty);
      expect(
          tagsWithMood([_entry('a', mood: Mood.hard, tags: ['x'])], Mood.good),
          isEmpty);
    });
  });

  group('dominantTagByMood', () {
    test('picks the most-used tag per mood, replies excluded', () {
      final map = dominantTagByMood([
        _entry('a', mood: Mood.good, tags: ['여행', '가족']),
        _entry('b', mood: Mood.good, tags: ['여행']),
        _entry('r', mood: Mood.good, tags: ['가족', '가족'], replyTo: 'a'),
        _entry('h', mood: Mood.hard, tags: ['일']),
      ]);
      expect(map[Mood.good], '여행'); // 여행 2 > 가족 1 (reply ignored)
      expect(map[Mood.hard], '일');
    });

    test('ties resolve alphabetically', () {
      final map = dominantTagByMood([
        _entry('a', mood: Mood.good, tags: ['나', '가']),
      ]);
      expect(map[Mood.good], '가');
    });

    test('omits moods with no tagged record', () {
      expect(dominantTagByMood([_entry('a', mood: Mood.good)]), isEmpty);
      expect(
          dominantTagByMood([_entry('a', tags: ['여행'])]), isEmpty); // moodless
    });
  });

  group('placesWithMood', () {
    test('counts places for the mood, replies & other mood & blanks excluded',
        () {
      final r = placesWithMood([
        _entry('a', mood: Mood.good, location: '제주'),
        _entry('b', mood: Mood.good, location: '제주'),
        _entry('c', mood: Mood.good, location: '서울'),
        _entry('d', mood: Mood.good, location: '  '), // blank ignored
        _entry('r', mood: Mood.good, location: '제주', replyTo: 'a'), // reply
        _entry('h', mood: Mood.hard, location: '부산'), // other mood
      ], Mood.good);
      expect(r, ['제주', '서울']);
    });

    test('ties resolve alphabetically and respect the limit', () {
      final r = placesWithMood([
        _entry('a', mood: Mood.good, location: '다'),
        _entry('b', mood: Mood.good, location: '나'),
        _entry('c', mood: Mood.good, location: '가'),
      ], Mood.good, limit: 2);
      expect(r, ['가', '나']);
    });

    test('empty when no matching record carries a place', () {
      expect(placesWithMood([_entry('a', mood: Mood.good)], Mood.good), isEmpty);
      expect(
          placesWithMood(
              [_entry('a', mood: Mood.hard, location: '제주')], Mood.good),
          isEmpty);
    });
  });

  group('averageCharsWithMood', () {
    test('rounds the mean grapheme length, replies & other moods excluded', () {
      final r = averageCharsWithMood([
        _entry('a', mood: Mood.good, content: '가나다'), // 3
        _entry('b', mood: Mood.good, content: '  Diary😊  '), // trims → 6
        _entry('r', mood: Mood.good, content: '길다길다길다', replyTo: 'a'), // reply
        _entry('h', mood: Mood.hard, content: '아주아주긴글'), // other mood
      ], Mood.good);
      expect(r, 5); // (3 + 6) / 2 = 4.5 → 5
    });

    test('single record yields its own length', () {
      expect(
        averageCharsWithMood(
            [_entry('a', mood: Mood.good, content: '안녕😊')], Mood.good),
        3,
      );
    });

    test('zero when the mood has no top-level records', () {
      expect(averageCharsWithMood(const [], Mood.good), 0);
      expect(
          averageCharsWithMood([_entry('a', mood: Mood.hard)], Mood.good), 0);
      expect(
        averageCharsWithMood(
            [_entry('r', mood: Mood.good, replyTo: 'x')], Mood.good),
        0,
      );
    });
  });

  group('favoriteCountWithMood', () {
    test('counts favorited records, replies & other moods excluded', () {
      final n = favoriteCountWithMood([
        _entry('a', mood: Mood.good, favorite: true),
        _entry('b', mood: Mood.good, favorite: true),
        _entry('c', mood: Mood.good), // not favorite
        _entry('r', mood: Mood.good, favorite: true, replyTo: 'a'), // reply
        _entry('h', mood: Mood.hard, favorite: true), // other mood
      ], Mood.good);
      expect(n, 2);
    });

    test('zero when none favorited, mood absent, or list empty', () {
      expect(favoriteCountWithMood(const [], Mood.good), 0);
      expect(favoriteCountWithMood([_entry('a', mood: Mood.good)], Mood.good), 0);
      expect(
          favoriteCountWithMood(
              [_entry('a', mood: Mood.hard, favorite: true)], Mood.good),
          0);
    });
  });

  group('decoratedCountWithMood', () {
    test('counts decorated top-level records with the mood, replies excluded',
        () {
      final n = decoratedCountWithMood([
        _entry('a', mood: Mood.good,
            pageCanvas: encodePageCanvas(const PageCanvas(paper: PaperStyle.grid))),
        _entry('b', mood: Mood.good), // no canvas
        _entry('c', mood: Mood.good,
            pageCanvas: encodePageCanvas(const PageCanvas())), // stored but plain
        _entry('r', mood: Mood.good, replyTo: 'a',
            pageCanvas: encodePageCanvas(const PageCanvas(paper: PaperStyle.dotted))), // reply
        _entry('h', mood: Mood.hard,
            pageCanvas: encodePageCanvas(const PageCanvas(paper: PaperStyle.lined))), // other mood
      ], Mood.good);
      expect(n, 1);
    });

    test('malformed pageCanvas JSON never throws, counts as not decorated', () {
      final n = decoratedCountWithMood(
          [_entry('a', mood: Mood.good, pageCanvas: 'not json')], Mood.good);
      expect(n, 0);
    });

    test('zero when none decorated, mood absent, or list empty', () {
      expect(decoratedCountWithMood(const [], Mood.good), 0);
      expect(decoratedCountWithMood([_entry('a', mood: Mood.good)], Mood.good), 0);
      expect(
          decoratedCountWithMood(
              [
                _entry('a', mood: Mood.hard,
                    pageCanvas: encodePageCanvas(const PageCanvas(paper: PaperStyle.grid)))
              ],
              Mood.good),
          0);
    });
  });

  group('photoCountWithMood', () {
    test('counts top-level records with a photo for the mood, replies & other mood excluded',
        () {
      final n = photoCountWithMood([
        _entry('a', mood: Mood.good, mediaUrls: const ['a.jpg']),
        _entry('b', mood: Mood.good), // no photo
        _entry('c', mood: Mood.good, mediaUrls: const ['b.jpg', 'c.jpg']),
        _entry('r',
            mood: Mood.good,
            replyTo: 'a',
            mediaUrls: const ['d.jpg']), // reply
        _entry('h', mood: Mood.hard, mediaUrls: const ['e.jpg']), // other mood
      ], Mood.good);
      expect(n, 2);
    });

    test('zero when none carry photos, mood absent, or list empty', () {
      expect(photoCountWithMood(const [], Mood.good), 0);
      expect(photoCountWithMood([_entry('a', mood: Mood.good)], Mood.good), 0);
      expect(
          photoCountWithMood(
              [_entry('a', mood: Mood.hard, mediaUrls: const ['a.jpg'])],
              Mood.good),
          0);
    });
  });

  group('titledCountWithMood', () {
    test('counts top-level records with a title for the mood, replies & other mood & blank excluded',
        () {
      final n = titledCountWithMood([
        _entry('a', mood: Mood.good, title: '제주'),
        _entry('b', mood: Mood.good), // no title
        _entry('c', mood: Mood.good, title: '   '), // blank title
        _entry('r', mood: Mood.good, replyTo: 'a', title: '답장'), // reply
        _entry('h', mood: Mood.hard, title: '회사'), // other mood
      ], Mood.good);
      expect(n, 1);
    });

    test('zero when none carry a title, mood absent, or list empty', () {
      expect(titledCountWithMood(const [], Mood.good), 0);
      expect(titledCountWithMood([_entry('a', mood: Mood.good)], Mood.good), 0);
      expect(
          titledCountWithMood(
              [_entry('a', mood: Mood.hard, title: '제주')], Mood.good),
          0);
    });
  });

  group('busiestWeekdayWithMood', () {
    test('picks the weekday with the most records, replies & other mood excluded',
        () {
      final entries = [
        _entry('a', mood: Mood.good, created: DateTime(2026, 6, 13)), // Sat
        _entry('b', mood: Mood.good, created: DateTime(2026, 6, 20)), // Sat
        _entry('c', mood: Mood.good, created: DateTime(2026, 6, 8)), // Mon
        _entry('r',
            mood: Mood.good, replyTo: 'a', created: DateTime(2026, 6, 8)), // reply
        _entry('h', mood: Mood.hard, created: DateTime(2026, 6, 8)), // other mood
      ];
      expect(busiestWeekdayWithMood(entries, Mood.good), DateTime.saturday);
    });

    test('ties resolve to the earlier weekday (Mon first)', () {
      final entries = [
        _entry('a', mood: Mood.good, created: DateTime(2026, 6, 13)), // Sat
        _entry('b', mood: Mood.good, created: DateTime(2026, 6, 8)), // Mon
      ];
      expect(busiestWeekdayWithMood(entries, Mood.good), DateTime.monday);
    });

    test('null when the mood has no top-level records', () {
      expect(busiestWeekdayWithMood(const [], Mood.good), isNull);
      expect(
          busiestWeekdayWithMood([_entry('a', mood: Mood.hard)], Mood.good),
          isNull);
      expect(
        busiestWeekdayWithMood(
            [_entry('r', mood: Mood.good, replyTo: 'x')], Mood.good),
        isNull,
      );
    });
  });

  group('busiestDayPartWithMood', () {
    test('picks the busiest time bucket, replies & other mood excluded', () {
      final entries = [
        _entry('a',
            mood: Mood.good, created: DateTime(2026, 6, 13, 14)), // 오후=2
        _entry('b',
            mood: Mood.good, created: DateTime(2026, 6, 20, 17)), // 오후=2
        _entry('c',
            mood: Mood.good, created: DateTime(2026, 6, 8, 9)), // 아침=1
        _entry('r',
            mood: Mood.good,
            replyTo: 'a',
            created: DateTime(2026, 6, 8, 9)), // reply
        _entry('h',
            mood: Mood.hard, created: DateTime(2026, 6, 8, 14)), // other mood
      ];
      expect(busiestDayPartWithMood(entries, Mood.good), 2); // 오후
    });

    test('ties resolve to the earlier bucket (새벽 first)', () {
      final entries = [
        _entry('a', mood: Mood.good, created: DateTime(2026, 6, 13, 3)), // 새벽=0
        _entry('b', mood: Mood.good, created: DateTime(2026, 6, 8, 20)), // 저녁=3
      ];
      expect(busiestDayPartWithMood(entries, Mood.good), 0); // 새벽
    });

    test('null when the mood has no top-level records', () {
      expect(busiestDayPartWithMood(const [], Mood.good), isNull);
      expect(
          busiestDayPartWithMood([_entry('a', mood: Mood.hard)], Mood.good),
          isNull);
      expect(
        busiestDayPartWithMood(
            [_entry('r', mood: Mood.good, replyTo: 'x')], Mood.good),
        isNull,
      );
    });
  });

  group('journalIdsWithMood', () {
    test('distinct journals in first-seen order, replies & other moods excluded',
        () {
      final r = journalIdsWithMood([
        _entry('a', mood: Mood.good, journal: 'j1'),
        _entry('b', mood: Mood.good, journal: 'j2'),
        _entry('c', mood: Mood.good, journal: 'j1'), // dup
        _entry('r', mood: Mood.good, journal: 'j3', replyTo: 'a'), // reply
        _entry('h', mood: Mood.hard, journal: 'j4'), // other mood
      ], Mood.good);
      expect(r, ['j1', 'j2']);
    });

    test('empty when the mood has no top-level records', () {
      expect(journalIdsWithMood(const [], Mood.good), isEmpty);
      expect(
          journalIdsWithMood([_entry('a', mood: Mood.hard)], Mood.good),
          isEmpty);
      expect(
        journalIdsWithMood([_entry('r', mood: Mood.good, replyTo: 'x')],
            Mood.good),
        isEmpty,
      );
    });
  });

  group('longestEntryWithMood', () {
    test(
        'picks the mood record with the longest body, replies & other mood excluded',
        () {
      final r = longestEntryWithMood([
        _entry('a', mood: Mood.good, created: DateTime(2026, 6, 1), content: 'abc'),
        _entry('b', mood: Mood.good, created: DateTime(2026, 6, 2), content: 'abcdefg'),
        _entry('r', mood: Mood.good, created: DateTime(2026, 6, 3), content: 'abcdefghijk', replyTo: 'a'), // reply, longer but excluded
        _entry('o', mood: Mood.hard, created: DateTime(2026, 6, 4), content: 'abcdefghij'),
      ], Mood.good);
      expect(r?.entryId, 'b');
    });

    test('ties resolve to the most recent record', () {
      final r = longestEntryWithMood([
        _entry('a', mood: Mood.good, created: DateTime(2026, 6, 1), content: 'abc'),
        _entry('b', mood: Mood.good, created: DateTime(2026, 6, 5), content: 'xyz'),
      ], Mood.good);
      expect(r?.entryId, 'b');
    });

    test('null when the mood has no top-level record with text', () {
      expect(longestEntryWithMood(const [], Mood.good), isNull);
      expect(
          longestEntryWithMood(
              [_entry('a', mood: Mood.good, content: '  ')], Mood.good),
          isNull);
      expect(
          longestEntryWithMood(
              [_entry('a', mood: Mood.hard, content: 'abc')], Mood.good),
          isNull);
    });
  });

  group('dominantPlaceByMood', () {
    test('picks the most-used location per mood, replies excluded', () {
      final map = dominantPlaceByMood([
        _entry('a', mood: Mood.good, location: '제주'),
        _entry('b', mood: Mood.good, location: '제주'),
        _entry('c', mood: Mood.good, location: '부산'),
        _entry('r', mood: Mood.good, location: '서울', replyTo: 'a'),
        _entry('h', mood: Mood.hard, location: '강릉'),
      ]);
      expect(map[Mood.good], '제주');
      expect(map[Mood.hard], '강릉');
    });

    test('groups locations case-insensitively, keeps first-seen spelling',
        () {
      final map = dominantPlaceByMood([
        _entry('a', mood: Mood.good, location: 'Jeju'),
        _entry('b', mood: Mood.good, location: 'jeju'),
      ]);
      expect(map[Mood.good], 'Jeju');
    });

    test('ties resolve alphabetically', () {
      final map = dominantPlaceByMood([
        _entry('a', mood: Mood.good, location: '제주'),
        _entry('b', mood: Mood.good, location: '부산'),
      ]);
      expect(map[Mood.good], '부산');
    });

    test('omits moods with no located record', () {
      expect(dominantPlaceByMood([_entry('a', mood: Mood.good)]), isEmpty);
      expect(
          dominantPlaceByMood([_entry('a', mood: Mood.good, location: '  ')]),
          isEmpty);
      expect(dominantPlaceByMood([_entry('a', location: '제주')]),
          isEmpty); // moodless
    });
  });
}
