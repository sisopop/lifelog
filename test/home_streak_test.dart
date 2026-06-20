import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifelog/features/entries/entries_provider.dart';
import 'package:lifelog/features/stats/streak.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

class _FakeEntries extends EntriesNotifier {
  _FakeEntries(this._items);
  final List<DiaryEntry> _items;
  @override
  Future<List<DiaryEntry>> build() async => _items;
}

DiaryEntry _entry(DateTime at, {String? replyTo}) => DiaryEntry(
      entryId: 'e${at.millisecondsSinceEpoch}$replyTo',
      userId: 'me',
      journalId: 'jr_default',
      content: 'c',
      tags: const [],
      replyToEntryId: replyTo,
      createdAt: at,
      updatedAt: at,
    );

Future<int> _streak(List<DiaryEntry> items) async {
  final c = ProviderContainer(
    overrides: [entriesProvider.overrideWith(() => _FakeEntries(items))],
  );
  addTearDown(c.dispose);
  await c.read(entriesProvider.future);
  return c.read(homeStreakProvider);
}

void main() {
  test('counts today + yesterday as a 2-day streak', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final n = await _streak([
      _entry(today),
      _entry(today.subtract(const Duration(days: 1))),
    ]);
    expect(n, 2);
  });

  test('no record today or yesterday → 0', () async {
    final old = DateTime.now().subtract(const Duration(days: 10));
    final n = await _streak([_entry(old)]);
    expect(n, 0);
  });

  test('replies do not extend the streak', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final n = await _streak([
      _entry(today),
      _entry(today.subtract(const Duration(days: 1)), replyTo: 'x'),
    ]);
    expect(n, 1);
  });
}
