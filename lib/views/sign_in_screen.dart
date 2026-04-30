import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/primary_button.dart';
import '../widgets/section.dart';
import 'create_account_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final vm = context.read<AuthViewModel>();
    if (vm.busy) return;
    vm.signInOrSignUp(
      email: _email.text.trim(),
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppTheme.background,
        border: null,
        middle: Text(''),
      ),
      child: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Text('Sign in',
                  style: AppTheme.balanceLarge.copyWith(fontSize: 40)),
              const SizedBox(height: 24),
              const SectionHeader('Email'),
              CupertinoTextField(
                controller: _email,
                focusNode: _emailFocus,
                placeholder: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.username, AutofillHints.email],
                padding: const EdgeInsets.all(14),
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SectionHeader('Password'),
              CupertinoTextField(
                controller: _password,
                focusNode: _passwordFocus,
                placeholder: 'at least 6 characters',
                obscureText: true,
                textInputAction: TextInputAction.go,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.password],
                padding: const EdgeInsets.all(14),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Sign in',
                  busy: vm.busy,
                  busyLabel: 'Signing in…',
                  onPressed: vm.busy ? null : _submit,
                ),
              ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(vm.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 13,
                      )),
                ),
              const SizedBox(height: 16),
              Center(
                child: CupertinoButton(
                  onPressed: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                        builder: (_) => const CreateAccountScreen()),
                  ),
                  child: const Text('New here? Create account',
                      style: AppTheme.caption),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
