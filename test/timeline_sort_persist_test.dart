import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lifelog/features/auth/session.dart';
import 'package:lifelog/features/timeline/timeline_filter.dart';

Future<ProviderContainer> _container(Map<String, Object> seed) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('defaults to newest-first when nothing stored', () async {
    final c = await _container({});
    expect(c.read(timelineSortProvider), isFalse);
  });

  test('reads the stored oldest-first preference', () async {
    final c = await _container({'timeline_sort_ascending': true});
    expect(c.read(timelineSortProvider), isTrue);
  });

  test('toggle flips and persists the order', () async {
    final c = await _container({});
    await c.read(timelineSortProvider.notifier).toggle();
    expect(c.read(timelineSortProvider), isTrue);

    final prefs = c.read(sharedPrefsProvider);
    expect(prefs.getBool('timeline_sort_ascending'), isTrue);

    await c.read(timelineSortProvider.notifier).toggle();
    expect(c.read(timelineSortProvider), isFalse);
    expect(prefs.getBool('timeline_sort_ascending'), isFalse);
  });
}
