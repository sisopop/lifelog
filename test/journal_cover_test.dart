import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/journal_cover.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: SizedBox(
      width: 110, height: 140, child: child))));

void main() {
  group('JournalCover', () {
    testWidgets('아이콘과 제목을 표시한다', (tester) async {
      await tester.pumpWidget(_host(const JournalCover(
        color: 0xFF7C6FF0,
        icon: '🌙',
        title: '나의 일기장',
      )));
      expect(find.text('🌙'), findsOneWidget);
      expect(find.text('나의 일기장'), findsOneWidget);
    });

    testWidgets('title이 null이면 제목을 그리지 않는다', (tester) async {
      await tester.pumpWidget(_host(const JournalCover(
        color: 0xFF7C6FF0,
        icon: '🌙',
        centerIcon: true,
      )));
      expect(find.text('🌙'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget); // 아이콘 텍스트 1개뿐
    });

    testWidgets('icon이 빈 문자열이면 아이콘이 안 보인다(없음)', (tester) async {
      await tester.pumpWidget(_host(const JournalCover(
        color: 0xFF7C6FF0,
        icon: '',
        title: '나의 일기장',
      )));
      expect(find.text('🌙'), findsNothing);
      expect(find.text('나의 일기장'), findsOneWidget);
    });

    testWidgets('entryCount가 있으면 배지를 표시한다', (tester) async {
      await tester.pumpWidget(_host(const JournalCover(
        color: 0xFF7C6FF0,
        icon: '🌙',
        title: 'A',
        entryCount: 7,
      )));
      expect(find.text('7'), findsOneWidget);
    });
  });
}
