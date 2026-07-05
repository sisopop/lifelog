import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';
import 'package:lifelog/features/places/place_entries.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _entry({
  required String id,
  String? location,
  int day = 10,
  int hour = 0,
  String? replyTo,
  List<String> tags = const [],
  Mood? mood,
  String content = 'c',
  bool favorite = false,
  String journal = 'jr_default',
  String? pageCanvas,
}) {
  final t = DateTime(2026, 6, day, hour);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: journal,
    content: content,
    tags: tags,
    location: location,
    mood: mood,
    isFavorite: favorite,
    replyToEntryId: replyTo,
    createdAt: t,
    updatedAt: t,
    pageCanvas: pageCanvas,
  );
}

void main() {
  test('matches location case-insensitively and trims', () {
    final list = entriesAtLocation([
      _entry(id: 'a', location: '제주'),
      _entry(id: 'b', location: '  제주  '),
      _entry(id: 'c', location: '서울'),
    ], '제주');
    expect(list.map((e) => e.entryId), ['a', 'b']);
  });

  test('newest first', () {
    final list = entriesAtLocation([
      _entry(id: 'old', location: '제주', day: 1),
      _entry(id: 'new', location: '제주', day: 20),
    ], '제주');
    expect(list.first.entryId, 'new');
  });

  test('excludes replies', () {
    final list = entriesAtLocation([
      _entry(id: 'top', location: '제주'),
      _entry(id: 'reply', location: '제주', replyTo: 'top'),
    ], '제주');
    expect(list.map((e) => e.entryId), ['top']);
  });

  test('blank query matches nothing', () {
    final list = entriesAtLocation([_entry(id: 'a', location: '제주')], '  ');
    expect(list, isEmpty);
  });

  test('entries without a location never match', () {
    final list = entriesAtLocation([_entry(id: 'a', location: null)], '제주');
    expect(list, isEmpty);
  });

  group('busiestWeekdayAtLocation', () {
    test('picks the weekday with the most records, case-insensitive & trimmed',
        () {
      final r = busiestWeekdayAtLocation([
        _entry(id: 'a', location: '제주', day: 13), // Sat
        _entry(id: 'b', location: '  제주  ', day: 20), // Sat, trim match
        _entry(id: 'c', location: '제주', day: 8), // Mon
        _entry(id: 'r', location: '제주', day: 8, replyTo: 'a'), // reply
        _entry(id: 'o', location: '서울', day: 8), // other place
      ], '제주');
      expect(r, DateTime.saturday);
    });

    test('ties resolve to the earlier weekday (Mon first)', () {
      final r = busiestWeekdayAtLocation([
        _entry(id: 'a', location: '제주', day: 13), // Sat
        _entry(id: 'b', location: '제주', day: 8), // Mon
      ], '제주');
      expect(r, DateTime.monday);
    });

    test('null for blank query, no match, or no records', () {
      expect(busiestWeekdayAtLocation(const [], '제주'), isNull);
      expect(
          busiestWeekdayAtLocation(
              [_entry(id: 'a', location: '제주', day: 13)], '  '),
          isNull);
      expect(
          busiestWeekdayAtLocation(
              [_entry(id: 'a', location: '서울', day: 13)], '제주'),
          isNull);
    });
  });

  group('busiestDayPartAtLocation', () {
    test('picks the busiest bucket; replies and other places excluded', () {
      final r = busiestDayPartAtLocation([
        _entry(id: 'a', location: '제주', hour: 13), // 오후
        _entry(id: 'b', location: '  제주  ', hour: 15), // 오후, trim match
        _entry(id: 'c', location: '제주', hour: 8), // 아침
        _entry(id: 'r', location: '제주', hour: 14, replyTo: 'a'), // reply
        _entry(id: 'o', location: '서울', hour: 14), // other place
      ], '제주');
      expect(r, 2); // 오후 12–17
    });

    test('tie resolves to the earlier bucket', () {
      final r = busiestDayPartAtLocation([
        _entry(id: 'a', location: '제주', hour: 3), // 새벽
        _entry(id: 'b', location: '제주', hour: 20), // 저녁
      ], '제주');
      expect(r, 0);
    });

    test('null for blank query, no match, or replies only', () {
      expect(busiestDayPartAtLocation(const [], '제주'), isNull);
      expect(
          busiestDayPartAtLocation(
              [_entry(id: 'a', location: '제주', hour: 9)], '  '),
          isNull);
      expect(
          busiestDayPartAtLocation(
              [_entry(id: 'a', location: '서울', hour: 9)], '제주'),
          isNull);
      expect(
          busiestDayPartAtLocation(
              [_entry(id: 'r', location: '제주', hour: 9, replyTo: 'x')], '제주'),
          isNull);
    });
  });

  group('placeDateSpan', () {
    test('earliest and latest date-only, case-insensitive, replies excluded',
        () {
      final s = placeDateSpan([
        _entry(id: 'a', location: '제주', day: 10),
        _entry(id: 'b', location: '  제주  ', day: 20),
        _entry(id: 'r', location: '제주', day: 25, replyTo: 'a'), // reply ignored
        _entry(id: 'c', location: '서울', day: 5), // other place
      ], '제주');
      expect(s!.first, DateTime(2026, 6, 10));
      expect(s.last, DateTime(2026, 6, 20));
    });

    test('single day spans that one date', () {
      final s = placeDateSpan([_entry(id: 'a', location: '제주', day: 13)], '제주');
      expect(s!.first, DateTime(2026, 6, 13));
      expect(s.first, s.last);
    });

    test('null for blank query or no match', () {
      expect(placeDateSpan([_entry(id: 'a', location: '제주')], '  '), isNull);
      expect(placeDateSpan([_entry(id: 'a', location: '서울')], '제주'), isNull);
    });
  });

  group('tagsAtLocation', () {
    test('counts tags at the place by frequency, case-insensitive & trimmed',
        () {
      final r = tagsAtLocation([
        _entry(id: 'a', location: '제주', tags: ['추억', '가족']),
        _entry(id: 'b', location: '  제주  ', tags: ['추억']),
        _entry(id: 'r', location: '제주', tags: ['추억'], replyTo: 'a'), // reply
        _entry(id: 'c', location: '서울', tags: ['일']), // other place
      ], '제주');
      expect(r.map((e) => e.key).toList(), ['추억', '가족']);
      expect(r.first.value, 2);
    });

    test('ties resolve alphabetically and respect the limit', () {
      final r = tagsAtLocation([
        _entry(id: 'a', location: '제주', tags: ['다', '나', '가']),
      ], '제주', limit: 2);
      expect(r.map((e) => e.key).toList(), ['가', '나']);
    });

    test('empty for blank query, no match, or no tags', () {
      expect(tagsAtLocation([_entry(id: 'a', location: '제주')], '  '), isEmpty);
      expect(tagsAtLocation([_entry(id: 'a', location: '서울')], '제주'), isEmpty);
      expect(tagsAtLocation([_entry(id: 'a', location: '제주')], '제주'), isEmpty);
    });
  });

  group('placeMood', () {
    test('most frequent mood, case-insensitive, replies & other place excluded',
        () {
      final m = placeMood([
        _entry(id: 'a', location: '제주', mood: Mood.good),
        _entry(id: 'b', location: '  제주  ', mood: Mood.good),
        _entry(id: 'c', location: '제주', mood: Mood.hard),
        _entry(id: 'r', location: '제주', mood: Mood.hard, replyTo: 'a'),
        _entry(id: 'x', location: '서울', mood: Mood.hard),
      ], '제주');
      expect(m, Mood.good);
    });

    test('ties resolve to the earlier Mood.values entry', () {
      final m = placeMood([
        _entry(id: 'a', location: '제주', mood: Mood.hard),
        _entry(id: 'b', location: '제주', mood: Mood.good),
      ], '제주');
      expect(m, Mood.good); // good precedes hard
    });

    test('null for blank query, no match, or no moods', () {
      expect(placeMood([_entry(id: 'a', location: '제주', mood: Mood.good)], '  '),
          isNull);
      expect(placeMood([_entry(id: 'a', location: '서울', mood: Mood.good)], '제주'),
          isNull);
      expect(placeMood([_entry(id: 'a', location: '제주')], '제주'), isNull);
    });
  });

  group('averageCharsAtLocation', () {
    test('rounds the mean grapheme length, case-insensitive, replies excluded',
        () {
      final r = averageCharsAtLocation([
        _entry(id: 'a', location: '제주', content: '가나다'), // 3
        _entry(id: 'b', location: '  제주  ', content: '  Diary😊  '), // trim → 6
        _entry(id: 'r', location: '제주', content: '길다길다', replyTo: 'a'), // reply
        _entry(id: 'c', location: '서울', content: '아주아주긴글'), // other place
      ], '제주');
      expect(r, 5); // (3 + 6) / 2 = 4.5 → 5
    });

    test('single record yields its own length', () {
      expect(
        averageCharsAtLocation(
            [_entry(id: 'a', location: '제주', content: '안녕😊')], '제주'),
        3,
      );
    });

    test('zero for blank query, no match, or no records', () {
      expect(averageCharsAtLocation(const [], '제주'), 0);
      expect(
          averageCharsAtLocation(
              [_entry(id: 'a', location: '제주', content: 'x')], '  '),
          0);
      expect(
          averageCharsAtLocation(
              [_entry(id: 'a', location: '서울', content: 'x')], '제주'),
          0);
    });
  });

  group('favoriteCountAtLocation', () {
    test('counts favorited records, case-insensitive, replies excluded', () {
      final n = favoriteCountAtLocation([
        _entry(id: 'a', location: '제주', favorite: true),
        _entry(id: 'b', location: '  제주  ', favorite: true), // trim match
        _entry(id: 'c', location: '제주'), // not favorite
        _entry(id: 'r', location: '제주', favorite: true, replyTo: 'a'), // reply
        _entry(id: 'o', location: '서울', favorite: true), // other place
      ], '제주');
      expect(n, 2);
    });

    test('zero for blank query, no match, or none favorited', () {
      expect(favoriteCountAtLocation(const [], '제주'), 0);
      expect(
          favoriteCountAtLocation(
              [_entry(id: 'a', location: '제주', favorite: true)], '  '),
          0);
      expect(
          favoriteCountAtLocation(
              [_entry(id: 'a', location: '서울', favorite: true)], '제주'),
          0);
      expect(
          favoriteCountAtLocation(
              [_entry(id: 'a', location: '제주')], '제주'),
          0);
    });
  });

  group('journalIdsAtLocation', () {
    test('distinct journals in first-seen order, case-insensitive & trimmed',
        () {
      final r = journalIdsAtLocation([
        _entry(id: 'a', location: '제주', journal: 'j1'),
        _entry(id: 'b', location: '  제주  ', journal: 'j2'), // trim match
        _entry(id: 'c', location: '제주', journal: 'j1'), // dup
        _entry(id: 'r', location: '제주', journal: 'j3', replyTo: 'a'), // reply
        _entry(id: 'o', location: '서울', journal: 'j4'), // other place
      ], '제주');
      expect(r, ['j1', 'j2']);
    });

    test('empty for blank query or no match', () {
      expect(journalIdsAtLocation(const [], '제주'), isEmpty);
      expect(journalIdsAtLocation([_entry(id: 'a', location: '제주')], '  '),
          isEmpty);
      expect(journalIdsAtLocation([_entry(id: 'a', location: '서울')], '제주'),
          isEmpty);
    });
  });

  group('decoratedCountAtLocation', () {
    test('counts decorated top-level records at the place, replies excluded',
        () {
      final n = decoratedCountAtLocation([
        _entry(
            id: 'a',
            location: '제주',
            pageCanvas: encodePageCanvas(const PageCanvas(paper: PaperStyle.grid))),
        _entry(id: 'b', location: '  제주  '), // no canvas, trim match
        _entry(
            id: 'c',
            location: '제주',
            pageCanvas: encodePageCanvas(const PageCanvas())), // stored but plain
        _entry(
            id: 'r',
            location: '제주',
            replyTo: 'a',
            pageCanvas:
                encodePageCanvas(const PageCanvas(paper: PaperStyle.dotted))), // reply
        _entry(
            id: 'o',
            location: '서울',
            pageCanvas:
                encodePageCanvas(const PageCanvas(paper: PaperStyle.lined))), // other place
      ], '제주');
      expect(n, 1);
    });

    test('malformed pageCanvas JSON never throws, counts as not decorated', () {
      final n = decoratedCountAtLocation(
          [_entry(id: 'a', location: '제주', pageCanvas: 'not json')], '제주');
      expect(n, 0);
    });

    test('zero for blank query, no match, or none decorated', () {
      expect(decoratedCountAtLocation(const [], '제주'), 0);
      expect(
          decoratedCountAtLocation(
              [
                _entry(
                    id: 'a',
                    location: '제주',
                    pageCanvas:
                        encodePageCanvas(const PageCanvas(paper: PaperStyle.grid)))
              ],
              '  '),
          0);
      expect(
          decoratedCountAtLocation(
              [
                _entry(
                    id: 'a',
                    location: '서울',
                    pageCanvas:
                        encodePageCanvas(const PageCanvas(paper: PaperStyle.grid)))
              ],
              '제주'),
          0);
      expect(decoratedCountAtLocation([_entry(id: 'a', location: '제주')], '제주'),
          0);
    });
  });

  group('longestEntryAtLocation', () {
    test(
        'picks the place record with the longest body, replies & other place excluded',
        () {
      final r = longestEntryAtLocation([
        _entry(id: 'a', location: '제주', day: 1, content: 'abc'),
        _entry(id: 'b', location: '제주', day: 2, content: 'abcdefg'),
        _entry(
            id: 'r',
            location: '제주',
            day: 3,
            content: 'abcdefghijk',
            replyTo: 'a'), // reply, longer but excluded
        _entry(id: 'o', location: '서울', day: 4, content: 'abcdefghij'),
      ], '제주');
      expect(r?.entryId, 'b');
    });

    test('ties resolve to the most recent record', () {
      final r = longestEntryAtLocation([
        _entry(id: 'a', location: '제주', day: 1, content: 'abc'),
        _entry(id: 'b', location: '제주', day: 5, content: 'xyz'),
      ], '제주');
      expect(r?.entryId, 'b');
    });

    test('null when nothing matches or query is blank', () {
      expect(longestEntryAtLocation(const [], '제주'), isNull);
      expect(
          longestEntryAtLocation(
              [_entry(id: 'a', location: '제주', content: '  ')], '제주'),
          isNull);
      expect(
          longestEntryAtLocation(
              [_entry(id: 'a', location: '서울', content: 'abc')], '제주'),
          isNull);
      expect(
          longestEntryAtLocation(
              [_entry(id: 'a', location: '제주', content: 'abc')], '  '),
          isNull);
    });
  });
}
