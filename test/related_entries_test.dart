import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/entry_detail/related_entries.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry({
  required String id,
  required DateTime at,
  String? replyTo,
  List<String> tags = const [],
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'jr_default',
      content: 'c',
      tags: tags,
      replyToEntryId: replyTo,
      createdAt: at,
      updatedAt: at,
    );

void main() {
  final base = _entry(id: 'base', at: DateTime(2026, 6, 10), tags: ['여행', '가족']);

  test('empty when the entry has no tags', () {
    final tagless = _entry(id: 'base', at: DateTime(2026, 6, 10));
    expect(
      relatedEntries([
        tagless,
        _entry(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행']),
      ], tagless),
      isEmpty,
    );
  });

  test('excludes the entry itself, replies, and no-overlap records', () {
    final r = relatedEntries([
      base,
      _entry(id: 'self2', at: DateTime(2026, 6, 9), tags: ['여행']), // shares
      _entry(id: 'reply', at: DateTime(2026, 6, 8), tags: ['여행'], replyTo: 'x'),
      _entry(id: 'none', at: DateTime(2026, 6, 7), tags: ['일상']), // no overlap
    ], base);
    expect(r.map((e) => e.entryId).toList(), ['self2']);
  });

  test('ranks by shared-tag count desc, then by recency', () {
    final r = relatedEntries([
      base,
      _entry(id: 'one', at: DateTime(2026, 6, 5), tags: ['여행']), // 1 shared
      _entry(id: 'two', at: DateTime(2026, 6, 1), tags: ['여행', '가족']), // 2 shared
      _entry(id: 'oneNewer', at: DateTime(2026, 6, 8), tags: ['가족']), // 1, newer
    ], base);
    // two (2 shared) first; then the two 1-shared ordered newest-first.
    expect(r.map((e) => e.entryId).toList(), ['two', 'oneNewer', 'one']);
  });

  test('respects the limit', () {
    final r = relatedEntries([
      base,
      _entry(id: 'a', at: DateTime(2026, 6, 5), tags: ['여행']),
      _entry(id: 'b', at: DateTime(2026, 6, 4), tags: ['가족']),
      _entry(id: 'c', at: DateTime(2026, 6, 3), tags: ['여행']),
      _entry(id: 'd', at: DateTime(2026, 6, 2), tags: ['가족']),
    ], base, limit: 2);
    expect(r.length, 2);
    expect(r.map((e) => e.entryId).toList(), ['a', 'b']);
  });
}
