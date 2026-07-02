import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/places/place_entries.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry({
  required String id,
  String? location,
  int day = 10,
  String? replyTo,
  List<String> tags = const [],
}) {
  final t = DateTime(2026, 6, day);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: 'jr_default',
    content: 'c',
    tags: tags,
    location: location,
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
}
