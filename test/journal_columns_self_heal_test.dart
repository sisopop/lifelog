import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/core/db/app_database.dart';
import 'package:lifelog/features/journals/journal_repository.dart';

/// Reproduces the web (drift WASM) regression where a journals column went
/// missing while the stored schema version stayed at 15, so `getAllJournals()`
/// threw and journals "disappeared" from the home screen. Verifies the
/// `ensureJournalColumns()` self-heal recovers a stuck DB without losing data.
void main() {
  test('ensureJournalColumns recovers a journals table missing inner-paper '
      'columns and getAllJournals works again', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Seed one journal through the normal path (all columns present).
    await JournalRepository(db).seedIfEmpty();
    expect((await db.getAllJournals()).length, 1);

    // Simulate the stuck web DB: the new 속지 columns never got added.
    await db.customStatement('ALTER TABLE journals DROP COLUMN inner_paper_color');
    await db.customStatement('ALTER TABLE journals DROP COLUMN inner_paper');

    // The generated SELECT references the now-missing columns, so it throws —
    // this is exactly what made journals vanish while entries survived.
    await expectLater(db.getAllJournals(), throwsA(anything));

    // Self-heal: idempotently re-adds only the missing columns.
    await db.ensureJournalColumns();

    // Journals read works again and the existing row (data) is intact.
    final rows = await db.getAllJournals();
    expect(rows.length, 1);
    expect(rows.first.journalId, JournalRepository.defaultJournalId);
    expect(rows.first.innerPaper, 'plain');
    expect(rows.first.innerPaperColor, 'cream');
  });

  test('ensureJournalColumns recovers missing icon position columns and '
      'backfills 0/0 (top-left) for existing journals', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await JournalRepository(db).seedIfEmpty();

    // Simulate a stuck DB where the new icon-position columns never got added.
    await db.customStatement('ALTER TABLE journals DROP COLUMN icon_x');
    await db.customStatement('ALTER TABLE journals DROP COLUMN icon_y');
    await expectLater(db.getAllJournals(), throwsA(anything));

    await db.ensureJournalColumns();

    final rows = await db.getAllJournals();
    expect(rows.length, 1);
    // Existing journals default to the top-left position (종전 모습 유지).
    expect(rows.first.iconX, 0.0);
    expect(rows.first.iconY, 0.0);
  });

  test('ensureJournalColumns is a no-op on a healthy DB', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await JournalRepository(db).seedIfEmpty();

    // Running it on an already-consistent DB must not throw or duplicate.
    await db.ensureJournalColumns();
    await db.ensureJournalColumns();

    expect((await db.getAllJournals()).length, 1);
  });
}
