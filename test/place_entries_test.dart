import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/places/place_entries.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry({
  required String id,
  String? location,
  int day = 10,
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
}
