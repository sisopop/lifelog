import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/write/entry_date.dart';

void main() {
  group('composeEntryDate', () {
    test('takes calendar day from day and time-of-day from base', () {
      final day = DateTime(2024, 3, 15, 9, 0, 0);
      final base = DateTime(2026, 6, 21, 14, 35, 12, 500);
      final result = composeEntryDate(day, base);
      expect(result.year, 2024);
      expect(result.month, 3);
      expect(result.day, 15);
      expect(result.hour, 14);
      expect(result.minute, 35);
      expect(result.second, 12);
      expect(result.millisecond, 500);
    });

    test('keeps midnight time when base is midnight', () {
      final day = DateTime(2025, 1, 1);
      final base = DateTime(2025, 1, 1);
      final result = composeEntryDate(day, base);
      expect(result, DateTime(2025, 1, 1, 0, 0, 0, 0));
    });

    test('ignores day time-of-day entirely', () {
      final day = DateTime(2023, 12, 31, 23, 59, 59);
      final base = DateTime(2026, 6, 21, 8, 0, 0);
      final result = composeEntryDate(day, base);
      expect(result.hour, 8);
      expect(result.minute, 0);
      expect(result.second, 0);
    });
  });
}
