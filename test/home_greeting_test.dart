import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/home/home_greeting.dart';

void main() {
  test('dawn hours (0-5)', () {
    expect(greetingForHour(0), '편안한 새벽이에요');
    expect(greetingForHour(5), '편안한 새벽이에요');
  });

  test('morning hours (6-11)', () {
    expect(greetingForHour(6), '좋은 아침이에요');
    expect(greetingForHour(11), '좋은 아침이에요');
  });

  test('afternoon hours (12-17)', () {
    expect(greetingForHour(12), '좋은 오후예요');
    expect(greetingForHour(17), '좋은 오후예요');
  });

  test('evening/night hours (18-23)', () {
    expect(greetingForHour(18), '편안한 밤 되세요');
    expect(greetingForHour(23), '편안한 밤 되세요');
  });
}
