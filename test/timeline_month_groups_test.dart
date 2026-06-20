import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/timeline/timeline_filter.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry(String id, DateTime at) => DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'jr_default',
      content: 'c',
      createdAt: at,
      updatedAt: at,
    );

void main() {
  test('empty input yields no groups', () {
    expect(groupByMonth(const []), isEmpty);
  });

  test('groups consecutive same-month entries, preserving order', () {
    final entries = [
      _entry('a', DateTime(2026, 6, 20)),
      _entry('b', DateTime(2026, 6, 3)),
      _entry('c', DateTime(2026, 5, 28)),
      _entry('d', DateTime(2026, 5, 1)),
    ];
    final groups = groupByMonth(entries);
    expect(groups.length, 2);
    expect(groups[0].year, 2026);
    expect(groups[0].month, 6);
    expect(groups[0].entries.map((e) => e.entryId), ['a', 'b']);
    expect(groups[1].month, 5);
    expect(groups[1].entries.map((e) => e.entryId), ['c', 'd']);
  });

  test('same month across different years are separate groups', () {
    final groups = groupByMonth([
      _entry('a', DateTime(2026, 6, 1)),
      _entry('b', DateTime(2025, 6, 1)),
    ]);
    expect(groups.length, 2);
    expect(groups[0].year, 2026);
    expect(groups[1].year, 2025);
  });

  test('a month that recurs after another month starts a new group', () {
    // ascending-style ordering where June appears, then May, then June again
    final groups = groupByMonth([
      _entry('a', DateTime(2026, 6, 5)),
      _entry('b', DateTime(2026, 5, 5)),
      _entry('c', DateTime(2026, 6, 1)),
    ]);
    expect(groups.length, 3);
    expect(groups.map((g) => g.month), [6, 5, 6]);
  });
}
