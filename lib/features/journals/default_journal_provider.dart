import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/enums.dart';
import '../../shared/models/journal.dart';
import '../auth/session.dart';
import 'journal_repository.dart';
import 'journals_provider.dart';
import 'turn_provider.dart';

const _kDefaultJournalKey = 'default_journal_id';

/// The journal the bottom (+) quick-write button targets.
/// Persisted in SharedPreferences; falls back to the default personal journal.
class DefaultJournalNotifier extends Notifier<String> {
  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  String build() =>
      _p.getString(_kDefaultJournalKey) ?? JournalRepository.defaultJournalId;

  Future<void> set(String journalId) async {
    await _p.setString(_kDefaultJournalKey, journalId);
    state = journalId;
  }
}

final defaultJournalProvider =
    NotifierProvider<DefaultJournalNotifier, String>(
  DefaultJournalNotifier.new,
);

/// Builds the `/write` route for [journalId], applying exchange-turn
/// semantics. If the journal is missing or archived, falls back to the
/// default personal journal.
String writeRouteForJournal(WidgetRef ref, String journalId) {
  final journals =
      ref.read(journalsProvider).asData?.value ?? const <Journal>[];
  var journal = journals.where((j) => j.journalId == journalId).firstOrNull;
  if (journal == null || journal.isArchived) {
    journalId = JournalRepository.defaultJournalId;
    journal = journals.where((j) => j.journalId == journalId).firstOrNull;
  }
  if (journal?.type == JournalType.exchange) {
    final holder = ref.read(exchangeTurnProvider(journalId)).holder;
    if (holder != null) {
      return '/write?journalId=$journalId&authorId=${holder.userId}&advance=1';
    }
  }
  return '/write?journalId=$journalId';
}
