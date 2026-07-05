import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';
import 'package:lifelog/features/review/day_entries.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _e({
  required String id,
  required DateTime at,
  String? replyTo,
  Mood? mood,
  String? title,
  String content = 'x',
  List<String> tags = const [],
  String? place,
  bool favorite = false,
  String journal = 'j1',
  String? pageCanvas,
  List<String> mediaUrls = const [],
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: journal,
      replyToEntryId: replyTo,
      title: title,
      content: content,
      mood: mood,
      tags: tags,
      location: place,
      isFavorite: favorite,
      createdAt: at,
      updatedAt: at,
      pageCanvas: pageCanvas,
      mediaUrls: mediaUrls,
    );

void main() {
  final entries = [
    _e(id: '1', at: DateTime(2026, 6, 12, 9)),
    _e(id: '2', at: DateTime(2026, 6, 12, 21)), // later same day
    _e(id: '3', at: DateTime(2026, 6, 12, 14), replyTo: '1'), // reply excluded
    _e(id: '4', at: DateTime(2026, 6, 13, 8)), // other day
  ];

  test('returns top-level entries of the day, newest first', () {
    final r = entriesOfDay(entries, DateTime(2026, 6, 12));
    expect(r.map((e) => e.entryId), ['2', '1']);
  });

  test('time component of the query day is ignored', () {
    final r = entriesOfDay(entries, DateTime(2026, 6, 12, 23, 59));
    expect(r.length, 2);
  });

  test('empty when no entries on that day', () {
    expect(entriesOfDay(entries, DateTime(2026, 6, 1)), isEmpty);
  });

  group('dayShareText', () {
    test('placeholder when there are no records', () {
      final t = dayShareText(const [], '6월 13일 (토)');
      expect(t, contains('이 날의 기록이 없어요'));
      expect(t, endsWith('— lifelog'));
    });

    test('includes header count, mood, title, content and tags', () {
      final t = dayShareText([
        _e(
          id: '1',
          at: DateTime(2026, 6, 13),
          mood: Mood.good,
          title: '제주',
          content: '바닷가',
          tags: ['추억', '가족'],
        ),
      ], '6월 13일 (토)');
      expect(t, startsWith('📔 6월 13일 (토) · 기록 1개'));
      expect(t, contains('😊 제주'));
      expect(t, contains('바닷가'));
      expect(t, contains('#추억 #가족'));
      expect(t, endsWith('— lifelog'));
    });

    test('omits missing pieces gracefully', () {
      final t = dayShareText([
        _e(id: '1', at: DateTime(2026, 6, 13), content: '메모만'),
      ], '6월 13일 (토)');
      expect(t, contains('메모만'));
      expect(t, isNot(contains('#')));
    });

    test('records are separated by a blank line', () {
      final t = dayShareText([
        _e(id: '1', at: DateTime(2026, 6, 13), content: 'a'),
        _e(id: '2', at: DateTime(2026, 6, 13), content: 'b'),
      ], '6월 13일 (토)');
      expect(t, contains('a\n\nb'));
    });

    test('meta line shows the day time span and places', () {
      final t = dayShareText([
        _e(id: '1', at: DateTime(2026, 6, 13, 9), place: '제주', content: 'a'),
        _e(id: '2', at: DateTime(2026, 6, 13, 21), place: '서울', content: 'b'),
      ], '6월 13일 (토)');
      expect(t, contains('🕘 09:00–21:00'));
      expect(t, contains('📍 제주 · 서울'));
    });

    test('single record meta shows one time and omits place when absent', () {
      final t = dayShareText([
        _e(id: '1', at: DateTime(2026, 6, 13, 8, 5), content: 'hi'),
      ], '6월 13일 (토)');
      expect(t, contains('🕘 08:05'));
      expect(t, isNot(contains('📍')));
    });
  });

  group('adjacentRecordedDays', () {
    final entries = [
      _e(id: '1', at: DateTime(2026, 6, 10, 9)),
      _e(id: '2', at: DateTime(2026, 6, 10, 20)), // same day, dedup
      _e(id: '3', at: DateTime(2026, 6, 13, 8)),
      _e(id: '4', at: DateTime(2026, 6, 18, 8)),
      _e(id: '5', at: DateTime(2026, 6, 20, 8), replyTo: '4'), // reply ignored
    ];

    test('returns nearest recorded days around the query day', () {
      final a = adjacentRecordedDays(entries, DateTime(2026, 6, 13));
      expect(a.previous, DateTime(2026, 6, 10));
      expect(a.next, DateTime(2026, 6, 18));
    });

    test('null previous before the first recorded day', () {
      final a = adjacentRecordedDays(entries, DateTime(2026, 6, 10));
      expect(a.previous, isNull);
      expect(a.next, DateTime(2026, 6, 13));
    });

    test('null next after the last recorded day', () {
      final a = adjacentRecordedDays(entries, DateTime(2026, 6, 18));
      expect(a.previous, DateTime(2026, 6, 13));
      expect(a.next, isNull);
    });

    test('works from a day with no records of its own', () {
      final a = adjacentRecordedDays(entries, DateTime(2026, 6, 15));
      expect(a.previous, DateTime(2026, 6, 13));
      expect(a.next, DateTime(2026, 6, 18));
    });

    test('replies do not create recorded days', () {
      // 6/20 is only a reply, so the next after 6/18 is null, not 6/20.
      expect(adjacentRecordedDays(entries, DateTime(2026, 6, 18)).next, isNull);
      expect(recordedDaysSorted(entries), [
        DateTime(2026, 6, 10),
        DateTime(2026, 6, 13),
        DateTime(2026, 6, 18),
      ]);
    });
  });

  group('dominantMoodOf', () {
    test('returns the most-recorded mood', () {
      final m = dominantMoodOf([
        _e(id: '1', at: DateTime(2026, 6, 1), mood: Mood.good),
        _e(id: '2', at: DateTime(2026, 6, 1), mood: Mood.good),
        _e(id: '3', at: DateTime(2026, 6, 1), mood: Mood.hard),
      ]);
      expect(m, Mood.good);
    });

    test('ties resolve to the earlier mood in enum order', () {
      final m = dominantMoodOf([
        _e(id: '1', at: DateTime(2026, 6, 1), mood: Mood.hard),
        _e(id: '2', at: DateTime(2026, 6, 1), mood: Mood.good),
      ]);
      expect(m, Mood.good);
    });

    test('ignores moodless records', () {
      final m = dominantMoodOf([
        _e(id: '1', at: DateTime(2026, 6, 1), mood: Mood.neutral),
        _e(id: '2', at: DateTime(2026, 6, 1)),
      ]);
      expect(m, Mood.neutral);
    });

    test('null when nothing carries a mood', () {
      expect(dominantMoodOf([_e(id: '1', at: DateTime(2026, 6, 1))]), isNull);
      expect(dominantMoodOf(const []), isNull);
    });
  });

  group('placesOfDay', () {
    test('distinct places ordered by frequency, ties keep first-seen', () {
      final r = placesOfDay([
        _e(id: '1', at: DateTime(2026, 6, 1), place: '서울'),
        _e(id: '2', at: DateTime(2026, 6, 1), place: '제주'),
        _e(id: '3', at: DateTime(2026, 6, 1), place: '제주'),
      ]);
      // 제주 x2, then 서울 x1
      expect(r, ['제주', '서울']);
    });

    test('trims and ignores blank or missing locations', () {
      final r = placesOfDay([
        _e(id: '1', at: DateTime(2026, 6, 1), place: '  부산  '),
        _e(id: '2', at: DateTime(2026, 6, 1), place: '   '),
        _e(id: '3', at: DateTime(2026, 6, 1)),
      ]);
      expect(r, ['부산']);
    });

    test('empty list is empty', () {
      expect(placesOfDay(const []), isEmpty);
    });
  });

  group('dayTimeSpan', () {
    test('earliest and latest regardless of list order', () {
      final s = dayTimeSpan([
        _e(id: '1', at: DateTime(2026, 6, 12, 21)),
        _e(id: '2', at: DateTime(2026, 6, 12, 9)),
        _e(id: '3', at: DateTime(2026, 6, 12, 14)),
      ]);
      expect(s!.first, DateTime(2026, 6, 12, 9));
      expect(s.last, DateTime(2026, 6, 12, 21));
    });

    test('single record spans a single instant', () {
      final s = dayTimeSpan([_e(id: '1', at: DateTime(2026, 6, 12, 8, 30))]);
      expect(s!.first, DateTime(2026, 6, 12, 8, 30));
      expect(s.first, s.last);
    });

    test('null when empty', () {
      expect(dayTimeSpan(const []), isNull);
    });
  });

  group('tagsOfDay', () {
    test('distinct tags ordered by frequency, ties keep first-seen', () {
      final r = tagsOfDay([
        _e(id: '1', at: DateTime(2026, 6, 1), tags: ['가족', '추억']),
        _e(id: '2', at: DateTime(2026, 6, 1), tags: ['추억', '여행']),
        _e(id: '3', at: DateTime(2026, 6, 1), tags: ['추억']),
      ]);
      // 추억 x3, then 가족 & 여행 tie at 1 -> first-seen order (가족 before 여행)
      expect(r, ['추억', '가족', '여행']);
    });

    test('empty when no record carries a tag', () {
      final r = tagsOfDay([
        _e(id: '1', at: DateTime(2026, 6, 1)),
        _e(id: '2', at: DateTime(2026, 6, 1)),
      ]);
      expect(r, isEmpty);
    });

    test('empty list is empty', () {
      expect(tagsOfDay(const []), isEmpty);
    });
  });

  group('totalContentChars', () {
    test('sums grapheme-aware trimmed length across records', () {
      final n = totalContentChars([
        _e(id: '1', at: DateTime(2026, 6, 1), content: '  안녕  '), // 2
        _e(id: '2', at: DateTime(2026, 6, 1), content: 'Diary😊'), // 6
      ]);
      expect(n, 8);
    });

    test('blank or empty content contributes 0', () {
      final n = totalContentChars([
        _e(id: '1', at: DateTime(2026, 6, 1), content: '   '),
        _e(id: '2', at: DateTime(2026, 6, 1), content: ''),
      ]);
      expect(n, 0);
    });

    test('empty list is 0', () {
      expect(totalContentChars(const []), 0);
    });
  });

  group('averageCharsOfDay', () {
    test('rounds the mean grapheme length per record', () {
      // (2 + 6) / 2 = 4
      final n = averageCharsOfDay([
        _e(id: '1', at: DateTime(2026, 6, 1), content: '  안녕  '), // 2
        _e(id: '2', at: DateTime(2026, 6, 1), content: 'Diary😊'), // 6
      ]);
      expect(n, 4);
    });

    test('rounds a fractional mean to nearest whole', () {
      // (3 + 6) / 2 = 4.5 -> 5
      final n = averageCharsOfDay([
        _e(id: '1', at: DateTime(2026, 6, 1), content: 'abc'), // 3
        _e(id: '2', at: DateTime(2026, 6, 1), content: 'abcdef'), // 6
      ]);
      expect(n, 5);
    });

    test('zero for an empty list', () {
      expect(averageCharsOfDay(const []), 0);
    });
  });

  group('favoriteCountOfDay', () {
    test('counts the favorited records', () {
      final n = favoriteCountOfDay([
        _e(id: '1', at: DateTime(2026, 6, 1), favorite: true),
        _e(id: '2', at: DateTime(2026, 6, 1)), // not favorite
        _e(id: '3', at: DateTime(2026, 6, 1), favorite: true),
      ]);
      expect(n, 2);
    });

    test('zero when none are favorited or list is empty', () {
      expect(
          favoriteCountOfDay([_e(id: '1', at: DateTime(2026, 6, 1))]), 0);
      expect(favoriteCountOfDay(const []), 0);
    });
  });

  group('decoratedCountOfDay', () {
    test('counts records with a decorated page canvas', () {
      final n = decoratedCountOfDay([
        _e(
          id: '1',
          at: DateTime(2026, 6, 1),
          pageCanvas: encodePageCanvas(const PageCanvas(paper: PaperStyle.grid)),
        ),
        _e(id: '2', at: DateTime(2026, 6, 1)), // no canvas at all
        _e(
          id: '3',
          at: DateTime(2026, 6, 1),
          pageCanvas: encodePageCanvas(const PageCanvas()), // stored but plain
        ),
      ]);
      expect(n, 1);
    });

    test('malformed pageCanvas JSON never throws, counts as not decorated', () {
      final n = decoratedCountOfDay([
        _e(id: '1', at: DateTime(2026, 6, 1), pageCanvas: 'not json'),
      ]);
      expect(n, 0);
    });

    test('zero when none are decorated or list is empty', () {
      expect(decoratedCountOfDay([_e(id: '1', at: DateTime(2026, 6, 1))]), 0);
      expect(decoratedCountOfDay(const []), 0);
    });
  });

  group('photoCountOfDay', () {
    test('counts records with at least one attached photo', () {
      final n = photoCountOfDay([
        _e(id: '1', at: DateTime(2026, 6, 1), mediaUrls: const ['a.jpg']),
        _e(id: '2', at: DateTime(2026, 6, 1)), // no photos
        _e(
          id: '3',
          at: DateTime(2026, 6, 1),
          mediaUrls: const ['b.jpg', 'c.jpg'],
        ),
      ]);
      expect(n, 2);
    });

    test('zero when none carry photos or list is empty', () {
      expect(photoCountOfDay([_e(id: '1', at: DateTime(2026, 6, 1))]), 0);
      expect(photoCountOfDay(const []), 0);
    });
  });

  group('journalIdsOfDay', () {
    test('distinct journal ids in first-seen order', () {
      final r = journalIdsOfDay([
        _e(id: '1', at: DateTime(2026, 6, 1), journal: 'a'),
        _e(id: '2', at: DateTime(2026, 6, 1), journal: 'b'),
        _e(id: '3', at: DateTime(2026, 6, 1), journal: 'a'), // dedup
      ]);
      expect(r, ['a', 'b']);
    });

    test('single journal yields one id', () {
      final r = journalIdsOfDay([
        _e(id: '1', at: DateTime(2026, 6, 1)),
        _e(id: '2', at: DateTime(2026, 6, 1)),
      ]);
      expect(r, ['j1']);
    });

    test('empty list is empty', () {
      expect(journalIdsOfDay(const []), isEmpty);
    });
  });

  group('longestEntryOfDay', () {
    test('picks the record with the longest body, replies excluded', () {
      final r = longestEntryOfDay([
        _e(id: '1', at: DateTime(2026, 6, 1), content: 'abc'),
        _e(id: '2', at: DateTime(2026, 6, 1, 1), content: 'abcdefg'),
        _e(id: '3', at: DateTime(2026, 6, 1, 2), content: 'abcdefghijk', replyTo: '1'), // reply, longer but excluded
      ]);
      expect(r?.entryId, '2');
    });

    test('ties resolve to the most recent record', () {
      final r = longestEntryOfDay([
        _e(id: '1', at: DateTime(2026, 6, 1), content: 'abc'),
        _e(id: '2', at: DateTime(2026, 6, 1, 5), content: 'xyz'),
      ]);
      expect(r?.entryId, '2');
    });

    test('null when nothing carries text or list is empty', () {
      expect(longestEntryOfDay(const []), isNull);
      expect(
          longestEntryOfDay([_e(id: '1', at: DateTime(2026, 6, 1), content: '  ')]),
          isNull);
    });
  });
}
