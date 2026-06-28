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
    // 30일 지난 휴지통 일기장(+소속 일기·멤버) 자동 정리. 멱등.
    await _repo.purgeExpiredTrash();
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
    // cascade로 소속 일기도 함께 휴지통으로 → 일기 목록·홈 배지도 갱신.
    ref.invalidate(entriesProvider);
    state = AsyncData(await _repo.getAll());
  }

  /// 휴지통에서 복원: 일기장과 같은 cascade로 버려진 일기를 함께 되살린다.
  Future<void> restore(String journalId, DateTime when) async {
    await _repo.restore(journalId, when);
    // cascade로 일기도 함께 되살아나므로 일기 목록·홈 배지도 갱신.
    ref.invalidate(entriesProvider);
    state = AsyncData(await _repo.getAll());
  }

  /// 영구 삭제: 일기장과 소속 일기·멤버를 완전히 제거한다.
  Future<void> deleteForever(String journalId) async {
    await _repo.deleteForever(journalId);
    // 소속 일기도 완전히 사라지므로 일기 목록도 갱신.
    ref.invalidate(entriesProvider);
    state = AsyncData(await _repo.getAll());
  }
}

final journalsProvider =
    AsyncNotifierProvider<JournalsNotifier, List<Journal>>(
  JournalsNotifier.new,
);
