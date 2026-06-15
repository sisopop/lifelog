import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lifelog/features/auth/session.dart';

void main() {
  test('session starts logged out and persists login/logout', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(sessionProvider).loggedIn, isFalse);

    await container.read(sessionProvider.notifier).login('지연');
    expect(container.read(sessionProvider).loggedIn, isTrue);
    expect(container.read(sessionProvider).name, '지연');
    expect(prefs.getBool('loggedIn'), isTrue);

    await container.read(sessionProvider.notifier).logout();
    expect(container.read(sessionProvider).loggedIn, isFalse);
  });
}
