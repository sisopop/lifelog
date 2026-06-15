/// 템플릿 파일. 이 파일을 `api_keys.dart` 로 복사한 뒤 키를 채우세요.
/// (api_keys.dart 는 .gitignore 처리되어 커밋되지 않습니다.)
class ApiKeys {
  static const String _inline = 'YOUR_GEMINI_API_KEY';

  static const String gemini = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: _inline,
  );

  static bool get hasGemini =>
      gemini.isNotEmpty && gemini != 'YOUR_GEMINI_API_KEY';
}
