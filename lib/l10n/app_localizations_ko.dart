// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class L10nKo extends L10n {
  L10nKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'lifelog';

  @override
  String get navHome => '홈';

  @override
  String get navReview => '회고';

  @override
  String get navAlerts => '알림';

  @override
  String get navFriends => '친구';

  @override
  String get navWrite => '작성';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsProfile => '프로필';

  @override
  String get settingsLanguage => '앱 언어';

  @override
  String get settingsNotifications => '알림 설정';

  @override
  String get settingsLogout => '로그아웃';

  @override
  String get settingsTerms => '약관 / 문의';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageSystem => '기기 언어 따름';

  @override
  String get commonSave => '저장';

  @override
  String get commonCancel => '취소';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonEdit => '수정';

  @override
  String get commonShare => '공유하기';

  @override
  String get commonConfirm => '확인';

  @override
  String get moodGood => '좋았어요';

  @override
  String get moodNeutral => '보통';

  @override
  String get moodHard => '힘들었어요';

  @override
  String get writeHint => '오늘 하루는 어땠나요?';

  @override
  String get aiSummaryTitle => 'AI 요약';

  @override
  String get aiSummaryPending => '요약을 만들고 있어요…';
}
