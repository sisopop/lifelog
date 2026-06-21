import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/review/review_share.dart';
import 'package:lifelog/features/stats/stats_provider.dart';
import 'package:lifelog/shared/models/enums.dart';

MonthlyStats _stats({
  int year = 2026,
  int month = 6,
  int days = 0,
  int total = 0,
  int chars = 0,
  Map<Mood, double> mood = const {},
  List<MapEntry<String, int>> tags = const [],
}) =>
    MonthlyStats(
      year: year,
      month: month,
      daysRecorded: days,
      total: total,
      charsWritten: chars,
      moodRatio: mood,
      topTags: tags,
    );

void main() {
  group('monthlyReviewShareText', () {
    test('empty month yields a placeholder', () {
      final t = monthlyReviewShareText(_stats());
      expect(t, contains('2026년 6월 회고'));
      expect(t, contains('아직 기록이 없어요'));
    });

    test('includes counts, moods and tags', () {
      final t = monthlyReviewShareText(_stats(
        days: 12,
        total: 5,
        chars: 234,
        mood: const {Mood.good: 0.6, Mood.hard: 0.4},
        tags: [const MapEntry('가족', 2), const MapEntry('여행', 1)],
      ));
      expect(t, contains('기록한 날 12일'));
      expect(t, contains('총 기록 5개'));
      expect(t, contains('쓴 글자 234자'));
      expect(t, contains('좋았어요 60%'));
      expect(t, contains('힘들었어요 40%'));
      expect(t, contains('#가족 2'));
      expect(t, contains('#여행 1'));
    });

    test('omits zero-ratio moods', () {
      final t = monthlyReviewShareText(_stats(
        days: 1,
        total: 1,
        chars: 10,
        mood: const {Mood.good: 1.0, Mood.neutral: 0.0},
      ));
      expect(t, contains('좋았어요 100%'));
      expect(t, isNot(contains('보통')));
    });

    test('skips the tag line when there are no tags', () {
      final t = monthlyReviewShareText(_stats(days: 1, total: 1, chars: 5));
      expect(t, isNot(contains('#')));
    });
  });
}
