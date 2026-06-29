import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Maps a [FirebaseAuthException.code] to a short, user-facing Korean message.
/// Pure & top-level so it is unit-testable without touching Firebase. Unknown
/// codes fall back to a generic message instead of leaking the raw code.
String authErrorMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return '이메일 형식이 올바르지 않아요';
    case 'user-disabled':
      return '사용이 중지된 계정이에요';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return '이메일 또는 비밀번호가 올바르지 않아요';
    case 'email-already-in-use':
      return '이미 가입된 이메일이에요';
    case 'weak-password':
      return '비밀번호는 6자 이상으로 정해주세요';
    case 'network-request-failed':
      return '네트워크 연결을 확인해주세요';
    case 'too-many-requests':
      return '잠시 후 다시 시도해주세요';
    case 'operation-not-allowed':
    case 'configuration-not-found':
      return '이메일 로그인이 아직 활성화되지 않았어요';
    default:
      return '로그인 중 문제가 생겼어요. 다시 시도해주세요';
  }
}

/// Thin wrapper over [FirebaseAuth]. All calls are guarded so a project without
/// Auth provisioned (or the keyless web build) degrades gracefully instead of
/// crashing. Sign-in/up surface a Korean message via [authErrorMessage].
class AuthRepository {
  AuthRepository(this._auth);
  final FirebaseAuth? _auth;

  String? get currentUid => _auth?.currentUser?.uid;
  String? get currentEmail => _auth?.currentUser?.email;

  /// Signs in with email/password. Returns the uid on success; throws
  /// [AuthException] (Korean message) on any failure.
  Future<String> signIn(String email, String password) =>
      _run(() => _auth!.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          ));

  Future<String> signUp(String email, String password) =>
      _run(() => _auth!.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          ));

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {/* ignore — local session is cleared by the caller */}
  }

  Future<String> _run(Future<UserCredential> Function() op) async {
    if (_auth == null) {
      throw const AuthException('로그인 기능을 사용할 수 없어요');
    }
    try {
      final cred = await op();
      final uid = cred.user?.uid;
      if (uid == null) throw const AuthException('로그인에 실패했어요');
      return uid;
    } on FirebaseAuthException catch (e) {
      throw AuthException(authErrorMessage(e.code));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('로그인 중 문제가 생겼어요. 다시 시도해주세요');
    }
  }
}

/// User-facing (Korean) auth failure carrying a ready-to-show [message].
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => 'AuthException: $message';
}

/// Provides an [AuthRepository]. Returns a no-op repo if Firebase Auth can't be
/// reached so the app (incl. the keyless web build) never crashes on startup.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  FirebaseAuth? auth;
  try {
    auth = FirebaseAuth.instance;
  } catch (_) {
    auth = null;
  }
  return AuthRepository(auth);
});
