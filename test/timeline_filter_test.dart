import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/timeline/timeline_filter.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _e({
  required String id,
  Mood? mood,
  List<String> tags = const [],
  String? replyTo,
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'j1',
      replyToEntryId: replyTo,
      mood: mood,
      tags: tags,
      content: 'x',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
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

  group('TimelineFilter.copyWith', () {
    test('clear flags reset axes', () {
      const f = TimelineFilter(mood: Mood.good, tag: '여행');
      expect(f.copyWith(clearMood: true).mood, isNull);
      expect(f.copyWith(clearTag: true).tag, isNull);
      expect(f.isActive, isTrue);
      expect(const TimelineFilter().isActive, isFalse);
    });
  });
}
