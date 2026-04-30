import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/primary_button.dart';
import '../widgets/section.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppTheme.background,
        border: null,
        middle: Text(''),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(_isSignUp ? 'Create account' : 'Sign in',
                style: AppTheme.balanceLarge.copyWith(fontSize: 40)),
            const SizedBox(height: 24),
            if (Platform.isIOS || Platform.isMacOS) ...[
              PrimaryButton(
                label: 'Continue with Apple',
                onPressed: vm.busy ? null : vm.signInApple,
                busy: vm.busy,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('or', style: AppTheme.caption),
              ),
              const SizedBox(height: 16),
            ],
            if (_isSignUp) ...[
              const SectionHeader('Name'),
              CupertinoTextField(
                controller: _name,
                placeholder: 'Your name',
                padding: const EdgeInsets.all(14),
              ),
            ],
            const SectionHeader('Email'),
            CupertinoTextField(
              controller: _email,
              placeholder: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              padding: const EdgeInsets.all(14),
            ),
            const SectionHeader('Password'),
            CupertinoTextField(
              controller: _password,
              placeholder: '••••••••',
              obscureText: true,
              padding: const EdgeInsets.all(14),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isSignUp ? 'Create account' : 'Sign in',
              busy: vm.busy,
              onPressed: vm.busy
                  ? null
                  : () {
                      if (_isSignUp) {
                        vm.signUpEmail(
                            _email.text, _password.text, _name.text);
                      } else {
                        vm.signInEmail(_email.text, _password.text);
                      }
                    },
            ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(vm.error!,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 13,
                    )),
              ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(
                _isSignUp ? 'Have an account? Sign in' : 'New here? Sign up',
                style: AppTheme.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
