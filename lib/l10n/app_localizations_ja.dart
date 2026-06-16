// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class L10nJa extends L10n {
  L10nJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'lifelog';

  @override
  String get navHome => 'ホーム';

  @override
  String get navReview => 'ふりかえり';

  @override
  String get navAlerts => 'お知らせ';

  @override
  String get navFriends => '友だち';

  @override
  String get navWrite => '作成';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsProfile => 'プロフィール';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsNotifications => '通知設定';

  @override
  String get settingsLogout => 'ログアウト';

  @override
  String get settingsTerms => '規約 / お問い合わせ';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageSystem => '端末の言語に従う';

  @override
  String get commonSave => '保存';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonDelete => '削除';

  @override
  String get commonEdit => '編集';

  @override
  String get commonShare => '共有';

  @override
  String get commonConfirm => 'OK';

  @override
  String get moodGood => 'よかった';

  @override
  String get moodNeutral => 'ふつう';

  @override
  String get moodHard => 'つらかった';

  @override
  String get writeHint => '今日はどんな一日でしたか？';

  @override
  String get aiSummaryTitle => 'AI要約';

  @override
  String get aiSummaryPending => '要約を作成しています…';
}
