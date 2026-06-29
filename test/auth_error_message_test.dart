import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/auth/auth_repository.dart';

void main() {
  group('authErrorMessage', () {
    test('maps known codes to Korean messages', () {
      expect(authErrorMessage('invalid-email'), '이메일 형식이 올바르지 않아요');
      expect(authErrorMessage('email-already-in-use'), '이미 가입된 이메일이에요');
      expect(authErrorMessage('weak-password'), '비밀번호는 6자 이상으로 정해주세요');
      expect(authErrorMessage('network-request-failed'), '네트워크 연결을 확인해주세요');
    });

    test('bad credentials collapse to one message (no user enumeration)', () {
      const msg = '이메일 또는 비밀번호가 올바르지 않아요';
      expect(authErrorMessage('user-not-found'), msg);
      expect(authErrorMessage('wrong-password'), msg);
      expect(authErrorMessage('invalid-credential'), msg);
    });

    test('provider-disabled codes explain auth is not enabled yet', () {
      const msg = '이메일 로그인이 아직 활성화되지 않았어요';
      expect(authErrorMessage('operation-not-allowed'), msg);
      expect(authErrorMessage('configuration-not-found'), msg);
    });

    test('unknown codes fall back instead of leaking the raw code', () {
      final m = authErrorMessage('some-weird-code');
      expect(m, '로그인 중 문제가 생겼어요. 다시 시도해주세요');
      expect(m.contains('some-weird-code'), isFalse);
    });
  });
}
