import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/entries/summary_guard.dart';

void main() {
  group('canApplyAiSummary', () {
    final snapshot = DateTime(2026, 6, 14, 9, 0);

    test('applies when current updatedAt matches the snapshot (no edit since)', () {
      expect(
        canApplyAiSummary(
          snapshotUpdatedAt: snapshot,
          currentUpdatedAt: snapshot,
          currentDeletedAt: null,
        ),
        isTrue,
      );
    });

    test('rejects when the entry was edited while summarizing', () {
      expect(
        canApplyAiSummary(
          snapshotUpdatedAt: snapshot,
          currentUpdatedAt: snapshot.add(const Duration(minutes: 1)),
          currentDeletedAt: null,
        ),
        isFalse,
      );
    });

    test('rejects when the entry was moved to trash while summarizing', () {
      expect(
        canApplyAiSummary(
          snapshotUpdatedAt: snapshot,
          currentUpdatedAt: snapshot,
          currentDeletedAt: DateTime(2026, 6, 14, 9, 5),
        ),
        isFalse,
      );
    });

    test('rejects when the entry was permanently deleted (row gone)', () {
      expect(
        canApplyAiSummary(
          snapshotUpdatedAt: snapshot,
          currentUpdatedAt: null,
          currentDeletedAt: null,
        ),
        isFalse,
      );
    });
  });
}
