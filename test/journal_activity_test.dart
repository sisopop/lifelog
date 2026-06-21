import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/home/journal_activity.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _e({
  required String id,
  required DateTime at,
  String journalId = 'j1',
  String? replyTo,
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: journalId,
      replyToEntryId: replyTo,
      content: 'x',
      createdAt: at,
      updatedAt: at,
    );

void main() {
  group('lastEntryDate', () {
    final entries = [
      _e(id: '1', at: DateTime(2026, 6, 1), journalId: 'j1'),
      _e(id: '2', at: DateTime(2026, 6, 20), journalId: 'j1'),
      _e(id: '3', at: DateTime(2026, 6, 25), journalId: 'j1', replyTo: '2'),
      _e(id: '4', at: DateTime(2026, 6, 30), journalId: 'j2'),
    ];

    test('returns the newest top-level entry date for the journal', () {
      expect(lastEntryDate(entries, 'j1'), DateTime(2026, 6, 20));
    });

    test('ignores replies even if newer', () {
      // #3 (6/25) is a reply, so 6/20 still wins for j1.
      expect(lastEntryDate(entries, 'j1'), DateTime(2026, 6, 20));
    });

    test('scopes to the requested journal', () {
      expect(lastEntryDate(entries, 'j2'), DateTime(2026, 6, 30));
    });

    test('null when the journal has no entries', () {
      expect(lastEntryDate(entries, 'ghost'), isNull);
      expect(lastEntryDate(const [], 'j1'), isNull);
    });
  });

  group('relativeDayLabel', () {
    final now = DateTime(2026, 6, 21, 15);

    test('today and future read as 오늘', () {
      expect(relativeDayLabel(DateTime(2026, 6, 21, 8), now), '오늘');
      expect(relativeDayLabel(DateTime(2026, 6, 22), now), '오늘');
    });

    test('yesterday', () {
      expect(relativeDayLabel(DateTime(2026, 6, 20), now), '어제');
    });

    test('within a week is N일 전', () {
      expect(relativeDayLabel(DateTime(2026, 6, 18), now), '3일 전');
    });

    test('weeks, months and years', () {
      expect(relativeDayLabel(DateTime(2026, 6, 7), now), '2주 전'); // 14d
      expect(relativeDayLabel(DateTime(2026, 4, 21), now), '2개월 전'); // ~61d
      expect(relativeDayLabel(DateTime(2024, 6, 21), now), '2년 전');
    });
  });
}
