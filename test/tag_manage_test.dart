import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/tags/tag_manage.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _e(String id, List<String> tags) => DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'j1',
      tags: tags,
      content: 'x',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

DiaryEntry _em(String id, List<String> tags,
        {Mood? mood, String? replyTo, String? location}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'j1',
      tags: tags,
      mood: mood,
      replyToEntryId: replyTo,
      location: location,
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

  group('tagSharePercent', () {
    test('percent of tagged records that carry the tag, rounded', () {
      final entries = [
        _e('1', ['여행', '가족']),
        _e('2', ['여행']),
        _e('3', ['여행']),
        _e('4', ['일상']),
      ];
      expect(tagSharePercent(entries, '여행'), 75); // 3/4 tagged records
      expect(tagSharePercent(entries, '가족'), 25); // 1/4
    });

    test('ignores replies and untagged records in the denominator', () {
      final entries = [
        _em('top', ['여행']),
        _em('reply', ['여행'], replyTo: 'top'),
        _e('none', const []),
      ];
      // Only the one top-level tagged record counts → 100%.
      expect(tagSharePercent(entries, '여행'), 100);
    });

    test('0 when nothing is tagged or the tag is unseen', () {
      expect(tagSharePercent(const [], '여행'), 0);
      expect(tagSharePercent([_e('a', const [])], '여행'), 0);
      expect(tagSharePercent([_e('a', ['가족'])], '여행'), 0);
    });
  });

  group('dominantMoodByTag', () {
    test('picks the most-recorded mood per tag', () {
      final map = dominantMoodByTag([
        _em('1', ['여행'], mood: Mood.good),
        _em('2', ['여행'], mood: Mood.good),
        _em('3', ['여행'], mood: Mood.hard),
        _em('4', ['가족'], mood: Mood.hard),
      ]);
      expect(map['여행'], Mood.good);
      expect(map['가족'], Mood.hard);
    });

    test('ties resolve to the earlier Mood.values', () {
      final map = dominantMoodByTag([
        _em('1', ['여행'], mood: Mood.hard),
        _em('2', ['여행'], mood: Mood.good),
      ]);
      expect(map['여행'], Mood.good);
    });

    test('excludes replies and moodless records', () {
      final map = dominantMoodByTag([
        _em('1', ['여행'], mood: Mood.good),
        _em('2', ['여행'], mood: Mood.hard, replyTo: '1'),
        _em('3', ['여행']),
      ]);
      expect(map['여행'], Mood.good);
      expect(map.length, 1);
    });

    test('omits tags with no mood-bearing records', () {
      expect(dominantMoodByTag([_em('1', ['여행'])]), isEmpty);
    });
  });

  group('dominantPlaceByTag', () {
    test('picks the most-used location per tag', () {
      final map = dominantPlaceByTag([
        _em('1', ['여행'], location: '제주'),
        _em('2', ['여행'], location: '제주'),
        _em('3', ['여행'], location: '부산'),
        _em('4', ['가족'], location: '서울'),
      ]);
      expect(map['여행'], '제주');
      expect(map['가족'], '서울');
    });

    test('groups locations case-insensitively, keeps first-seen spelling',
        () {
      final map = dominantPlaceByTag([
        _em('1', ['여행'], location: 'Jeju'),
        _em('2', ['여행'], location: 'jeju'),
      ]);
      expect(map['여행'], 'Jeju');
    });

    test('ties resolve alphabetically by location', () {
      final map = dominantPlaceByTag([
        _em('1', ['여행'], location: '제주'),
        _em('2', ['여행'], location: '부산'),
      ]);
      expect(map['여행'], '부산');
    });

    test('excludes replies and blank locations', () {
      final map = dominantPlaceByTag([
        _em('1', ['여행'], location: '제주'),
        _em('2', ['여행'], location: '부산', replyTo: '1'),
        _em('3', ['여행'], location: '  '),
      ]);
      expect(map['여행'], '제주');
      expect(map.length, 1);
    });

    test('omits tags with no located record', () {
      expect(dominantPlaceByTag([_em('1', ['여행'])]), isEmpty);
    });
  });
}
