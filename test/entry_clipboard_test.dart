import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/entry_detail/entry_clipboard.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry({
  String? title,
  String content = '',
  List<String> tags = const [],
  String? location,
}) {
  final t = DateTime(2026, 6, 17);
  return DiaryEntry(
    entryId: 'e',
    userId: 'me',
    journalId: 'jr_default',
    title: title,
    content: content,
    tags: tags,
    location: location,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  test('title, body and tags are joined with blank lines', () {
    final text = entryClipboardText(
      _entry(title: '제주도', content: '바다를 걸었다', tags: ['여행', '가족']),
    );
    expect(text, '제주도\n\n바다를 걸었다\n\n#여행 #가족');
  });

  test('missing title is skipped without a dangling separator', () {
    final text = entryClipboardText(_entry(content: '오늘은 평범한 하루'));
    expect(text, '오늘은 평범한 하루');
  });

  test('no tags → only title and body', () {
    final text = entryClipboardText(_entry(title: 't', content: 'b'));
    expect(text, 't\n\nb');
  });

  test('blank tags are dropped', () {
    final text = entryClipboardText(
      _entry(content: 'b', tags: ['', '  ', 'keep']),
    );
    expect(text, 'b\n\n#keep');
  });

  test('content is trimmed', () {
    final text = entryClipboardText(_entry(content: '  hi  '));
    expect(text, 'hi');
  });

  test('location is included as 📍 place between body and tags', () {
    final text = entryClipboardText(
      _entry(content: '바다를 걸었다', location: '제주', tags: ['여행']),
    );
    expect(text, '바다를 걸었다\n\n📍 제주\n\n#여행');
  });

  test('blank or null location is skipped', () {
    expect(entryClipboardText(_entry(content: 'b', location: '   ')), 'b');
    expect(entryClipboardText(_entry(content: 'b')), 'b');
  });

  test('location is trimmed', () {
    final text = entryClipboardText(_entry(content: 'b', location: '  제주  '));
    expect(text, 'b\n\n📍 제주');
  });
}
