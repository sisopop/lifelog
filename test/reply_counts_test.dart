import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/features/timeline/timeline_filter.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry(String id, {String? replyTo}) {
  final ts = DateTime(2026, 6, 1);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: 'jr_default',
    replyToEntryId: replyTo,
    content: id,
    createdAt: ts,
    updatedAt: ts,
  );
}

void main() {
  group('replyCountsByParent', () {
    test('tallies replies per parent, omitting parents with none', () {
      final entries = [
        _entry('a'),
        _entry('b'),
        _entry('r1', replyTo: 'a'),
        _entry('r2', replyTo: 'a'),
        _entry('r3', replyTo: 'b'),
      ];
      final counts = replyCountsByParent(entries);
      expect(counts['a'], 2);
      expect(counts['b'], 1);
      expect(counts.containsKey('r1'), isFalse);
    });

    test('empty list yields empty map', () {
      expect(replyCountsByParent(const []), isEmpty);
    });

    test('no replies yields empty map', () {
      expect(replyCountsByParent([_entry('a'), _entry('b')]), isEmpty);
    });
  });
}
