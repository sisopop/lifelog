import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/journal_member.dart';

/// Bridges the `JournalMember` domain model and the Drift cache.
/// Local-only mock of the relationship/invite flow (see PRD.md §5/§8).
class MembersRepository {
  MembersRepository(this._db);

  final AppDatabase _db;

  /// Local device user id.
  static const meUserId = 'me';

  Future<List<JournalMember>> getForJournal(String journalId) async {
    final rows = await _db.getMembers(journalId);
    return rows.map(_toDomain).toList();
  }

  Future<void> save(JournalMember member) {
    return _db.upsertMember(_toCompanion(member));
  }

  Future<void> remove(String memberId) => _db.deleteMember(memberId);

  /// Ensures the journal owner ("me") is recorded as a member.
  Future<void> ensureOwner(String journalId, String myName) async {
    final existing = await _db.getMembers(journalId);
    if (existing.any((m) => m.isMe)) return;
    await save(
      JournalMember(
        memberId: 'mb_${journalId}_me',
        journalId: journalId,
        userId: meUserId,
        displayName: myName,
        role: MemberRole.owner,
        isMe: true,
        joinedAt: DateTime.now(),
      ),
    );
  }

  /// Mock invite acceptance: adds a partner member on this device so the
  /// shared-journal experience (author distinction) can be demoed locally.
  Future<void> addPartner(String journalId, String name) async {
    final now = DateTime.now();
    await save(
      JournalMember(
        memberId: 'mb_${now.microsecondsSinceEpoch}',
        journalId: journalId,
        userId: 'partner_${now.microsecondsSinceEpoch}',
        displayName: name,
        role: MemberRole.partner,
        joinedAt: now,
      ),
    );
  }

  JournalMember _toDomain(JournalMemberRow r) => JournalMember(
        memberId: r.memberId,
        journalId: r.journalId,
        userId: r.userId,
        displayName: r.displayName,
        role: r.role,
        isMe: r.isMe,
        joinedAt: r.joinedAt,
      );

  JournalMembersCompanion _toCompanion(JournalMember m) =>
      JournalMembersCompanion(
        memberId: Value(m.memberId),
        journalId: Value(m.journalId),
        userId: Value(m.userId),
        displayName: Value(m.displayName),
        role: Value(m.role),
        isMe: Value(m.isMe),
        joinedAt: Value(m.joinedAt),
      );
}
