import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/places/place_directory.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry({
  required String id,
  String? location,
  String? replyTo,
}) {
  final t = DateTime(2026, 6, 10);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: 'jr_default',
    content: 'c',
    tags: const [],
    location: location,
    replyToEntryId: replyTo,
    createdAt: t,
    updatedAt: t,
  );
}

DiaryEntry _dated({
  required String id,
  String? location,
  required int day,
  String? replyTo,
}) {
  final t = DateTime(2026, 6, day);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: 'jr_default',
    content: 'c',
    tags: const [],
    location: location,
    replyToEntryId: replyTo,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  group('placeCountsSorted', () {
    test('counts distinct places, most-used first', () {
      final list = placeCountsSorted([
        _entry(id: '1', location: '제주'),
        _entry(id: '2', location: '제주'),
        _entry(id: '3', location: '서울'),
      ]);
      expect(list.map((e) => e.key), ['제주', '서울']);
      expect(list.first.value, 2);
    });

    test('groups case-insensitively and trims, keeping first spelling', () {
      final list = placeCountsSorted([
        _entry(id: '1', location: '제주'),
        _entry(id: '2', location: '  제주  '),
      ]);
      expect(list.length, 1);
      expect(list.first.key, '제주');
      expect(list.first.value, 2);
    });

    test('ties are broken alphabetically', () {
      final list = placeCountsSorted([
        _entry(id: '1', location: '부산'),
        _entry(id: '2', location: '강릉'),
      ]);
      expect(list.map((e) => e.key), ['강릉', '부산']);
    });

    test('excludes replies and blank/null locations', () {
      final list = placeCountsSorted([
        _entry(id: 'top', location: '제주'),
        _entry(id: 'reply', location: '제주', replyTo: 'top'),
        _entry(id: 'blank', location: '   '),
        _entry(id: 'none', location: null),
      ]);
      expect(list.length, 1);
      expect(list.first.value, 1);
    });

    test('empty when no locations', () {
      expect(placeCountsSorted([_entry(id: 'a', location: null)]), isEmpty);
    });
  });

  group('lastVisitByPlace', () {
    test('keeps the latest date per place', () {
      final map = lastVisitByPlace([
        _dated(id: '1', location: '제주', day: 3),
        _dated(id: '2', location: '제주', day: 18),
        _dated(id: '3', location: '서울', day: 10),
      ]);
      expect(map['제주'], DateTime(2026, 6, 18));
      expect(map['서울'], DateTime(2026, 6, 10));
    });

    test('groups case-insensitively, keeping first spelling', () {
      final map = lastVisitByPlace([
        _dated(id: '1', location: '제주', day: 5),
        _dated(id: '2', location: '  제주  ', day: 20),
      ]);
      expect(map.keys, ['제주']);
      expect(map['제주'], DateTime(2026, 6, 20));
    });

    test('excludes replies and blank/null locations', () {
      final map = lastVisitByPlace([
        _dated(id: 'top', location: '제주', day: 5),
        _dated(id: 'reply', location: '제주', day: 25, replyTo: 'top'),
        _dated(id: 'blank', location: '   ', day: 9),
      ]);
      expect(map['제주'], DateTime(2026, 6, 5)); // reply on day 25 ignored
      expect(map.length, 1);
    });

    test('empty when no located records', () {
      expect(lastVisitByPlace([_dated(id: 'a', location: null, day: 1)]),
          isEmpty);
    });
  });
}
