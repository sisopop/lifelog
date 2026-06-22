import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/stats/stats_provider.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry({
  required String id,
  required int month,
  required int day,
  List<String> tags = const [],
  String? replyTo,
}) {
  final t = DateTime(2026, month, day);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: 'jr_default',
    content: 'c',
    tags: tags,
    replyToEntryId: replyTo,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  group('topTagOfMonth', () {
    test('picks the most-used tag of the month with its count', () {
      final best = topTagOfMonth([
        _entry(id: '1', month: 6, day: 3, tags: ['가족', '제주']),
        _entry(id: '2', month: 6, day: 10, tags: ['가족']),
        _entry(id: '3', month: 6, day: 12, tags: ['일상']),
      ], 2026, 6);
      expect(best!.key, '가족');
      expect(best.value, 2);
    });

    test('only counts the given month', () {
      final best = topTagOfMonth([
        _entry(id: '1', month: 6, day: 3, tags: ['제주']),
        _entry(id: '2', month: 5, day: 9, tags: ['부산']),
        _entry(id: '3', month: 5, day: 10, tags: ['부산']),
      ], 2026, 6);
      expect(best!.key, '제주');
      expect(best.value, 1);
    });

    test('groups case-insensitively and trims, keeping first spelling', () {
      final best = topTagOfMonth([
        _entry(id: '1', month: 6, day: 3, tags: ['Travel']),
        _entry(id: '2', month: 6, day: 5, tags: ['  travel  ']),
      ], 2026, 6);
      expect(best!.key, 'Travel');
      expect(best.value, 2);
    });

    test('ties resolve alphabetically', () {
      final best = topTagOfMonth([
        _entry(id: '1', month: 6, day: 3, tags: ['육아']),
        _entry(id: '2', month: 6, day: 5, tags: ['가족']),
      ], 2026, 6);
      expect(best!.key, '가족');
    });

    test('excludes replies and blank tags', () {
      final best = topTagOfMonth([
        _entry(id: 'top', month: 6, day: 3, tags: ['가족']),
        _entry(id: 'reply', month: 6, day: 3, tags: ['가족'], replyTo: 'top'),
        _entry(id: 'blank', month: 6, day: 4, tags: ['   ']),
      ], 2026, 6);
      expect(best!.key, '가족');
      expect(best.value, 1);
    });

    test('null when the month has no tagged records', () {
      final best = topTagOfMonth([
        _entry(id: '1', month: 6, day: 3),
      ], 2026, 6);
      expect(best, isNull);
    });
  });
}
