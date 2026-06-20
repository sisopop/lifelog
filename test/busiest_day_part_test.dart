import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/stats/lifetime_stats.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _at(String id, int hour, {String? replyTo}) {
  final t = DateTime(2026, 6, 17, hour, 30);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: 'jr_default',
    content: 'c',
    replyToEntryId: replyTo,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  test('null when there are no entries', () {
    expect(busiestDayPart(const []), isNull);
  });

  test('buckets hours into the right day-part', () {
    expect(busiestDayPart([_at('a', 2)])!.key, DayPart.dawn);
    expect(busiestDayPart([_at('b', 8)])!.key, DayPart.morning);
    expect(busiestDayPart([_at('c', 14)])!.key, DayPart.afternoon);
    expect(busiestDayPart([_at('d', 21)])!.key, DayPart.evening);
  });

  test('picks the most frequent day-part with its count', () {
    final best = busiestDayPart([
      _at('a', 20),
      _at('b', 22),
      _at('c', 9),
    ]);
    expect(best!.key, DayPart.evening);
    expect(best.value, 2);
  });

  test('ties resolve to the earlier day-part', () {
    final best = busiestDayPart([
      _at('a', 8), // morning
      _at('b', 20), // evening
    ]);
    expect(best!.key, DayPart.morning);
  });

  test('replies are excluded', () {
    final best = busiestDayPart([
      _at('a', 8),
      _at('r', 20, replyTo: 'a'),
    ]);
    expect(best!.key, DayPart.morning);
    expect(best.value, 1);
  });
}
