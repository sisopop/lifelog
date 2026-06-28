import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/core/db/app_database.dart';
import 'package:lifelog/features/entries/diary_repository.dart';
import 'package:lifelog/features/journals/journal_repository.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _entry(String id, {DateTime? createdAt}) => DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: JournalRepository.defaultJournalId,
      content: 'c$id',
      aiStatus: AiStatus.none,
      visibility: EntryVisibility.private,
      createdAt: createdAt ?? DateTime(2026, 6, 1),
      updatedAt: createdAt ?? DateTime(2026, 6, 1),
    );

void main() {
  test('delete() soft-deletes: row persists but drops out of getAll()',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DiaryRepository(db);

    await repo.save(_entry('1'));
    await repo.save(_entry('2'));
    expect((await repo.getAll()).length, 2);

    await repo.delete('1');

    // Hidden from the live list...
    final live = await repo.getAll();
    expect(live.map((e) => e.entryId), ['2']);
    // ...but still in the DB (recoverable from 휴지통).
    final trashed = await repo.getTrashed();
    expect(trashed.length, 1);
    expect(trashed.first.entryId, '1');
    expect(trashed.first.deletedAt, isNotNull);
  });

  test('restore() brings a trashed entry back; deleteForever() removes it',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DiaryRepository(db);

    await repo.save(_entry('1'));
    await repo.delete('1');
    expect((await repo.getAll()).length, 0);

    await repo.restore('1');
    expect((await repo.getAll()).map((e) => e.entryId), ['1']);
    expect((await repo.getTrashed()).length, 0);

    await repo.delete('1');
    await repo.deleteForever('1');
    expect((await repo.getAll()).length, 0);
    expect((await repo.getTrashed()).length, 0);
  });

  test('purgeExpiredTrash() removes only entries trashed >30 days ago',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DiaryRepository(db);
    final now = DateTime(2026, 6, 30);

    await repo.save(_entry('old'));
    await repo.save(_entry('recent'));

    // Trash both, but backdate "old" past the 30-day window.
    await db.softDeleteEntry('old', now.subtract(const Duration(days: 31)));
    await db.softDeleteEntry('recent', now.subtract(const Duration(days: 5)));

    final purged = await repo.purgeExpiredTrash(now);
    expect(purged, 1);

    final trashed = await repo.getTrashed();
    expect(trashed.map((e) => e.entryId), ['recent']);
  });

  test('ensureEntryColumns recovers a diary_entries table missing deleted_at',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await JournalRepository(db).seedIfEmpty();
    final repo = DiaryRepository(db);
    await repo.save(_entry('1'));

    // Simulate the stuck web DB: the v16 column never got added.
    await db.customStatement('ALTER TABLE diary_entries DROP COLUMN deleted_at');
    await expectLater(repo.getAll(), throwsA(anything));

    // Self-heal idempotently re-adds only the missing column.
    await db.ensureEntryColumns();
    await db.ensureEntryColumns(); // no-op second run

    final rows = await repo.getAll();
    expect(rows.length, 1);
    expect(rows.first.deletedAt, isNull);
  });
}
