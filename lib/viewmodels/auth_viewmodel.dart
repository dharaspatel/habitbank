import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._auth) {
    _status = _auth.currentSession == null
        ? AuthStatus.signedOut
        : AuthStatus.signedIn;
    _sub = _auth.onAuthStateChange.listen((s) {
      _status = s.session == null ? AuthStatus.signedOut : AuthStatus.signedIn;
      notifyListeners();
    });
  }

  final AuthService _auth;
  late final StreamSubscription<AuthState> _sub;
  AuthStatus _status = AuthStatus.unknown;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  AuthStatus get status => _status;
  String? get error => _error;
  bool get busy => _busy;
  String? get userId => _auth.currentUser?.id;

  /// Sign in with email/password. If the account does not exist, automatically
  /// create it with the same credentials. The Supabase response we treat as
  /// "user not found" is the generic `invalid_credentials` error: we attempt
  /// signup and only surface a real error if signup also fails.
  Future<void> signInOrSignUp({
    required String email,
    required String password,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      try {
        await _auth.signInWithEmail(email: email, password: password);
      } on AuthException catch (e) {
        if (_looksLikeMissingAccount(e)) {
          await _auth.signUpWithEmail(email: email, password: password);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      _error = _friendly(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.signUpWithEmail(
          email: email, password: password, name: name);
    } catch (e) {
      _error = _friendly(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _busy = true;
    notifyListeners();
    try {
      await _auth.signOut();
    } catch (e) {
      _error = _friendly(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  static bool _looksLikeMissingAccount(AuthException e) {
    final msg = e.message.toLowerCase();
    return msg.contains('invalid login credentials') ||
        msg.contains('user not found') ||
        msg.contains('invalid_credentials');
  }

  static String _friendly(Object e) {
    if (e is AuthException) return e.message;
    return e.toString();
  }
}
