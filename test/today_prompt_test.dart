import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/home/today_prompt.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _at(String id, DateTime at, {String? replyTo}) => DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'jr_default',
      content: 'c',
      replyToEntryId: replyTo,
      createdAt: at,
      updatedAt: at,
    );

void main() {
  final today = DateTime(2026, 6, 21);

  test('false when there are no entries', () {
    expect(hasEntryOn(const [], today), isFalse);
  });

  test('true when a top-level entry exists on the day (time ignored)', () {
    expect(
      hasEntryOn([_at('a', DateTime(2026, 6, 21, 23, 5))], today),
      isTrue,
    );
  });

  test('false when the only entry is on another day', () {
    expect(hasEntryOn([_at('a', DateTime(2026, 6, 20))], today), isFalse);
  });

  test('a reply on the day does not count', () {
    expect(
      hasEntryOn([_at('r', DateTime(2026, 6, 21), replyTo: 'a')], today),
      isFalse,
    );
  });
}
