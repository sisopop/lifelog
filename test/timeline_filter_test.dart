import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/timeline/timeline_filter.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _e({
  required String id,
  Mood? mood,
  List<String> tags = const [],
  String? replyTo,
  DateTime? created,
  bool favorite = false,
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'j1',
      replyToEntryId: replyTo,
      mood: mood,
      tags: tags,
      content: 'x',
      isFavorite: favorite,
      createdAt: created ?? DateTime(2026, 1, 1),
      updatedAt: created ?? DateTime(2026, 1, 1),
    );

void main() {
  final entries = [
    _e(id: '1', mood: Mood.good, tags: ['여행', '가족']),
    _e(id: '2', mood: Mood.hard, tags: ['일']),
    _e(id: '3', mood: Mood.good, tags: ['여행']),
    _e(id: '4', mood: Mood.good, tags: ['여행'], replyTo: '1'),
  ];

  group('filterEntries', () {
    test('no filter returns all top-level entries', () {
      final r = filterEntries(entries, const TimelineFilter());
      expect(r.map((e) => e.entryId), ['1', '2', '3']);
    });

    test('filters by mood', () {
      final r = filterEntries(entries, const TimelineFilter(mood: Mood.good));
      expect(r.map((e) => e.entryId), ['1', '3']);
    });

    test('filters by tag', () {
      final r = filterEntries(entries, const TimelineFilter(tag: '여행'));
      expect(r.map((e) => e.entryId), ['1', '3']);
    });

    test('combines mood and tag (AND)', () {
      final r = filterEntries(
          entries, const TimelineFilter(mood: Mood.hard, tag: '여행'));
      expect(r, isEmpty);
    });

    test('always excludes replies', () {
      final r = filterEntries(entries, const TimelineFilter(tag: '여행'));
      expect(r.any((e) => e.entryId == '4'), isFalse);
    });

    test('filters by favorite', () {
      final favs = [
        _e(id: 'a', favorite: true),
        _e(id: 'b'),
        _e(id: 'c', favorite: true),
      ];
      final r = filterEntries(favs, const TimelineFilter(favorite: true));
      expect(r.map((e) => e.entryId), ['a', 'c']);
    });

    test('favorite combines with tag (AND)', () {
      final favs = [
        _e(id: 'a', tags: ['여행'], favorite: true),
        _e(id: 'b', tags: ['여행']),
        _e(id: 'c', favorite: true),
      ];
      final r = filterEntries(
          favs, const TimelineFilter(tag: '여행', favorite: true));
      expect(r.map((e) => e.entryId), ['a']);
    });

    test('favorite is part of isActive', () {
      expect(const TimelineFilter(favorite: true).isActive, isTrue);
      expect(const TimelineFilter().isActive, isFalse);
    });
  });

  group('availableTags', () {
    test('returns distinct tags ordered by usage', () {
      // 여행 appears in 2 top-level entries, 가족 & 일 once each
      expect(availableTags(entries), ['여행', '가족', '일']);
    });

    test('ignores reply tags', () {
      final only = [
        _e(id: 'a', tags: ['x']),
        _e(id: 'b', tags: ['secret'], replyTo: 'a'),
      ];
      expect(availableTags(only), ['x']);
    });
  });

  group('sortByDate', () {
    final dated = [
      _e(id: 'mid', created: DateTime(2026, 6, 10)),
      _e(id: 'old', created: DateTime(2026, 6, 1)),
      _e(id: 'new', created: DateTime(2026, 6, 20)),
    ];

    test('defaults to newest-first', () {
      expect(sortByDate(dated).map((e) => e.entryId), ['new', 'mid', 'old']);
    });

    test('ascending gives oldest-first', () {
      expect(sortByDate(dated, ascending: true).map((e) => e.entryId),
          ['old', 'mid', 'new']);
    });

    test('does not mutate the input list', () {
      final before = dated.map((e) => e.entryId).toList();
      sortByDate(dated, ascending: true);
      expect(dated.map((e) => e.entryId).toList(), before);
    });
  });

  group('TimelineFilter.copyWith', () {
    test('clear flags reset axes', () {
      const f = TimelineFilter(mood: Mood.good, tag: '여행');
      expect(f.copyWith(clearMood: true).mood, isNull);
      expect(f.copyWith(clearTag: true).tag, isNull);
      expect(f.isActive, isTrue);
      expect(const TimelineFilter().isActive, isFalse);
    });

    test('a non-all period counts as active', () {
      expect(const TimelineFilter(period: DatePreset.month).isActive, isTrue);
      expect(const TimelineFilter(period: DatePreset.all).isActive, isFalse);
    });
  });

  group('filterByPeriod', () {
    // now = Wed 2026-06-17. Week (Mon-start) begins 2026-06-15.
    final now = DateTime(2026, 6, 17, 12);
    final dated = [
      _e(id: 'lastYear', created: DateTime(2025, 12, 31)),
      _e(id: 'lastMonth', created: DateTime(2026, 5, 20)),
      _e(id: 'thisMonthOld', created: DateTime(2026, 6, 2)),
      _e(id: 'thisWeek', created: DateTime(2026, 6, 16)),
      _e(id: 'today', created: DateTime(2026, 6, 17, 9)),
    ];

    test('all returns everything unchanged', () {
      expect(filterByPeriod(dated, DatePreset.all, now).length, 5);
    });

    test('week keeps Monday-onward entries', () {
      expect(filterByPeriod(dated, DatePreset.week, now).map((e) => e.entryId),
          ['thisWeek', 'today']);
    });

    test('month keeps the current calendar month', () {
      expect(filterByPeriod(dated, DatePreset.month, now).map((e) => e.entryId),
          ['thisMonthOld', 'thisWeek', 'today']);
    });

    test('year keeps the current calendar year', () {
      expect(filterByPeriod(dated, DatePreset.year, now).map((e) => e.entryId),
          ['lastMonth', 'thisMonthOld', 'thisWeek', 'today']);
    });

    test('does not mutate the input list', () {
      final before = dated.length;
      filterByPeriod(dated, DatePreset.week, now);
      expect(dated.length, before);
    });
  });
}
