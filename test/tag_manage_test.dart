import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/tags/tag_manage.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _e(String id, List<String> tags) => DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'j1',
      tags: tags,
      content: 'x',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

DiaryEntry _ed(String id, List<String> tags, int day) => DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'j1',
      tags: tags,
      content: 'x',
      createdAt: DateTime(2026, 6, day),
      updatedAt: DateTime(2026, 6, day),
    );

void main() {
  group('tagCountsSorted', () {
    test('counts usage, most-used first then name asc', () {
      final entries = [
        _e('1', ['여행', '가족']),
        _e('2', ['여행']),
        _e('3', ['가족']),
        _e('4', ['일상']),
      ];
      expect(
        tagCountsSorted(entries).map((e) => '${e.key}:${e.value}').toList(),
        ['가족:2', '여행:2', '일상:1'],
      );
    });

    test('empty when no tags', () {
      expect(tagCountsSorted([_e('1', const [])]), isEmpty);
    });

    test('byName sorts alphabetically, ties by higher count', () {
      final entries = [
        _e('1', ['여행', '가족']),
        _e('2', ['여행']),
        _e('3', ['가족']),
        _e('4', ['일상']),
      ];
      expect(
        tagCountsSorted(entries, byName: true)
            .map((e) => '${e.key}:${e.value}')
            .toList(),
        ['가족:2', '여행:2', '일상:1'],
      );
    });

    test('byName orders distinct names regardless of count', () {
      final entries = [
        _e('1', ['하늘']),
        _e('2', ['하늘']),
        _e('3', ['바다']),
      ];
      expect(
        tagCountsSorted(entries, byName: true).map((e) => e.key).toList(),
        ['바다', '하늘'],
      );
    });
  });

  group('renameTagInEntries', () {
    final entries = [
      _e('1', ['여행', '가족']),
      _e('2', ['일상']),
    ];

    test('renames only affected entries, preserving order', () {
      final changed = renameTagInEntries(entries, '여행', '추억');
      expect(changed.length, 1);
      expect(changed.first.entryId, '1');
      expect(changed.first.tags, ['추억', '가족']);
    });

    test('collapses duplicates when target already present', () {
      final changed = renameTagInEntries([_e('1', ['여행', '가족'])], '여행', '가족');
      expect(changed.first.tags, ['가족']);
    });

    test('no-op for blank target or identical name', () {
      expect(renameTagInEntries(entries, '여행', '  '), isEmpty);
      expect(renameTagInEntries(entries, '여행', '여행'), isEmpty);
    });

    test('trims the target', () {
      final changed = renameTagInEntries([_e('1', ['여행'])], '여행', '  추억 ');
      expect(changed.first.tags, ['추억']);
    });
  });

  group('removeTagFromEntries', () {
    test('strips the tag from affected entries only', () {
      final entries = [
        _e('1', ['여행', '가족']),
        _e('2', ['일상']),
      ];
      final changed = removeTagFromEntries(entries, '여행');
      expect(changed.length, 1);
      expect(changed.first.entryId, '1');
      expect(changed.first.tags, ['가족']);
    });

    test('empty when tag unused', () {
      expect(removeTagFromEntries([_e('1', ['가족'])], '여행'), isEmpty);
    });
  });

  group('lastUseByTag', () {
    test('keeps the latest date each tag was used', () {
      final map = lastUseByTag([
        _ed('1', ['여행', '가족'], 3),
        _ed('2', ['여행'], 18),
        _ed('3', ['가족'], 10),
      ]);
      expect(map['여행'], DateTime(2026, 6, 18));
      expect(map['가족'], DateTime(2026, 6, 10));
    });

    test('empty when there are no tags', () {
      expect(lastUseByTag([_ed('1', const [], 5)]), isEmpty);
    });
  });
}
