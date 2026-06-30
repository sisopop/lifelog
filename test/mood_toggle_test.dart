import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/shared/models/enums.dart';

void main() {
  group('toggledMood', () {
    test('selects a mood when none was set', () {
      expect(toggledMood(null, Mood.good), Mood.good);
    });

    test('clears the mood when the same one is tapped again', () {
      expect(toggledMood(Mood.good, Mood.good), isNull);
    });

    test('switches to a different mood', () {
      expect(toggledMood(Mood.good, Mood.hard), Mood.hard);
    });
  });
}
