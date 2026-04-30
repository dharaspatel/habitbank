import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/primary_button.dart';
import '../widgets/section.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final vm = context.read<AuthViewModel>();
    if (vm.busy) return;
    vm.signUp(
      email: _email.text.trim(),
      password: _password.text,
      name: _name.text.trim(),
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
        previousPageTitle: 'Sign in',
        middle: Text('Create account'),
      ),
      child: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Text('Create account',
                  style: AppTheme.balanceLarge.copyWith(fontSize: 40)),
              const SizedBox(height: 24),
              const SectionHeader('Name'),
              CupertinoTextField(
                controller: _name,
                focusNode: _nameFocus,
                placeholder: 'Your name',
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                padding: const EdgeInsets.all(14),
                onSubmitted: (_) => _emailFocus.requestFocus(),
              ),
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
                autofillHints: const [AutofillHints.email, AutofillHints.username],
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
                autofillHints: const [AutofillHints.newPassword],
                padding: const EdgeInsets.all(14),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Create account',
                  busy: vm.busy,
                  busyLabel: 'Creating…',
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to sign in',
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
