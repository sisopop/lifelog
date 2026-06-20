import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/search/entry_search.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry(String id, String journalId) {
  final t = DateTime(2026, 6, 17);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: journalId,
    content: 'c',
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  final entries = [
    _entry('a', 'jr_default'),
    _entry('b', 'jr_exchange'),
    _entry('c', 'jr_default'),
  ];

  test('null journalId returns the list unchanged', () {
    final out = filterByJournal(entries, null);
    expect(out.length, 3);
    expect(identical(out, entries), isTrue);
  });

  test('filters to entries of the given journal only', () {
    final def = filterByJournal(entries, 'jr_default');
    expect(def.map((e) => e.entryId), ['a', 'c']);

    final ex = filterByJournal(entries, 'jr_exchange');
    expect(ex.map((e) => e.entryId), ['b']);
  });

  test('unknown journalId yields no results', () {
    expect(filterByJournal(entries, 'jr_missing'), isEmpty);
  });

  test('combining text search + journal filter narrows results', () {
    final searched = searchEntries(entries, 'c'); // content 'c' → all 3
    final def = filterByJournal(searched, 'jr_default');
    expect(def.map((e) => e.entryId), ['a', 'c']);
  });
}
