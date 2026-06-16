import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/journal.dart';

/// Bridges the domain model (`Journal`) and the Drift cache (`JournalRow`).
class JournalRepository {
  JournalRepository(this._db);

  final AppDatabase _db;

  /// Default personal journal id — also the backfill target for v1 entries.
  static const defaultJournalId = 'jr_default';

  Future<List<Journal>> getAll() async {
    final rows = await _db.getAllJournals();
    return rows.map(_toDomain).toList();
  }

  Future<void> save(Journal journal) {
    return _db.upsertJournal(_toCompanion(journal));
  }

  Future<void> delete(String journalId) => _db.deleteJournal(journalId);

  Future<Map<String, int>> entryCounts() => _db.entryCountsByJournal();

  /// Seeds a default personal journal on first launch (and as the migration
  /// backfill target). Idempotent.
  Future<void> seedIfEmpty() async {
    if (await _db.countJournals() > 0) return;
    await save(
      Journal(
        journalId: defaultJournalId,
        ownerId: 'me',
        type: JournalType.personal,
        title: '나의 일기장',
        coverColor: 0xFF7C6FF0,
        icon: '📔',
        createdAt: DateTime(2026, 6, 1),
      ),
    );
  }

  // ---- mapping ----

  Journal _toDomain(JournalRow r) => Journal(
        journalId: r.journalId,
        ownerId: r.ownerId,
        type: r.type,
        title: r.title,
        coverColor: r.coverColor,
        icon: r.icon,
        status: r.status,
        spaceId: r.spaceId,
        createdAt: r.createdAt,
      );

  JournalsCompanion _toCompanion(Journal j) => JournalsCompanion(
        journalId: Value(j.journalId),
        ownerId: Value(j.ownerId),
        type: Value(j.type),
        title: Value(j.title),
        coverColor: Value(j.coverColor),
        icon: Value(j.icon),
        status: Value(j.status),
        spaceId: Value(j.spaceId),
        createdAt: Value(j.createdAt),
      );
}
