import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/journal_member.dart';
import '../entries/entries_provider.dart';
import '../journals/members_provider.dart';

/// A person you share journals with (aggregated across all shared journals).
class Person {
  const Person({
    required this.name,
    required this.journalCount,
    required this.entryCount,
  });

  final String name;

  /// Number of distinct journals shared with this person.
  final int journalCount;

  /// Number of top-level entries authored by this person.
  final int entryCount;
}

/// Aggregates partner members (excluding "me") into a per-person summary.
///
/// People are grouped by display name; their journal and entry counts are
/// derived from membership and entry authorship. Sorted by entry count
/// (desc), then journal count (desc), then name.
List<Person> aggregatePeople(
  List<JournalMember> members,
  List<DiaryEntry> entries,
) {
  // name -> (journalIds, userIds)
  final byName = <String, ({Set<String> journals, Set<String> users})>{};
  for (final m in members) {
    if (m.isMe) continue;
    final g = byName.putIfAbsent(
      m.displayName,
      () => (journals: <String>{}, users: <String>{}),
    );
    g.journals.add(m.journalId);
    g.users.add(m.userId);
  }
  if (byName.isEmpty) return const [];

  final people = byName.entries.map((e) {
    final userIds = e.value.users;
    final entryCount = entries
        .where((d) => d.replyToEntryId == null && userIds.contains(d.userId))
        .length;
    return Person(
      name: e.key,
      journalCount: e.value.journals.length,
      entryCount: entryCount,
    );
  }).toList()
    ..sort((a, b) {
      final byEntries = b.entryCount.compareTo(a.entryCount);
      if (byEntries != 0) return byEntries;
      final byJournals = b.journalCount.compareTo(a.journalCount);
      if (byJournals != 0) return byJournals;
      return a.name.compareTo(b.name);
    });
  return people;
}

/// All journal members across the app (seeded owners + added partners).
final allMembersProvider = FutureProvider<List<JournalMember>>((ref) async {
  // Refresh when entries change (new shared journals may add members).
  ref.watch(entriesProvider);
  return ref.watch(membersRepositoryProvider).getAll();
});

/// People you share journals with, aggregated for the 사람 screen.
final peopleProvider = Provider<List<Person>>((ref) {
  final members =
      ref.watch(allMembersProvider).asData?.value ?? const <JournalMember>[];
  final entries =
      ref.watch(entriesProvider).asData?.value ?? const <DiaryEntry>[];
  return aggregatePeople(members, entries);
});
