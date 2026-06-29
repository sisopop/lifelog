import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/write/draft_guard.dart';

void main() {
  group('hasUnsavedDraft', () {
    test('new entry with any text is guarded', () {
      expect(
        hasUnsavedDraft(isEditing: false, title: '제목', content: ''),
        isTrue,
      );
      expect(
        hasUnsavedDraft(isEditing: false, title: '', content: '오늘의 기록'),
        isTrue,
      );
    });

    test('new entry that is empty or whitespace-only is not guarded', () {
      expect(
        hasUnsavedDraft(isEditing: false, title: '', content: ''),
        isFalse,
      );
      expect(
        hasUnsavedDraft(isEditing: false, title: '   ', content: '\n\t '),
        isFalse,
      );
    });

    test('editing an existing entry is never guarded', () {
      expect(
        hasUnsavedDraft(isEditing: true, title: '제목', content: '내용'),
        isFalse,
      );
    });
  });
}
