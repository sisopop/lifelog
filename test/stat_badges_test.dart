import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/shared/widgets/stat_badges.dart';

/// Pumps a list of badge widgets inside a Column and returns nothing;
/// callers assert with find.text.
Future<void> _pump(WidgetTester tester, List<Widget> badges) =>
    tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Column(children: badges)),
    ));

void main() {
  testWidgets('renders each badge above its threshold', (tester) async {
    await _pump(tester, [
      ...statBadgeAvgChars(29),
      ...statBadgeFavorites(1),
      ...statBadgeDecorated(2),
      ...statBadgePhotos(3),
      ...statBadgeJournalNames(const ['나의 일기장', 'Exchange']),
      ...statBadgeWeekday(6), // 토
      ...statBadgeDayPart(1), // 아침
    ]);
    expect(find.text('✍️ 평균 29자'), findsOneWidget);
    expect(find.text('⭐ 즐겨찾기 1개'), findsOneWidget);
    expect(find.text('🎨 꾸민 기록 2개'), findsOneWidget);
    expect(find.text('📷 사진 있는 기록 3개'), findsOneWidget);
    expect(find.text('📓 나의 일기장 · Exchange'), findsOneWidget);
    expect(find.text('📆 주로 토요일'), findsOneWidget);
    expect(find.text('🕘 주로 아침에 기록'), findsOneWidget);
  });

  test('returns empty below threshold / when null / when empty', () {
    expect(statBadgeAvgChars(0), isEmpty);
    expect(statBadgeFavorites(0), isEmpty);
    expect(statBadgeDecorated(0), isEmpty);
    expect(statBadgePhotos(0), isEmpty);
    expect(statBadgeJournalNames(const []), isEmpty);
    expect(statBadgeWeekday(null), isEmpty);
    expect(statBadgeDayPart(null), isEmpty);
  });

  test('journal names cap at four', () {
    final w = statBadgeJournalNames(const ['a', 'b', 'c', 'd', 'e']);
    expect(w, isNotEmpty);
    final text = w.whereType<Text>().first.data;
    expect(text, '📓 a · b · c · d');
  });
}
