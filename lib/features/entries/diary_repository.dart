import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';
import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../journals/journal_repository.dart';

/// Bridges the domain model (`DiaryEntry`) and the Drift cache (`DiaryEntryRow`).
/// Later this is where REST sync logic will live (see TECH_DESIGN.md).
class DiaryRepository {
  DiaryRepository(this._db);

  final AppDatabase _db;

  Future<List<DiaryEntry>> getAll() async {
    final rows = await _db.getAllEntries();
    return rows.map(_toDomain).toList();
  }

  Future<void> insert(DiaryEntry entry) {
    return _db.upsertEntry(_toCompanion(entry));
  }

  /// Insert or update (upsert by entryId).
  Future<void> save(DiaryEntry entry) {
    return _db.upsertEntry(_toCompanion(entry));
  }

  /// 휴지통으로 보내기 (soft delete) — kept 30 days, hidden from lists.
  Future<void> delete(String entryId) {
    return _db.softDeleteEntry(entryId, DateTime.now());
  }

  /// 복원: brings a trashed entry back to the live list.
  Future<void> restore(String entryId) {
    return _db.restoreEntry(entryId);
  }

  /// 영구 삭제: removes a trashed entry for good.
  Future<void> deleteForever(String entryId) {
    return _db.deleteEntry(entryId);
  }

  /// Trashed entries (휴지통), newest deletion first.
  Future<List<DiaryEntry>> getTrashed() async {
    final rows = await _db.getTrashedEntries();
    return rows.map(_toDomain).toList();
  }

  /// Drops entries trashed more than 30 days ago. Returns purged count.
  Future<int> purgeExpiredTrash([DateTime? now]) {
    final cutoff = (now ?? DateTime.now()).subtract(const Duration(days: 30));
    return _db.purgeEntriesDeletedBefore(cutoff);
  }

  /// Seeds demo data on first launch so the UI isn't empty.
  Future<void> seedIfEmpty() async {
    if (await _db.countEntries() > 0) return;
    for (final e in _seed) {
      await _db.upsertEntry(_toCompanion(e));
    }
  }

  // ---- mapping ----

  DiaryEntry _toDomain(DiaryEntryRow r) => DiaryEntry(
        entryId: r.entryId,
        userId: r.userId,
        journalId: r.journalId,
        replyToEntryId: r.replyToEntryId,
        lang: r.lang,
        title: r.title,
        content: r.content,
        aiSummary: r.aiSummary,
        aiStatus: r.aiStatus,
        mood: r.mood,
        visibility: r.visibility,
        location: r.location,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        mediaUrls: r.mediaUrls,
        tags: r.tags,
        isFavorite: r.isFavorite,
        deletedAt: r.deletedAt,
        syncStatus: r.syncStatus,
      );

  DiaryEntriesCompanion _toCompanion(DiaryEntry e) => DiaryEntriesCompanion(
        entryId: Value(e.entryId),
        userId: Value(e.userId),
        journalId: Value(e.journalId),
        replyToEntryId: Value(e.replyToEntryId),
        lang: Value(e.lang),
        title: Value(e.title),
        content: Value(e.content),
        aiSummary: Value(e.aiSummary),
        aiStatus: Value(e.aiStatus),
        mood: Value(e.mood),
        visibility: Value(e.visibility),
        location: Value(e.location),
        tags: Value(e.tags),
        mediaUrls: Value(e.mediaUrls),
        isFavorite: Value(e.isFavorite),
        deletedAt: Value(e.deletedAt),
        createdAt: Value(e.createdAt),
        updatedAt: Value(e.updatedAt),
        syncStatus: Value(e.syncStatus),
      );

  static final List<DiaryEntry> _seed = [
    DiaryEntry(
      entryId: '1',
      userId: 'me',
      journalId: JournalRepository.defaultJournalId,
      title: '제주도에서의 하루',
      content: '아침 일찍 일어나 바닷가를 걸었다. 바람이 시원했고 가족과 함께한 시간이 좋았다.',
      aiSummary: '가족과 함께한 제주 여행, 평온하고 만족스러운 하루.',
      aiStatus: AiStatus.done,
      mood: Mood.good,
      visibility: EntryVisibility.private,
      location: '제주',
      createdAt: DateTime(2026, 6, 13, 9, 30),
      updatedAt: DateTime(2026, 6, 13, 9, 30),
      tags: const ['여행', '가족', '제주도'],
    ),
    DiaryEntry(
      entryId: '2',
      userId: 'me',
      journalId: JournalRepository.defaultJournalId,
      title: '아이와 산책',
      content: '동네 공원을 한 바퀴 돌았다. 사소하지만 소중한 시간.',
      mood: Mood.neutral,
      visibility: EntryVisibility.private,
      createdAt: DateTime(2026, 6, 12, 18, 0),
      updatedAt: DateTime(2026, 6, 12, 18, 0),
      tags: const ['일상', '육아'],
    ),
  ];
}
