import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/write/writing_prompts.dart';

void main() {
  group('promptIndexForDay', () {
    test('is 0 on Jan 1', () {
      expect(promptIndexForDay(DateTime(2026, 1, 1), 10), 0);
    });

    test('rotates by day-of-year modulo length', () {
      // Jan 12 = day-of-year 11 → 11 % 10 = 1
      expect(promptIndexForDay(DateTime(2026, 1, 12), 10), 1);
    });

    test('ignores time-of-day', () {
      expect(
        promptIndexForDay(DateTime(2026, 1, 12, 23, 59), 10),
        promptIndexForDay(DateTime(2026, 1, 12), 10),
      );
    });

    test('returns 0 for non-positive length', () {
      expect(promptIndexForDay(DateTime(2026, 6, 21), 0), 0);
    });
  });

  group('nextPromptIndex', () {
    test('increments within range', () {
      expect(nextPromptIndex(0, 10), 1);
    });

    test('wraps around at the end', () {
      expect(nextPromptIndex(9, 10), 0);
    });

    test('returns 0 for non-positive length', () {
      expect(nextPromptIndex(3, 0), 0);
    });
  });

  group('promptForDay', () {
    test('returns a prompt from the list', () {
      final p = promptForDay(writingPrompts, DateTime(2026, 6, 21));
      expect(writingPrompts.contains(p), isTrue);
    });

    test('returns empty string for empty list', () {
      expect(promptForDay(const [], DateTime(2026, 6, 21)), '');
    });
  });
}
