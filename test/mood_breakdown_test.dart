import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/stats/lifetime_stats.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _entry(String id, {Mood? mood, String? replyTo}) {
  final t = DateTime(2026, 6, 17);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: 'jr_default',
    content: 'c',
    mood: mood,
    replyToEntryId: replyTo,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  test('empty input yields an empty map', () {
    expect(moodBreakdown(const []), isEmpty);
  });

  test('counts moods and ignores entries without a mood', () {
    final m = moodBreakdown([
      _entry('a', mood: Mood.good),
      _entry('b', mood: Mood.good),
      _entry('c', mood: Mood.hard),
      _entry('d'), // no mood
    ]);
    expect(m[Mood.good], 2);
    expect(m[Mood.hard], 1);
    expect(m.containsKey(Mood.neutral), isFalse);
  });

  test('replies are excluded from the breakdown', () {
    final m = moodBreakdown([
      _entry('a', mood: Mood.good),
      _entry('r', mood: Mood.hard, replyTo: 'a'),
    ]);
    expect(m[Mood.good], 1);
    expect(m.containsKey(Mood.hard), isFalse);
  });

  test('keys follow Mood.values order', () {
    final m = moodBreakdown([
      _entry('a', mood: Mood.hard),
      _entry('b', mood: Mood.good),
      _entry('c', mood: Mood.neutral),
    ]);
    expect(m.keys.toList(), [Mood.good, Mood.neutral, Mood.hard]);
  });
}
