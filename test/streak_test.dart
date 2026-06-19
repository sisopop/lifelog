import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/stats/streak.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _e({
  required String id,
  required DateTime at,
  String? replyTo,
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'j1',
      replyToEntryId: replyTo,
      content: 'x',
      createdAt: at,
      updatedAt: at,
    );

Set<DateTime> _days(List<DateTime> ds) => {for (final d in ds) d};

void main() {
  group('recordedDates', () {
    test('strips time and excludes replies, dedupes same day', () {
      final entries = [
        _e(id: '1', at: DateTime(2026, 6, 12, 9)),
        _e(id: '2', at: DateTime(2026, 6, 12, 22)),
        _e(id: '3', at: DateTime(2026, 6, 12, 14), replyTo: '1'),
        _e(id: '4', at: DateTime(2026, 6, 13, 8)),
      ];
      expect(recordedDates(entries),
          {DateTime(2026, 6, 12), DateTime(2026, 6, 13)});
    });
  });

  group('currentStreak', () {
    final today = DateTime(2026, 6, 18);

    test('counts back from today', () {
      final days = _days([
        DateTime(2026, 6, 18),
        DateTime(2026, 6, 17),
        DateTime(2026, 6, 16),
      ]);
      expect(currentStreak(days, today), 3);
    });

    test('counts from yesterday if today not yet recorded', () {
      final days = _days([
        DateTime(2026, 6, 17),
        DateTime(2026, 6, 16),
      ]);
      expect(currentStreak(days, today), 2);
    });

    test('zero when neither today nor yesterday recorded', () {
      final days = _days([DateTime(2026, 6, 10)]);
      expect(currentStreak(days, today), 0);
    });

    test('stops at the first gap', () {
      final days = _days([
        DateTime(2026, 6, 18),
        DateTime(2026, 6, 17),
        // gap on 16
        DateTime(2026, 6, 15),
      ]);
      expect(currentStreak(days, today), 2);
    });

    test('empty set is zero', () {
      expect(currentStreak(const {}, today), 0);
    });
  });

  group('longestStreak', () {
    test('finds the longest run anywhere', () {
      final days = _days([
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 2),
        DateTime(2026, 6, 3), // run of 3
        DateTime(2026, 6, 10),
        DateTime(2026, 6, 11), // run of 2
      ]);
      expect(longestStreak(days), 3);
    });

    test('single day is 1, empty is 0', () {
      expect(longestStreak(_days([DateTime(2026, 6, 1)])), 1);
      expect(longestStreak(const {}), 0);
    });
  });
}
