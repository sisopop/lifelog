import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/stats/stats_provider.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry({
  required String id,
  required DateTime at,
  String? replyTo,
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'jr_default',
      content: 'c',
      replyToEntryId: replyTo,
      createdAt: at,
      updatedAt: at,
    );

void main() {
  group('busiestWeekdayOfMonth', () {
    test('picks the most-recorded weekday of the month with its count', () {
      // 2026-06-01 is Monday. 6/1, 6/8 = Mondays; 6/3 = Wednesday.
      final best = busiestWeekdayOfMonth([
        _entry(id: '1', at: DateTime(2026, 6, 1)),
        _entry(id: '2', at: DateTime(2026, 6, 8)),
        _entry(id: '3', at: DateTime(2026, 6, 3)),
      ], 2026, 6);
      expect(best!.key, '월요일');
      expect(best.value, 2);
    });

    test('only counts the given month', () {
      final best = busiestWeekdayOfMonth([
        _entry(id: '1', at: DateTime(2026, 6, 3)), // Wed
        _entry(id: '2', at: DateTime(2026, 5, 4)), // Mon (other month)
        _entry(id: '3', at: DateTime(2026, 5, 11)), // Mon (other month)
      ], 2026, 6);
      expect(best!.key, '수요일');
      expect(best.value, 1);
    });

    test('ignores replies', () {
      final best = busiestWeekdayOfMonth([
        _entry(id: '1', at: DateTime(2026, 6, 3)), // Wed
        _entry(id: 'r1', at: DateTime(2026, 6, 1), replyTo: '1'), // Mon reply
        _entry(id: 'r2', at: DateTime(2026, 6, 8), replyTo: '1'), // Mon reply
      ], 2026, 6);
      expect(best!.key, '수요일');
      expect(best.value, 1);
    });

    test('ties resolve to the earlier weekday (Mon before Sun)', () {
      // 6/3 Wed, 6/2 Tue → tie at 1 each, Tuesday is earlier.
      final best = busiestWeekdayOfMonth([
        _entry(id: '1', at: DateTime(2026, 6, 3)),
        _entry(id: '2', at: DateTime(2026, 6, 2)),
      ], 2026, 6);
      expect(best!.key, '화요일');
    });

    test('null when the month has no records', () {
      expect(busiestWeekdayOfMonth(const [], 2026, 6), isNull);
    });
  });
}
