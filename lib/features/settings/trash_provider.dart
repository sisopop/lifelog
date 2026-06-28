import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/journal.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';

/// Everything currently sitting in the 휴지통 — soft-deleted journals and
/// entries, each newest-deletion-first.
class TrashContents {
  const TrashContents({required this.journals, required this.entries});
  final List<Journal> journals;
  final List<DiaryEntry> entries;

  bool get isEmpty => journals.isEmpty && entries.isEmpty;
  int get total => journals.length + entries.length;
}

/// Loads the trash. Re-reads whenever the live journals/entries change, so a
/// restore or permanent delete refreshes this list automatically.
final trashProvider = FutureProvider<TrashContents>((ref) async {
  ref.watch(journalsProvider);
  ref.watch(entriesProvider);
  final journals = await ref.watch(journalRepositoryProvider).getTrashed();
  final entries = await ref.watch(diaryRepositoryProvider).getTrashed();
  return TrashContents(journals: journals, entries: entries);
});
