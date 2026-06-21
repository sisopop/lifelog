import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/search/entry_search.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry({
  required String id,
  String? title,
  String content = '',
  String? summary,
  List<String> tags = const [],
  String? replyTo,
  DateTime? createdAt,
  bool favorite = false,
  String? location,
}) {
  final now = createdAt ?? DateTime(2026, 1, 1);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: 'jr_default',
    replyToEntryId: replyTo,
    title: title,
    content: content,
    aiSummary: summary,
    tags: tags,
    location: location,
    isFavorite: favorite,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('searchEntries', () {
    final entries = [
      _entry(
          id: '1',
          title: '제주 여행',
          content: '바다가 예뻤다',
          createdAt: DateTime(2026, 1, 1)),
      _entry(
          id: '2',
          content: '오늘은 가족과 저녁',
          tags: ['가족'],
          createdAt: DateTime(2026, 1, 3)),
      _entry(
          id: '3',
          content: '회사 회의',
          summary: '프로젝트 마감 논의',
          createdAt: DateTime(2026, 1, 2)),
      _entry(id: '4', content: '여행 답장', replyTo: '1'),
    ];

    test('blank query returns nothing', () {
      expect(searchEntries(entries, ''), isEmpty);
      expect(searchEntries(entries, '   '), isEmpty);
    });

    test('matches title', () {
      final r = searchEntries(entries, '제주');
      expect(r.map((e) => e.entryId), ['1']);
    });

    test('matches content', () {
      final r = searchEntries(entries, '바다');
      expect(r.map((e) => e.entryId), ['1']);
    });

    test('matches tags', () {
      final r = searchEntries(entries, '가족');
      expect(r.map((e) => e.entryId), ['2']);
    });

    test('matches AI summary', () {
      final r = searchEntries(entries, '마감');
      expect(r.map((e) => e.entryId), ['3']);
    });

    test('matches location', () {
      final located = [
        _entry(id: 'p', content: '맛있었다', location: '성산일출봉'),
        _entry(id: 'q', content: '평범한 하루'),
      ];
      expect(searchEntries(located, '성산').map((e) => e.entryId), ['p']);
    });

    test('is case-insensitive', () {
      final mixed = [_entry(id: 'x', content: 'Hello World')];
      expect(searchEntries(mixed, 'WORLD').map((e) => e.entryId), ['x']);
    });

    test('excludes replies', () {
      // "여행" appears in entry 1 (title) and entry 4 (reply content);
      // only the top-level entry should be returned.
      final r = searchEntries(entries, '여행');
      expect(r.map((e) => e.entryId), ['1']);
    });

    test('sorts results newest-first', () {
      final r = searchEntries(entries, '');
      expect(r, isEmpty);
      final all = searchEntries(entries, ''); // blank → empty
      expect(all, isEmpty);
      // multi-match ordering
      final multi = [
        _entry(id: 'a', content: '산책', createdAt: DateTime(2026, 1, 1)),
        _entry(id: 'b', content: '산책', createdAt: DateTime(2026, 1, 5)),
        _entry(id: 'c', content: '산책', createdAt: DateTime(2026, 1, 3)),
      ];
      expect(searchEntries(multi, '산책').map((e) => e.entryId), ['b', 'c', 'a']);
    });
  });

  group('filterByFavorite', () {
    final entries = [
      _entry(id: '1', content: 'a', favorite: true),
      _entry(id: '2', content: 'b'),
      _entry(id: '3', content: 'c', favorite: true),
    ];

    test('false returns the list unchanged', () {
      expect(filterByFavorite(entries, false).map((e) => e.entryId),
          ['1', '2', '3']);
    });

    test('true keeps only starred entries', () {
      expect(
          filterByFavorite(entries, true).map((e) => e.entryId), ['1', '3']);
    });

    test('true with no favorites is empty', () {
      expect(filterByFavorite([_entry(id: 'x', content: 'x')], true), isEmpty);
    });
  });

  group('sortSearchResults', () {
    final entries = [
      _entry(id: 'mid', content: 'x', createdAt: DateTime(2026, 6, 10)),
      _entry(id: 'old', content: 'x', createdAt: DateTime(2026, 6, 1)),
      _entry(id: 'new', content: 'x', createdAt: DateTime(2026, 6, 20)),
    ];

    test('defaults to newest-first', () {
      expect(sortSearchResults(entries).map((e) => e.entryId),
          ['new', 'mid', 'old']);
    });

    test('ascending gives oldest-first', () {
      expect(sortSearchResults(entries, ascending: true).map((e) => e.entryId),
          ['old', 'mid', 'new']);
    });

    test('does not mutate the input list', () {
      final before = entries.map((e) => e.entryId).toList();
      sortSearchResults(entries, ascending: true);
      expect(entries.map((e) => e.entryId).toList(), before);
    });
  });
}
