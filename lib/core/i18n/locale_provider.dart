import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/session.dart';

/// Supported app languages (priority: ko → en → ja).
/// See TECH_DESIGN.md §8 (i18n / 글로벌 구조).
const supportedAppLocales = [Locale('ko'), Locale('en'), Locale('ja')];

/// Holds the user's app-language override.
///
/// `null` means "follow the device language" — Flutter then resolves the
/// device locale against [supportedAppLocales], falling back to `ko`.
/// A non-null value is the explicit user choice, persisted locally and
/// (later) synced to `users.locale` on the backend.
class LocaleNotifier extends Notifier<Locale?> {
  static const _key = 'app_locale';

  @override
  Locale? build() {
    final code = ref.read(sharedPrefsProvider).getString(_key);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  /// Pass `null` to follow the device language.
  Future<void> setLocale(Locale? locale) async {
    final prefs = ref.read(sharedPrefsProvider);
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
    state = locale;
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);
