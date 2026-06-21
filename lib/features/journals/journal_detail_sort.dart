import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Toggles a single journal's timeline between newest-first (false) and
/// oldest-first. Kept separate from the global 기록 timeline sort so each
/// surface remembers its own order.
class JournalDetailSortNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final journalDetailSortProvider =
    NotifierProvider<JournalDetailSortNotifier, bool>(
        JournalDetailSortNotifier.new);
