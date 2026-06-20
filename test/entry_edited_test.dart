import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/entry_detail/entry_edited.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _e(DateTime created, DateTime updated) => DiaryEntry(
      entryId: 'e',
      userId: 'me',
      journalId: 'jr_default',
      content: 'c',
      createdAt: created,
      updatedAt: updated,
    );

void main() {
  final base = DateTime(2026, 6, 21, 9, 0);

  test('not edited when timestamps are equal', () {
    expect(wasEdited(_e(base, base)), isFalse);
  });

  test('sub-minute gap counts as save jitter, not an edit', () {
    expect(wasEdited(_e(base, base.add(const Duration(seconds: 30)))), isFalse);
  });

  test('a minute or more later counts as edited', () {
    expect(wasEdited(_e(base, base.add(const Duration(minutes: 1)))), isTrue);
    expect(wasEdited(_e(base, base.add(const Duration(hours: 3)))), isTrue);
  });
}
