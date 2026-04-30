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

  /// Sign in with email/password. If Supabase reports invalid credentials we
  /// optimistically attempt to sign up — first-time users get a one-tap
  /// flow; existing users with a wrong password get a clear error.
  ///
  /// Re-entrancy guard: a tap while another auth call is in flight is a
  /// no-op, so a frustrated double-tap can't accidentally trigger two
  /// signups against the same email.
  Future<void> signInOrSignUp({
    required String email,
    required String password,
  }) async {
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      try {
        await _auth.signInWithEmail(email: email, password: password);
        return; // success — onAuthStateChange will flip _status
      } on AuthException catch (e) {
        if (!_looksLikeMissingAccount(e)) {
          _error = _friendly(e);
          return;
        }
        // Account doesn't exist (or password wrong); try signup.
      }
      try {
        final res =
            await _auth.signUpWithEmail(email: email, password: password);
        if (res.session == null) {
          // Signup succeeded but no session — Supabase is set to require
          // email confirmation, OR the email already exists and signup
          // returned the existing user without a session.
          _error =
              'Check your email to confirm your account, or try a different password if you already signed up.';
        }
      } on AuthException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains('already registered') ||
            msg.contains('already exists')) {
          _error = 'Wrong password for that email.';
        } else {
          _error = _friendly(e);
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
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _auth.signUpWithEmail(
          email: email, password: password, name: name);
      if (res.session == null) {
        _error = 'Check your email to confirm your account.';
      }
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
