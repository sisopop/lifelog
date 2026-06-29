import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_repository.dart';

/// Injected in main() after SharedPreferences is loaded.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

class Session {
  const Session({required this.loggedIn, this.name, this.email});
  final bool loggedIn;
  final String? name;

  /// Set only for real (Firebase) accounts; null for the local guest session.
  final String? email;

  bool get isGuest => loggedIn && email == null;
}

/// App session gate. The local `loggedIn` flag (SharedPreferences) is the source
/// of truth so the gate survives restarts and supports a guest (no-account)
/// mode. Real accounts go through Firebase Auth via [AuthRepository]; on success
/// we also flip the local flag and remember the email for display.
class SessionNotifier extends Notifier<Session> {
  SharedPreferences get _p => ref.read(sharedPrefsProvider);
  AuthRepository get _auth => ref.read(authRepositoryProvider);

  @override
  Session build() => Session(
        loggedIn: _p.getBool('loggedIn') ?? false,
        name: _p.getString('name'),
        email: _p.getString('email'),
      );

  /// Local "browse without an account" session — keeps the app usable even when
  /// email login is unavailable.
  Future<void> loginGuest(String name) async {
    await _p.setBool('loggedIn', true);
    await _p.setString('name', name);
    await _p.remove('email');
    state = Session(loggedIn: true, name: name);
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signIn(email, password); // throws AuthException on failure
    await _persistAccount(email);
  }

  Future<void> signUp(String email, String password) async {
    await _auth.signUp(email, password); // throws AuthException on failure
    await _persistAccount(email);
  }

  Future<void> _persistAccount(String email) async {
    final name = email.split('@').first;
    await _p.setBool('loggedIn', true);
    await _p.setString('name', name);
    await _p.setString('email', email.trim());
    state = Session(loggedIn: true, name: name, email: email.trim());
  }

  Future<void> logout() async {
    // Clear the local gate first so logout never blocks on the network /
    // Firebase; sign the Firebase user out in the background.
    await _p.setBool('loggedIn', false);
    await _p.remove('email');
    state = Session(loggedIn: false, name: state.name);
    unawaited(_auth.signOut());
  }
}

final sessionProvider =
    NotifierProvider<SessionNotifier, Session>(SessionNotifier.new);
