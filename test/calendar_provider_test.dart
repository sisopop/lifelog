import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/calendar/calendar_provider.dart';

void main() {
  group('shiftMonth', () {
    test('keeps the day when the target month is long enough', () {
      expect(shiftMonth(DateTime(2026, 1, 10), 1), DateTime(2026, 2, 10));
      expect(shiftMonth(DateTime(2026, 3, 10), -1), DateTime(2026, 2, 10));
    });

    test('clamps the day to the target month last day', () {
      // Feb 2026 has 28 days.
      expect(shiftMonth(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    });

    test('rolls the year over', () {
      expect(shiftMonth(DateTime(2026, 12, 5), 1), DateTime(2027, 1, 5));
      expect(shiftMonth(DateTime(2026, 1, 5), -1), DateTime(2025, 12, 5));
    });
  });

  group('CalendarDateNotifier', () {
    test('build returns today (date-only, no time component)', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final now = DateTime.now();
      final d = c.read(calendarDateProvider);
      expect(d.year, now.year);
      expect(d.month, now.month);
      expect(d.day, now.day);
      expect(d.hour, 0);
      expect(d.minute, 0);
    });

    test('select changes the day within the same month', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(calendarDateProvider.notifier).select(15);
      expect(c.read(calendarDateProvider).day, 15);
    });

    test('previousMonth / nextMonth shift the month, keeping the day', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(calendarDateProvider.notifier);
      n.select(10);
      final start = c.read(calendarDateProvider);
      n.nextMonth();
      final next = c.read(calendarDateProvider);
      expect(next.day, 10);
      expect(DateTime(next.year, next.month),
          DateTime(start.year, start.month + 1));
      n.previousMonth();
      final back = c.read(calendarDateProvider);
      expect(DateTime(back.year, back.month),
          DateTime(start.year, start.month));
    });
  });
}
