import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/shared/models/enums.dart';

void main() {
  group('toggledWeather', () {
    test('selects a weather when none was set', () {
      expect(toggledWeather(null, Weather.sunny), Weather.sunny);
    });

    test('clears the weather when the same one is tapped again', () {
      expect(toggledWeather(Weather.sunny, Weather.sunny), isNull);
    });

    test('switches to a different weather', () {
      expect(toggledWeather(Weather.sunny, Weather.rainy), Weather.rainy);
    });
  });
}
