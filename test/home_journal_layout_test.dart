import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/home/home_journal_layout.dart';

void main() {
  group('homeJournalLayoutFromName', () {
    test('null falls back to the default layout', () {
      expect(homeJournalLayoutFromName(null), defaultHomeJournalLayout);
    });

    test('unknown name falls back to the default layout', () {
      expect(homeJournalLayoutFromName('nope'), defaultHomeJournalLayout);
    });

    test('each enum name round-trips to its value', () {
      for (final l in HomeJournalLayout.values) {
        expect(homeJournalLayoutFromName(l.name), l);
      }
    });

    test('crossAxisCount matches the layout (0 for the card list)', () {
      expect(HomeJournalLayout.card.crossAxisCount, 0);
      expect(HomeJournalLayout.grid2.crossAxisCount, 2);
      expect(HomeJournalLayout.grid3.crossAxisCount, 3);
      expect(HomeJournalLayout.grid4.crossAxisCount, 4);
    });
  });
}
