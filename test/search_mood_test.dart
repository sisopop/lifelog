import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/search/entry_search.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _entry(String id, {Mood? mood}) {
  final t = DateTime(2026, 6, 17);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: 'jr_default',
    content: 'c',
    mood: mood,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  final entries = [
    _entry('a', mood: Mood.good),
    _entry('b', mood: Mood.hard),
    _entry('c', mood: Mood.good),
    _entry('d'), // no mood
  ];

  test('null mood returns the list unchanged', () {
    final out = filterByMood(entries, null);
    expect(out.length, 4);
    expect(identical(out, entries), isTrue);
  });

  test('filters to entries of the given mood only', () {
    final good = filterByMood(entries, Mood.good);
    expect(good.map((e) => e.entryId), ['a', 'c']);

    final hard = filterByMood(entries, Mood.hard);
    expect(hard.map((e) => e.entryId), ['b']);
  });

  test('entries without a mood never match a mood filter', () {
    expect(filterByMood(entries, Mood.neutral), isEmpty);
  });

  test('combining text search + mood filter narrows results', () {
    final searched = searchEntries(entries, 'c'); // matches content 'c' → all
    final good = filterByMood(searched, Mood.good);
    expect(good.map((e) => e.entryId), ['a', 'c']);
  });
}
