import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/core/db/app_database.dart';
import 'package:lifelog/features/entries/diary_repository.dart';
import 'package:lifelog/features/journals/journal_repository.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';
import 'package:lifelog/shared/models/journal.dart';

Journal _journal(String id) => Journal(
      journalId: id,
      ownerId: 'me',
      type: JournalType.personal,
      title: 't$id',
      createdAt: DateTime(2026, 6, 1),
    );

DiaryEntry _entry(String id, String journalId) => DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: journalId,
      content: 'c$id',
      aiStatus: AiStatus.none,
      visibility: EntryVisibility.private,
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );

void main() {
  test('delete() cascade-trashes the journal and its live entries', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final journals = JournalRepository(db);
    final entries = DiaryRepository(db);

    await journals.save(_journal('a'));
    await journals.save(_journal('b'));
    await entries.save(_entry('a1', 'a'));
    await entries.save(_entry('a2', 'a'));
    await entries.save(_entry('b1', 'b'));

    await journals.delete('a');

    // Journal "a" drops out of the live list...
    expect((await journals.getAll()).map((j) => j.journalId), ['b']);
    // ...and so do its entries (no orphans left behind).
    expect((await entries.getAll()).map((e) => e.entryId), ['b1']);
    // Both the journal and its entries sit in the bin.
    expect((await journals.getTrashed()).map((j) => j.journalId), ['a']);
    expect((await entries.getTrashed()).map((e) => e.entryId).toSet(),
        {'a1', 'a2'});
  });

  test('restore() revives the journal and its cascade-trashed entries only',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final journals = JournalRepository(db);
    final entries = DiaryRepository(db);
    final when = DateTime(2026, 6, 10);

    await journals.save(_journal('a'));
    await entries.save(_entry('a1', 'a'));
    await entries.save(_entry('a2', 'a'));

    // a2 was individually trashed earlier (different timestamp).
    await db.softDeleteEntry('a2', DateTime(2026, 6, 5));
    // Now the whole journal is cascade-trashed.
    await journals.delete('a', when);

    await journals.restore('a', when);

    // Journal back, plus only the entry the cascade trashed (a1).
    expect((await journals.getAll()).map((j) => j.journalId), ['a']);
    expect((await entries.getAll()).map((e) => e.entryId), ['a1']);
    // a2 stays in the bin — the user had trashed it before the cascade.
    expect((await entries.getTrashed()).map((e) => e.entryId), ['a2']);
  });

  test('deleteForever() hard-removes the journal, its entries and members',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final journals = JournalRepository(db);
    final entries = DiaryRepository(db);

    await journals.save(_journal('a'));
    await entries.save(_entry('a1', 'a'));
    await journals.delete('a');

    await journals.deleteForever('a');

    expect((await journals.getAll()).length, 0);
    expect((await journals.getTrashed()).length, 0);
    // The entry row is gone from the DB entirely (not just trashed).
    expect((await entries.getAll()).length, 0);
    expect((await entries.getTrashed()).length, 0);
  });

  test('purgeExpiredTrash() removes only journals trashed >30 days ago',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final journals = JournalRepository(db);
    final now = DateTime(2026, 6, 30);

    await journals.save(_journal('old'));
    await journals.save(_journal('recent'));
    await journals.delete('old', now.subtract(const Duration(days: 31)));
    await journals.delete('recent', now.subtract(const Duration(days: 5)));

    final purged = await journals.purgeExpiredTrash(now);
    expect(purged, 1);

    expect((await journals.getTrashed()).map((j) => j.journalId), ['recent']);
  });
}
