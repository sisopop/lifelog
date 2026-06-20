import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../tags/tag_manage.dart';
import 'diary_repository.dart';
import 'gemini_service.dart';

/// Single database instance for the app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepository(ref.watch(appDatabaseProvider));
});

/// AI summarizer (Gemini 2.5 Flash, falls back to local mock without a key).
final geminiServiceProvider = Provider<GeminiService>((ref) {
  final service = GeminiService();
  return service;
});

/// Loads entries from the Drift cache (seeds demo data on first run).
class EntriesNotifier extends AsyncNotifier<List<DiaryEntry>> {
  DiaryRepository get _repo => ref.read(diaryRepositoryProvider);

  @override
  Future<List<DiaryEntry>> build() async {
    await _repo.seedIfEmpty();
    return _repo.getAll();
  }

  Future<void> add(DiaryEntry entry) async {
    await _repo.insert(entry);
    state = AsyncData(await _repo.getAll());
    // Fire-and-forget local summary generation (pending -> done).
    unawaited(_generateSummary(entry));
  }

  /// 답장형 기록: adds a short reply attached to [parent]. Replies live in the
  /// same journal, inherit visibility, and skip AI summarization.
  Future<void> addReply({
    required DiaryEntry parent,
    required String content,
    String userId = 'me',
  }) async {
    final now = DateTime.now();
    await _repo.insert(
      DiaryEntry(
        entryId: now.microsecondsSinceEpoch.toString(),
        userId: userId,
        journalId: parent.journalId,
        replyToEntryId: parent.entryId,
        lang: parent.lang,
        content: content,
        visibility: parent.visibility,
        createdAt: now,
        updatedAt: now,
      ),
    );
    state = AsyncData(await _repo.getAll());
  }

  /// Upsert an existing entry (e.g. visibility change) and refresh state.
  Future<void> saveEntry(DiaryEntry entry) async {
    await _repo.save(entry.copyWith(updatedAt: DateTime.now()));
    state = AsyncData(await _repo.getAll());
  }

  /// Save edits to an entry and regenerate its AI summary (content changed).
  Future<void> editEntry(DiaryEntry entry) async {
    final pending = entry.copyWith(
      updatedAt: DateTime.now(),
      aiStatus: AiStatus.pending,
    );
    await _repo.save(pending);
    state = AsyncData(await _repo.getAll());
    unawaited(_generateSummary(pending));
  }

  Future<void> delete(String entryId) async {
    await _repo.delete(entryId);
    state = AsyncData(await _repo.getAll());
  }

  /// 즐겨찾기 토글. Flips the star on [entry] and persists it.
  Future<void> toggleFavorite(DiaryEntry entry) async {
    await _repo.save(entry.copyWith(isFavorite: !entry.isFavorite));
    state = AsyncData(await _repo.getAll());
  }

  /// Renames a tag across every entry that uses it. No-op when nothing changes.
  Future<void> renameTag(String from, String to) async {
    final current = state.asData?.value ?? const [];
    final changed = renameTagInEntries(current, from, to);
    if (changed.isEmpty) return;
    for (final e in changed) {
      await _repo.save(e.copyWith(updatedAt: DateTime.now()));
    }
    state = AsyncData(await _repo.getAll());
  }

  /// Removes a tag from every entry that uses it. No-op when nothing changes.
  Future<void> deleteTag(String tag) async {
    final current = state.asData?.value ?? const [];
    final changed = removeTagFromEntries(current, tag);
    if (changed.isEmpty) return;
    for (final e in changed) {
      await _repo.save(e.copyWith(updatedAt: DateTime.now()));
    }
    state = AsyncData(await _repo.getAll());
  }

  /// Generates the AI summary via Gemini (or the local mock fallback) and
  /// persists it (pending -> done).
  Future<void> _generateSummary(DiaryEntry entry) async {
    if (entry.aiStatus != AiStatus.pending) return;
    final summary = await ref.read(geminiServiceProvider).summarize(entry);
    final summarized = entry.copyWith(
      aiSummary: summary,
      aiStatus: AiStatus.done,
    );
    await _repo.save(summarized);
    state = AsyncData(await _repo.getAll());
  }
}

final entriesProvider =
    AsyncNotifierProvider<EntriesNotifier, List<DiaryEntry>>(
  EntriesNotifier.new,
);
