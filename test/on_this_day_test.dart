import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/memories/on_this_day.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _e(String id, DateTime created, {String? replyTo}) => DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'j1',
      replyToEntryId: replyTo,
      content: 'x',
      createdAt: created,
      updatedAt: created,
    );

void main() {
  final today = DateTime(2026, 6, 21, 9);

  group('entriesOnThisDay', () {
    test('matches same month+day in earlier years, newest first', () {
      final entries = [
        _e('a', DateTime(2024, 6, 21)),
        _e('b', DateTime(2025, 6, 21)),
        _e('c', DateTime(2023, 6, 21)),
      ];
      expect(
        entriesOnThisDay(entries, today).map((e) => e.entryId).toList(),
        ['b', 'a', 'c'],
      );
    });

    test('excludes today\'s own year', () {
      final entries = [_e('today', DateTime(2026, 6, 21))];
      expect(entriesOnThisDay(entries, today), isEmpty);
    });

    test('excludes other days and months', () {
      final entries = [
        _e('wrongDay', DateTime(2025, 6, 20)),
        _e('wrongMonth', DateTime(2025, 7, 21)),
      ];
      expect(entriesOnThisDay(entries, today), isEmpty);
    });

    test('excludes replies', () {
      final entries = [
        _e('reply', DateTime(2025, 6, 21), replyTo: 'parent'),
      ];
      expect(entriesOnThisDay(entries, today), isEmpty);
    });
  });

  group('yearsAgo', () {
    test('whole-year difference', () {
      expect(yearsAgo(DateTime(2025, 6, 21), today), 1);
      expect(yearsAgo(DateTime(2023, 1, 1), today), 3);
    });
  });
}
