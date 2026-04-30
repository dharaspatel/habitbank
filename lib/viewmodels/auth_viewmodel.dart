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

  Future<void> signInEmail(String email, String password) =>
      _wrap(() => _auth.signInWithEmail(email: email, password: password));

  Future<void> signUpEmail(String email, String password, String name) =>
      _wrap(() => _auth.signUpWithEmail(
          email: email, password: password, name: name));

  Future<void> signInApple() => _wrap(() => _auth.signInWithApple());

  Future<void> signOut() => _wrap(() => _auth.signOut());

  Future<void> _wrap(Future<dynamic> Function() op) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await op();
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
