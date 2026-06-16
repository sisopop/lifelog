// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'lifelog';

  @override
  String get navHome => 'Home';

  @override
  String get navReview => 'Review';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get navFriends => 'Friends';

  @override
  String get navWrite => 'Write';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsTerms => 'Terms / Support';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonShare => 'Share';

  @override
  String get commonConfirm => 'OK';

  @override
  String get moodGood => 'Good';

  @override
  String get moodNeutral => 'Okay';

  @override
  String get moodHard => 'Tough';

  @override
  String get writeHint => 'How was your day?';

  @override
  String get aiSummaryTitle => 'AI summary';

  @override
  String get aiSummaryPending => 'Generating a summary…';
}
