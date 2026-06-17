import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/journals/turn_provider.dart';
import 'package:lifelog/shared/models/enums.dart';
import 'package:lifelog/shared/models/journal_member.dart';

JournalMember _m(String userId, int joinOrder, {bool isMe = false}) =>
    JournalMember(
      memberId: 'mb_$userId',
      journalId: 'j1',
      userId: userId,
      displayName: userId,
      role: isMe ? MemberRole.owner : MemberRole.partner,
      isMe: isMe,
      joinedAt: DateTime(2026, 1, 1).add(Duration(hours: joinOrder)),
    );

void main() {
  group('orderedTurnMembers', () {
    test('sorts by join time ascending', () {
      final ordered =
          orderedTurnMembers([_m('b', 2), _m('a', 1), _m('c', 3)]);
      expect(ordered.map((m) => m.userId), ['a', 'b', 'c']);
    });
  });

  group('resolveHolder', () {
    final ordered = [_m('me', 1, isMe: true), _m('partner', 2)];

    test('returns stored member', () {
      expect(resolveHolder(ordered, 'partner').userId, 'partner');
    });

    test('falls back to first when id unknown or null', () {
      expect(resolveHolder(ordered, 'ghost').userId, 'me');
      expect(resolveHolder(ordered, null).userId, 'me');
    });
  });

  group('nextHolderId', () {
    final ordered = [_m('me', 1, isMe: true), _m('partner', 2)];

    test('rotates to the next member', () {
      expect(nextHolderId(ordered, 'me'), 'partner');
      expect(nextHolderId(ordered, 'partner'), 'me');
    });

    test('null current starts from the first, advances to second', () {
      expect(nextHolderId(ordered, null), 'partner');
    });

    test('empty members returns null', () {
      expect(nextHolderId(const [], 'me'), isNull);
    });

    test('unknown current id wraps from index 0', () {
      // indexWhere returns -1, (-1 + 1) % len == 0 → first member
      expect(nextHolderId(ordered, 'ghost'), 'me');
    });
  });

  group('isTurnOverdue', () {
    final now = DateTime(2026, 1, 10, 12);

    test('null last entry is never overdue', () {
      expect(isTurnOverdue(null, now), isFalse);
    });

    test('within timeout is not overdue', () {
      expect(isTurnOverdue(now.subtract(const Duration(hours: 5)), now),
          isFalse);
    });

    test('beyond timeout is overdue', () {
      expect(
          isTurnOverdue(now.subtract(const Duration(hours: 7)), now), isTrue);
    });
  });
}
