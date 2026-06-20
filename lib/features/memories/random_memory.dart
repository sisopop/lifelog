import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/diary_entry.dart';
import '../entries/entries_provider.dart';

/// "다시 꺼내보기" / Resurface — top-level entries written *before* today,
/// so we can resurface a past record to revisit. Newest first for a stable
/// order. Unlike 그날의 추억 this works even within a single year of data.
List<DiaryEntry> resurfaceableEntries(
    List<DiaryEntry> entries, DateTime today) {
  final start = DateTime(today.year, today.month, today.day);
  return entries
      .where((e) => e.replyToEntryId == null && e.createdAt.isBefore(start))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

/// Picks one past entry deterministically from [seed]. Returns null when there
/// is nothing to resurface. The same seed always yields the same entry, which
/// keeps the UI stable across rebuilds and makes the logic testable.
DiaryEntry? pickRandomMemory(
    List<DiaryEntry> entries, DateTime today, int seed) {
  final pool = resurfaceableEntries(entries, today);
  if (pool.isEmpty) return null;
  return pool[seed.abs() % pool.length];
}

/// A seed that the user can bump (shuffle) to draw a different memory.
class RandomMemorySeedNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void shuffle() => state = state + 1;
}

final randomMemorySeedProvider =
    NotifierProvider<RandomMemorySeedNotifier, int>(
        RandomMemorySeedNotifier.new);

/// The currently-surfaced past entry (null when there's nothing to show).
final randomMemoryProvider = Provider<DiaryEntry?>((ref) {
  final entries = ref.watch(entriesProvider).asData?.value ?? const [];
  final seed = ref.watch(randomMemorySeedProvider);
  return pickRandomMemory(entries, DateTime.now(), seed);
});
