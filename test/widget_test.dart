import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:lifelog/features/home/home_screen.dart';
import 'package:lifelog/features/entries/entries_provider.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

/// Avoids touching the Drift database in a pure widget test.
class _FakeEntriesNotifier extends EntriesNotifier {
  @override
  Future<List<DiaryEntry>> build() async => const [];
}

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  testWidgets('Home renders the AI prompt card', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entriesProvider.overrideWith(_FakeEntriesNotifier.new),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('오늘 가장 기억하고 싶은 순간은?'), findsOneWidget);
  });
}
