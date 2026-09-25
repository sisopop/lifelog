import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ARCHITECTURE_RISK_REVIEW F2 진단: `Firebase.initializeApp()`이 실제로
/// 성공했는지를 상태로 노출한다. `main()`이 초기화 결과로 오버라이드한다.
///
/// 현재 소스 기준 웹은 `firebase_options.dart`에 web 옵션이 없어 항상 실패하고
/// (kIsWeb → UnsupportedError), 이는 `main()`이 조용히 삼켜 앱은 계속 실행된다.
/// 이 provider는 그 사실을 화면단에서 관찰 가능하게만 만든다 — UI 분기(로그인/
/// 원격 공지 비활성 안내 등)는 아직 연결하지 않았다(Phase 1에서 다룸).
///
/// 기본값 true: 이 provider를 오버라이드하지 않는 기존 위젯 테스트에 영향을
/// 주지 않기 위함이다(진짜 값은 main()에서만 오버라이드됨).
final firebaseAvailableProvider = Provider<bool>((ref) => true);
