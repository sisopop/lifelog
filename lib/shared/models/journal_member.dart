import 'enums.dart';

/// A participant in a shared journal (커플/교환). Personal journals have a
/// single owner member. See PRD.md §5/§6 (관계/공동 공간).
class JournalMember {
  const JournalMember({
    required this.memberId,
    required this.journalId,
    required this.userId,
    required this.displayName,
    this.role = MemberRole.partner,
    this.isMe = false,
    required this.joinedAt,
  });

  final String memberId;
  final String journalId;
  final String userId;
  final String displayName;
  final MemberRole role;

  /// True for the local device user (used for "나" labels / author distinction).
  final bool isMe;
  final DateTime joinedAt;
}
