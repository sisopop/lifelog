import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/stats/stats_provider.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry(DateTime createdAt, {String? replyTo}) {
  return DiaryEntry(
    entryId: createdAt.microsecondsSinceEpoch.toString(),
    userId: 'me',
    journalId: 'jr_default',
    content: 'c',
    createdAt: createdAt,
    updatedAt: createdAt,
    replyToEntryId: replyTo,
  );
}

void main() {
  // Wednesday 2026-06-17
  final now = DateTime(2026, 6, 17, 14);

  test('returns 7 dots, oldest first, today last', () {
    final dots = weekDots(const [], now);
    expect(dots.length, 7);
    // 2026-06-11 (목) … 2026-06-17 (수)
    expect(dots.map((d) => d.label), ['목', '금', '토', '일', '월', '화', '수']);
    expect(dots.every((d) => !d.done), isTrue);
    // Each dot carries its calendar date, oldest first, today last.
    expect(dots.first.date, DateTime(2026, 6, 11));
    expect(dots.last.date, DateTime(2026, 6, 17));
  });

  test('marks days that have a top-level entry', () {
    final dots = weekDots([
      _entry(DateTime(2026, 6, 12, 9)), // 금
      _entry(DateTime(2026, 6, 17, 8)), // 수 (today)
    ], now);
    expect(dots[1].done, isTrue); // 금
    expect(dots[6].done, isTrue); // 수
    expect(dots[0].done, isFalse); // 목
  });

  test('ignores replies and out-of-window entries', () {
    final dots = weekDots([
      _entry(DateTime(2026, 6, 16, 9), replyTo: 'x'), // reply → ignored
      _entry(DateTime(2026, 6, 1, 9)), // before window → ignored
    ], now);
    expect(dots.every((d) => !d.done), isTrue);
  });

  group('weekEntryCount', () {
    test('counts top-level entries in the last 7 days, multiple per day', () {
      // window 6/11 … 6/17
      final n = weekEntryCount([
        _entry(DateTime(2026, 6, 11, 9)), // oldest in window
        _entry(DateTime(2026, 6, 14, 9)),
        _entry(DateTime(2026, 6, 14, 20)), // same day, still counts
        _entry(DateTime(2026, 6, 17, 8)), // today
      ], now);
      expect(n, 4);
    });

    test('excludes entries before the window and replies', () {
      final n = weekEntryCount([
        _entry(DateTime(2026, 6, 10, 23)), // one day before window → out
        _entry(DateTime(2026, 6, 17, 9), replyTo: 'x'), // reply → ignored
        _entry(DateTime(2026, 6, 13, 9)), // in window
      ], now);
      expect(n, 1);
    });

    test('zero when nothing falls in the window', () {
      expect(weekEntryCount(const [], now), 0);
    });
  });
}
