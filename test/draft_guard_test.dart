import 'package:flutter/material.dart';
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

  group('canSaveEntry', () {
    test('content with text can be saved', () {
      expect(canSaveEntry(content: '오늘의 기록'), isTrue);
    });

    test('empty or whitespace-only content cannot be saved', () {
      expect(canSaveEntry(content: ''), isFalse);
      expect(canSaveEntry(content: '   \n\t '), isFalse);
    });
  });

  group('confirmLeaveDraft', () {
    // 이 다이얼로그는 이제 X(닫기) 버튼과 물리 back key 양쪽에서 뜬다.
    Future<bool?> tapAndRead(WidgetTester tester, String button) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () async => result = await confirmLeaveDraft(ctx),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      // 다이얼로그가 예상 문구와 두 선택지를 보여준다.
      expect(find.text('작성을 그만둘까요?'), findsOneWidget);
      expect(find.text('계속 작성'), findsOneWidget);
      expect(find.text('나가기'), findsOneWidget);
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('"나가기" returns true (leave)', (tester) async {
      expect(await tapAndRead(tester, '나가기'), isTrue);
    });

    testWidgets('"계속 작성" returns false (stay)', (tester) async {
      expect(await tapAndRead(tester, '계속 작성'), isFalse);
    });
  });
}
