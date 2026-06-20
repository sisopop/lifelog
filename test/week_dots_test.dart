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
}
