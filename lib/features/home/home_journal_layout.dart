import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/session.dart';

const _kHomeJournalLayoutKey = 'home_journal_layout';

/// How the journal list is laid out on the home screen.
enum HomeJournalLayout {
  /// Full-width horizontal cards, one per row.
  card('카드 (가로형)', 0),

  /// Book covers, two per row.
  grid2('2개씩', 2),

  /// Book covers, three per row.
  grid3('3개씩', 3),

  /// App-icon style, four per row with the title below the cover.
  grid4('4개씩 (앱 아이콘)', 4);

  const HomeJournalLayout(this.label, this.crossAxisCount);

  /// Human-readable label for the picker.
  final String label;

  /// Columns in the grid; 0 means the single-column card list.
  final int crossAxisCount;
}

/// Default layout when nothing has been chosen yet.
const defaultHomeJournalLayout = HomeJournalLayout.grid2;

/// Pure: resolve a stored enum name to a layout, falling back to the default
/// for null or unrecognized values.
HomeJournalLayout homeJournalLayoutFromName(String? name) {
  for (final l in HomeJournalLayout.values) {
    if (l.name == name) return l;
  }
  return defaultHomeJournalLayout;
}

/// The chosen home journal layout, persisted across launches.
class HomeJournalLayoutNotifier extends Notifier<HomeJournalLayout> {
  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  HomeJournalLayout build() =>
      homeJournalLayoutFromName(_p.getString(_kHomeJournalLayoutKey));

  Future<void> set(HomeJournalLayout layout) async {
    state = layout;
    await _p.setString(_kHomeJournalLayoutKey, layout.name);
  }
}

final homeJournalLayoutProvider =
    NotifierProvider<HomeJournalLayoutNotifier, HomeJournalLayout>(
        HomeJournalLayoutNotifier.new);
