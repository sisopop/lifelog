import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import 'ai_summary.dart';
import 'diary_repository.dart';

/// Single database instance for the app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepository(ref.watch(appDatabaseProvider));
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

  /// Upsert an existing entry (e.g. visibility change) and refresh state.
  Future<void> saveEntry(DiaryEntry entry) async {
    await _repo.save(entry.copyWith(updatedAt: DateTime.now()));
    state = AsyncData(await _repo.getAll());
  }

  Future<void> delete(String entryId) async {
    await _repo.delete(entryId);
    state = AsyncData(await _repo.getAll());
  }

  /// Simulates async AI summarization locally (placeholder for the real
  /// `/ai/summarize` endpoint — see TECH_DESIGN.md).
  Future<void> _generateSummary(DiaryEntry entry) async {
    if (entry.aiStatus != AiStatus.pending) return;
    await Future.delayed(const Duration(milliseconds: 700));
    final summarized = entry.copyWith(
      aiSummary: mockSummarize(entry),
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
