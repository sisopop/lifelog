import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/write/write_date.dart';

void main() {
  group('writeDateParam', () {
    test('formats as yyyy-MM-dd, dropping time', () {
      expect(writeDateParam(DateTime(2026, 6, 9, 23, 30)), '2026-06-09');
      expect(writeDateParam(DateTime(2026, 12, 25)), '2026-12-25');
    });
  });

  group('parseWriteDate', () {
    test('null / empty / malformed → null', () {
      expect(parseWriteDate(null), isNull);
      expect(parseWriteDate(''), isNull);
      expect(parseWriteDate('  '), isNull);
      expect(parseWriteDate('not-a-date'), isNull);
    });

    test('parses a valid date and drops the time', () {
      final d = parseWriteDate('2026-06-09');
      expect(d, DateTime(2026, 6, 9));
    });

    test('strips the time-of-day from a full timestamp', () {
      final d = parseWriteDate('2026-06-09T14:25:00');
      expect(d, DateTime(2026, 6, 9));
    });

    test('round-trips with writeDateParam', () {
      final day = DateTime(2026, 3, 1);
      expect(parseWriteDate(writeDateParam(day)), day);
    });
  });
}
