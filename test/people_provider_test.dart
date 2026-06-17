import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/people/people_provider.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';
import 'package:lifelog/shared/models/journal_member.dart';

JournalMember _member({
  required String id,
  required String journalId,
  required String userId,
  required String name,
  bool isMe = false,
  MemberRole role = MemberRole.partner,
}) =>
    JournalMember(
      memberId: id,
      journalId: journalId,
      userId: userId,
      displayName: name,
      role: role,
      isMe: isMe,
      joinedAt: DateTime(2026, 1, 1),
    );

DiaryEntry _entry({
  required String id,
  required String journalId,
  required String userId,
  String? replyTo,
}) =>
    DiaryEntry(
      entryId: id,
      userId: userId,
      journalId: journalId,
      replyToEntryId: replyTo,
      content: 'x',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('aggregatePeople', () {
    test('excludes me and returns empty when no partners', () {
      final members = [
        _member(
            id: 'm1',
            journalId: 'j1',
            userId: 'me',
            name: '나',
            isMe: true,
            role: MemberRole.owner),
      ];
      expect(aggregatePeople(members, const []), isEmpty);
    });

    test('groups the same person across multiple journals by name', () {
      final members = [
        _member(id: 'm1', journalId: 'j1', userId: 'u_a', name: '지연'),
        _member(id: 'm2', journalId: 'j2', userId: 'u_b', name: '지연'),
      ];
      final entries = [
        _entry(id: 'e1', journalId: 'j1', userId: 'u_a'),
        _entry(id: 'e2', journalId: 'j2', userId: 'u_b'),
        _entry(id: 'e3', journalId: 'j1', userId: 'me'),
      ];
      final people = aggregatePeople(members, entries);
      expect(people.length, 1);
      expect(people.first.name, '지연');
      expect(people.first.journalCount, 2);
      expect(people.first.entryCount, 2);
    });

    test('does not count replies as entries', () {
      final members = [
        _member(id: 'm1', journalId: 'j1', userId: 'u_a', name: '민수'),
      ];
      final entries = [
        _entry(id: 'e1', journalId: 'j1', userId: 'u_a'),
        _entry(id: 'e2', journalId: 'j1', userId: 'u_a', replyTo: 'e1'),
      ];
      expect(aggregatePeople(members, entries).first.entryCount, 1);
    });

    test('sorts by entry count desc, then journals, then name', () {
      final members = [
        _member(id: 'm1', journalId: 'j1', userId: 'u_a', name: '엄마'),
        _member(id: 'm2', journalId: 'j2', userId: 'u_b', name: '지연'),
      ];
      final entries = [
        _entry(id: 'e1', journalId: 'j2', userId: 'u_b'),
        _entry(id: 'e2', journalId: 'j2', userId: 'u_b'),
      ];
      final people = aggregatePeople(members, entries);
      expect(people.map((p) => p.name), ['지연', '엄마']);
    });
  });
}
