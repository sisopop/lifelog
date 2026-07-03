import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/places/place_entries.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _entry({
  required String id,
  String? location,
  int day = 10,
  String? replyTo,
  List<String> tags = const [],
  Mood? mood,
  String content = 'c',
  bool favorite = false,
}) {
  final t = DateTime(2026, 6, day);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: 'jr_default',
    content: content,
    tags: tags,
    location: location,
    mood: mood,
    isFavorite: favorite,
    replyToEntryId: replyTo,
    createdAt: t,
    updatedAt: t,
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
}
