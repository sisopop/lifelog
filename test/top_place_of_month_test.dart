import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/places/place_directory.dart';
import 'package:lifelog/features/stats/stats_provider.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry({
  required String id,
  required int month,
  required int day,
  String? location,
  String? replyTo,
}) {
  final t = DateTime(2026, month, day);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: 'jr_default',
    content: 'c',
    location: location,
    replyToEntryId: replyTo,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  group('topPlaceOfMonth', () {
    test('picks the most-visited place of the month with its count', () {
      final best = topPlaceOfMonth([
        _entry(id: '1', month: 6, day: 3, location: '제주'),
        _entry(id: '2', month: 6, day: 10, location: '제주'),
        _entry(id: '3', month: 6, day: 12, location: '서울'),
      ], 2026, 6);
      expect(best!.key, '제주');
      expect(best.value, 2);
    });

    test('only counts the given month', () {
      final best = topPlaceOfMonth([
        _entry(id: '1', month: 6, day: 3, location: '제주'),
        _entry(id: '2', month: 5, day: 9, location: '부산'),
        _entry(id: '3', month: 5, day: 10, location: '부산'),
      ], 2026, 6);
      expect(best!.key, '제주');
      expect(best.value, 1);
    });

    test('groups case-insensitively and trims, keeping first spelling', () {
      final best = topPlaceOfMonth([
        _entry(id: '1', month: 6, day: 3, location: '제주'),
        _entry(id: '2', month: 6, day: 5, location: '  제주  '),
      ], 2026, 6);
      expect(best!.key, '제주');
      expect(best.value, 2);
    });

    test('ties resolve alphabetically', () {
      final best = topPlaceOfMonth([
        _entry(id: '1', month: 6, day: 3, location: '부산'),
        _entry(id: '2', month: 6, day: 5, location: '강릉'),
      ], 2026, 6);
      expect(best!.key, '강릉');
    });

    test('excludes replies and blank/null locations', () {
      final best = topPlaceOfMonth([
        _entry(id: 'top', month: 6, day: 3, location: '제주'),
        _entry(id: 'reply', month: 6, day: 3, location: '제주', replyTo: 'top'),
        _entry(id: 'blank', month: 6, day: 4, location: '   '),
        _entry(id: 'none', month: 6, day: 5, location: null),
      ], 2026, 6);
      expect(best!.key, '제주');
      expect(best.value, 1);
    });

    test('null when the month has no located records', () {
      final best = topPlaceOfMonth([
        _entry(id: '1', month: 6, day: 3, location: null),
      ], 2026, 6);
      expect(best, isNull);
    });
  });

  group('distinctPlacesOfMonth', () {
    test('counts distinct in-month locations (case-insensitive)', () {
      // June: 제주, 서울, 제주(again, dup) → 2 distinct. May 부산 excluded.
      final n = distinctPlacesOfMonth([
        _entry(id: '1', month: 6, day: 3, location: '제주'),
        _entry(id: '2', month: 6, day: 10, location: '서울'),
        _entry(id: '3', month: 6, day: 12, location: '제주'),
        _entry(id: '4', month: 5, day: 9, location: '부산'),
      ], 2026, 6);
      expect(n, 2);
    });

    test('excludes replies and blank/null locations', () {
      final n = distinctPlacesOfMonth([
        _entry(id: 'a', month: 6, day: 3, location: '제주'),
        _entry(id: 'r', month: 6, day: 3, location: '서울', replyTo: 'a'),
        _entry(id: 'b', month: 6, day: 4, location: '   '),
        _entry(id: 'c', month: 6, day: 5, location: null),
      ], 2026, 6);
      expect(n, 1);
    });

    test('0 when the month has no located records', () {
      final n = distinctPlacesOfMonth([
        _entry(id: '1', month: 5, day: 3, location: '제주'),
      ], 2026, 6);
      expect(n, 0);
    });
  });
}
