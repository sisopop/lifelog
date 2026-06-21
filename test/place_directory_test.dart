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
}
