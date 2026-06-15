import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Injected in main() after SharedPreferences is loaded.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

class Session {
  const Session({required this.loggedIn, this.name});
  final bool loggedIn;
  final String? name;
}

/// Lightweight local session. The MVP gate is local-only; real auth
/// (JWT) plugs in here later — see TECH_DESIGN.md `/auth`.
class SessionNotifier extends Notifier<Session> {
  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  Session build() => Session(
        loggedIn: _p.getBool('loggedIn') ?? false,
        name: _p.getString('name'),
      );

  Future<void> login(String name) async {
    await _p.setBool('loggedIn', true);
    await _p.setString('name', name);
    state = Session(loggedIn: true, name: name);
  }

  Future<void> logout() async {
    await _p.setBool('loggedIn', false);
    state = Session(loggedIn: false, name: state.name);
  }
}

final sessionProvider =
    NotifierProvider<SessionNotifier, Session>(SessionNotifier.new);
