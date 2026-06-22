import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lifelog/features/auth/session.dart';
import 'package:lifelog/features/entries/entries_provider.dart';
import 'package:lifelog/features/home/home_screen.dart';
import 'package:lifelog/features/journals/journals_provider.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';
import 'package:lifelog/shared/models/journal.dart';

/// Avoids touching the Drift database in a pure widget test.
class _FakeJournalsNotifier extends JournalsNotifier {
  @override
  Future<List<Journal>> build() async => [
        Journal(
          journalId: 'jr_default',
          ownerId: 'me',
          type: JournalType.personal,
          title: '나의 일기장',
          createdAt: DateTime(2026, 6, 1),
        ),
      ];
}

/// Empty entries so OnThisDaySection renders nothing without hitting Drift.
class _FakeEntriesNotifier extends EntriesNotifier {
  @override
  Future<List<DiaryEntry>> build() async => const [];
}

void main() {
  setUpAll(() => initializeDateFormatting());

  testWidgets('Home lists journals and the new-journal action', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          journalsProvider.overrideWith(_FakeJournalsNotifier.new),
          journalEntryCountsProvider.overrideWith((ref) async => {'jr_default': 3}),
          entriesProvider.overrideWith(_FakeEntriesNotifier.new),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    // With journals present, the big CTA card is replaced by a compact
    // header action (tooltip), and the journal list is shown.
    expect(find.text('새 일기장 만들기'), findsNothing);
    expect(find.byTooltip('새 일기장'), findsOneWidget);
    expect(find.text('나의 일기장'), findsOneWidget);
  });
}
