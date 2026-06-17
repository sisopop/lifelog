import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/journal_member.dart';
import '../auth/session.dart';
import '../entries/entries_provider.dart';
import 'members_provider.dart';

/// 교환일기에서 상대가 이 시간 동안 안 쓰면 "이어쓰기 / 차례 넘기기"가 열린다.
/// (데모용으로 짧게 잡음 — 실제 서비스에선 24~48h 권장)
const exchangeTurnTimeout = Duration(hours: 6);

String _turnKey(String journalId) => 'turn_$journalId';

/// 교환일기 차례 정보. 단일 기기 로컬 모의이므로 한 기기에서 양쪽을
/// 번갈아 "연기"한다. holder = 지금 기록할 차례인 멤버.
class ExchangeTurn {
  const ExchangeTurn({
    this.holder,
    this.isMyTurn = true,
    this.overdue = false,
    this.previousAuthorId,
    this.lastEntryAt,
  });

  final JournalMember? holder;
  final bool isMyTurn;
  final bool overdue;
  final String? previousAuthorId;
  final DateTime? lastEntryAt;
}

/// Members ordered by join time = fixed turn rotation order.
List<JournalMember> _ordered(List<JournalMember> members) =>
    [...members]..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

/// Computes the current turn for an exchange journal from its members,
/// the last top-level entry, and the persisted turn holder.
final exchangeTurnProvider =
    Provider.family<ExchangeTurn, String>((ref, journalId) {
  final members =
      ref.watch(journalMembersProvider(journalId)).asData?.value ??
          const <JournalMember>[];
  final ordered = _ordered(members);
  if (ordered.isEmpty) return const ExchangeTurn();

  final entries = (ref.watch(entriesProvider).asData?.value ?? const [])
      .where((e) => e.journalId == journalId && e.replyToEntryId == null)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final last = entries.isEmpty ? null : entries.last;

  final storedId = ref.watch(sharedPrefsProvider).getString(_turnKey(journalId));
  final holder = ordered.firstWhere(
    (m) => m.userId == storedId,
    orElse: () => ordered.first,
  );

  final overdue = last != null &&
      DateTime.now().difference(last.createdAt) > exchangeTurnTimeout;

  return ExchangeTurn(
    holder: holder,
    isMyTurn: holder.isMe,
    overdue: overdue,
    previousAuthorId: last?.userId,
    lastEntryAt: last?.createdAt,
  );
});

/// Mutates the persisted turn holder (advance after a write, or manual skip).
class ExchangeTurnController {
  ExchangeTurnController(this._ref);
  final Ref _ref;

  SharedPreferences get _p => _ref.read(sharedPrefsProvider);

  /// Move the turn to the next member in rotation. Used after a normal
  /// exchange write and for "차례 넘기기".
  Future<void> advance(String journalId) async {
    final members =
        await _ref.read(journalMembersProvider(journalId).future);
    final ordered = _ordered(members);
    if (ordered.isEmpty) return;
    final currentId =
        _p.getString(_turnKey(journalId)) ?? ordered.first.userId;
    final idx = ordered.indexWhere((m) => m.userId == currentId);
    final next = ordered[(idx + 1) % ordered.length];
    await _p.setString(_turnKey(journalId), next.userId);
    _ref.invalidate(exchangeTurnProvider(journalId));
  }

  Future<void> setHolder(String journalId, String userId) async {
    await _p.setString(_turnKey(journalId), userId);
    _ref.invalidate(exchangeTurnProvider(journalId));
  }
}

final exchangeTurnControllerProvider =
    Provider<ExchangeTurnController>((ref) => ExchangeTurnController(ref));
