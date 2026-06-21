import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/stats/stats_provider.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry({
  required String content,
  int day = 10,
  int month = 6,
  int year = 2026,
  String? replyTo,
}) {
  final t = DateTime(year, month, day);
  return DiaryEntry(
    entryId: 'e$day$content',
    userId: 'me',
    journalId: 'jr_default',
    content: content,
    tags: const [],
    replyToEntryId: replyTo,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  group('totalChars', () {
    test('sums grapheme-aware lengths and trims', () {
      final n = totalChars([
        _entry(content: '  안녕  '), // 2
        _entry(content: 'hi'), // 2
      ]);
      expect(n, 4);
    });

    test('emoji counts as one grapheme', () {
      expect(totalChars([_entry(content: '😊')]), 1);
    });

    test('empty list → 0', () {
      expect(totalChars(const []), 0);
    });
  });

  group('computeMonthlyStats.charsWritten', () {
    test('counts only the given month and excludes replies', () {
      final stats = computeMonthlyStats([
        _entry(content: '제주도'), // 3, June
        _entry(content: '답장입니다', replyTo: 'x'), // excluded (reply)
        _entry(content: 'should not count', month: 5), // other month
      ], 2026, 6);
      expect(stats.charsWritten, 3);
      expect(stats.total, 1);
    });

    test('empty month → 0 chars', () {
      final stats = computeMonthlyStats(const [], 2026, 6);
      expect(stats.charsWritten, 0);
    });
  });

  group('MonthlyStats.avgChars', () {
    test('rounds the average body length per record', () {
      final stats = computeMonthlyStats([
        _entry(content: '12345'), // 5
        _entry(content: '12', day: 11), // 2  → (5+2)/2 = 3.5 → 4
      ], 2026, 6);
      expect(stats.total, 2);
      expect(stats.avgChars, 4);
    });

    test('0 when the month has no records', () {
      expect(computeMonthlyStats(const [], 2026, 6).avgChars, 0);
    });

    test('replies do not affect the average', () {
      final stats = computeMonthlyStats([
        _entry(content: '1234'), // 4
        _entry(content: 'ignored reply', replyTo: 'x'),
      ], 2026, 6);
      expect(stats.avgChars, 4);
    });
  });
}
