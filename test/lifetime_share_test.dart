import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/stats/lifetime_share.dart';
import 'package:lifelog/features/stats/lifetime_stats.dart';

void main() {
  group('lifetimeStatsShareText', () {
    test('empty stats yield a placeholder', () {
      final t = lifetimeStatsShareText(const LifetimeStats(
        totalEntries: 0,
        totalChars: 0,
        recordedDays: 0,
        longestStreak: 0,
      ));
      expect(t, contains('내 기록 요약'));
      expect(t, contains('아직 기록이 없어요'));
    });

    test('includes every figure and the first-record date', () {
      final t = lifetimeStatsShareText(LifetimeStats(
        totalEntries: 8,
        totalChars: 400,
        recordedDays: 6,
        longestStreak: 3,
        firstDate: DateTime(2026, 6, 13),
      ));
      expect(t, contains('총 기록 8개'));
      expect(t, contains('쓴 글자 400자'));
      expect(t, contains('기록한 날 6일'));
      expect(t, contains('최장 연속 3일'));
      expect(t, contains('평균 50자/기록')); // 400/8
      expect(t, contains('첫 기록 2026.6.13'));
    });

    test('omits the first-record line when firstDate is null', () {
      final t = lifetimeStatsShareText(const LifetimeStats(
        totalEntries: 1,
        totalChars: 10,
        recordedDays: 1,
        longestStreak: 1,
      ));
      expect(t, isNot(contains('첫 기록')));
    });
  });
}
