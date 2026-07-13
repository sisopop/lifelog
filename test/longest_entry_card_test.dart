import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/widgets/longest_entry_card.dart';

DiaryEntry _e({
  String id = '1',
  String? title,
  String content = 'x',
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'j1',
      title: title,
      content: content,
      createdAt: DateTime(2026, 6, 12),
      updatedAt: DateTime(2026, 6, 12),
    );

/// Wraps the card in a minimal router so context.push has a Navigator.
Widget _host(Widget child) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => Scaffold(body: child)),
      GoRoute(path: '/entry/:id', builder: (_, _) => const SizedBox()),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets('renders scoped header, char count and title', (tester) async {
    await tester.pumpWidget(_host(
      LongestEntryCard(
        entry: _e(title: '제주도에서의 하루', content: 'body'),
        chars: 42,
        scopeLabel: '이 태그의',
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('📜 이 태그의 가장 긴 기록 (42자)'), findsOneWidget);
    expect(find.text('제주도에서의 하루'), findsOneWidget);
  });

  testWidgets('falls back to content when title is blank', (tester) async {
    await tester.pumpWidget(_host(
      LongestEntryCard(
        entry: _e(content: '제목 없는 긴 본문'),
        chars: 7,
        scopeLabel: '이 날의',
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('📜 이 날의 가장 긴 기록 (7자)'), findsOneWidget);
    expect(find.text('제목 없는 긴 본문'), findsOneWidget);
  });
}
