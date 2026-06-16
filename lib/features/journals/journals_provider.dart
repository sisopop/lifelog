import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/journal.dart';
import '../entries/entries_provider.dart';
import 'journal_repository.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository(ref.watch(appDatabaseProvider));
});

/// Per-journal entry counts (for list badges).
final journalEntryCountsProvider = FutureProvider<Map<String, int>>((ref) {
  // Re-read when entries change.
  ref.watch(entriesProvider);
  return ref.watch(journalRepositoryProvider).entryCounts();
});

/// Loads journals from the Drift cache (seeds a default journal on first run).
class JournalsNotifier extends AsyncNotifier<List<Journal>> {
  JournalRepository get _repo => ref.read(journalRepositoryProvider);

  @override
  Future<List<Journal>> build() async {
    await _repo.seedIfEmpty();
    return _repo.getAll();
  }

  Future<void> create(Journal journal) async {
    await _repo.save(journal);
    state = AsyncData(await _repo.getAll());
  }

  Future<void> edit(Journal journal) async {
    await _repo.save(journal);
    state = AsyncData(await _repo.getAll());
  }

  Future<void> delete(String journalId) async {
    await _repo.delete(journalId);
    state = AsyncData(await _repo.getAll());
  }
}

final journalsProvider =
    AsyncNotifierProvider<JournalsNotifier, List<Journal>>(
  JournalsNotifier.new,
);
