import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/stats/lifetime_stats.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry({
  required String id,
  String content = 'c',
  required DateTime at,
  String? replyTo,
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'jr_default',
      content: content,
      tags: const [],
      replyToEntryId: replyTo,
      createdAt: at,
      updatedAt: at,
    );

void main() {
  test('empty → all zero and no first date', () {
    final s = computeLifetimeStats(const []);
    expect(s.isEmpty, true);
    expect(s.totalEntries, 0);
    expect(s.firstDate, isNull);
  });

  test('aggregates totals and excludes replies', () {
    final s = computeLifetimeStats([
      _entry(id: 'a', content: '제주', at: DateTime(2026, 6, 1)), // 2 chars
      _entry(id: 'b', content: 'hello', at: DateTime(2026, 6, 2)), // 5 chars
      _entry(id: 'r', content: 'reply', at: DateTime(2026, 6, 3), replyTo: 'a'),
    ]);
    expect(s.totalEntries, 2);
    expect(s.totalChars, 7);
    expect(s.recordedDays, 2);
  });

  test('firstDate is the earliest top-level day (time stripped)', () {
    final s = computeLifetimeStats([
      _entry(id: 'late', at: DateTime(2026, 6, 10, 9)),
      _entry(id: 'early', at: DateTime(2026, 6, 2, 23, 59)),
    ]);
    expect(s.firstDate, DateTime(2026, 6, 2));
  });

  test('longestStreak counts consecutive recorded days', () {
    final s = computeLifetimeStats([
      _entry(id: '1', at: DateTime(2026, 6, 1)),
      _entry(id: '2', at: DateTime(2026, 6, 2)),
      _entry(id: '3', at: DateTime(2026, 6, 3)),
      _entry(id: '5', at: DateTime(2026, 6, 5)),
    ]);
    expect(s.longestStreak, 3);
  });
}
