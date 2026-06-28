import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/features/settings/trash_retention.dart';

void main() {
  group('daysUntilPurge', () {
    final now = DateTime(2026, 6, 30, 12);

    test('just trashed → full retention window', () {
      expect(daysUntilPurge(now, now), trashRetentionDays);
    });

    test('trashed 5 days ago → 25 days left', () {
      expect(daysUntilPurge(now.subtract(const Duration(days: 5)), now), 25);
    });

    test('exactly 30 days ago → 0 (about to be purged)', () {
      expect(daysUntilPurge(now.subtract(const Duration(days: 30)), now), 0);
    });

    test('past the window never goes negative', () {
      expect(daysUntilPurge(now.subtract(const Duration(days: 45)), now), 0);
    });

    test('future deletedAt (clock skew) is clamped to the window', () {
      expect(daysUntilPurge(now.add(const Duration(days: 3)), now),
          trashRetentionDays);
    });
  });

  group('trashRetentionLabel', () {
    final now = DateTime(2026, 6, 30, 12);

    test('shows remaining days', () {
      expect(trashRetentionLabel(now.subtract(const Duration(days: 2)), now),
          '28일 후 삭제');
    });

    test('shows "곧 삭제돼요" at zero', () {
      expect(trashRetentionLabel(now.subtract(const Duration(days: 31)), now),
          '곧 삭제돼요');
    });
  });
}
