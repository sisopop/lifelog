import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/journal_member.dart';
import '../auth/session.dart';
import '../entries/entries_provider.dart';
import 'members_repository.dart';

final membersRepositoryProvider = Provider<MembersRepository>((ref) {
  return MembersRepository(ref.watch(appDatabaseProvider));
});

/// Members of a single journal. Seeds the owner ("me") on first read.
final journalMembersProvider =
    FutureProvider.family<List<JournalMember>, String>((ref, journalId) async {
  final repo = ref.watch(membersRepositoryProvider);
  final myName = ref.watch(sessionProvider).name ?? '나';
  await repo.ensureOwner(journalId, myName);
  return repo.getForJournal(journalId);
});

/// Imperative actions (add partner, remove) for journal membership.
class MembersController {
  MembersController(this._ref);
  final Ref _ref;

  MembersRepository get _repo => _ref.read(membersRepositoryProvider);

  Future<void> addPartner(String journalId, String name) async {
    await _repo.addPartner(journalId, name);
    _ref.invalidate(journalMembersProvider(journalId));
  }

  Future<void> remove(String journalId, String memberId) async {
    await _repo.remove(memberId);
    _ref.invalidate(journalMembersProvider(journalId));
  }
}

final membersControllerProvider =
    Provider<MembersController>((ref) => MembersController(ref));
