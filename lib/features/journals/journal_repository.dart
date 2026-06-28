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

  /// 휴지통으로 보내기 (cascade): the journal and all its currently-live
  /// entries are stamped with the same timestamp, so they vanish together.
  Future<void> delete(String journalId, [DateTime? when]) =>
      _db.softDeleteJournalCascade(journalId, when ?? DateTime.now());

  /// 복원: revives the journal and the entries trashed by the same cascade.
  Future<void> restore(String journalId, DateTime when) =>
      _db.restoreJournalCascade(journalId, when);

  /// 영구 삭제: hard-removes the journal with its entries + members.
  Future<void> deleteForever(String journalId) =>
      _db.deleteJournalForever(journalId);

  /// Soft-deleted journals (휴지통), newest deletion first.
  Future<List<Journal>> getTrashed() async {
    final rows = await _db.getTrashedJournals();
    return rows.map(_toDomain).toList();
  }

  /// Permanently removes journals trashed more than 30 days ago.
  Future<int> purgeExpiredTrash([DateTime? now]) {
    final cutoff = (now ?? DateTime.now()).subtract(const Duration(days: 30));
    return _db.purgeJournalsDeletedBefore(cutoff);
  }

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
        coverPattern: r.coverPattern,
        coverBinding: r.coverBinding,
        coverCorner: r.coverCorner,
        coverBand: r.coverBand,
        coverRibbon: r.coverRibbon,
        coverClip: r.coverClip,
        coverTab: r.coverTab,
        coverTexture: r.coverTexture,
        coverFont: r.coverFont,
        innerPaper: r.innerPaper,
        innerPaperColor: r.innerPaperColor,
        icon: r.icon,
        status: r.status,
        spaceId: r.spaceId,
        createdAt: r.createdAt,
        deletedAt: r.deletedAt,
      );

  JournalsCompanion _toCompanion(Journal j) => JournalsCompanion(
        journalId: Value(j.journalId),
        ownerId: Value(j.ownerId),
        type: Value(j.type),
        title: Value(j.title),
        coverColor: Value(j.coverColor),
        coverPattern: Value(j.coverPattern),
        coverBinding: Value(j.coverBinding),
        coverCorner: Value(j.coverCorner),
        coverBand: Value(j.coverBand),
        coverRibbon: Value(j.coverRibbon),
        coverClip: Value(j.coverClip),
        coverTab: Value(j.coverTab),
        coverTexture: Value(j.coverTexture),
        coverFont: Value(j.coverFont),
        innerPaper: Value(j.innerPaper),
        innerPaperColor: Value(j.innerPaperColor),
        icon: Value(j.icon),
        status: Value(j.status),
        spaceId: Value(j.spaceId),
        createdAt: Value(j.createdAt),
        deletedAt: Value(j.deletedAt),
      );
}
