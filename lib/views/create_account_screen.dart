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

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      // Default Cupertino back chevron handles "back to sign in".
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppTheme.background,
        border: null,
        previousPageTitle: 'Sign in',
        middle: Text('Create account'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text('Create account',
                style: AppTheme.balanceLarge.copyWith(fontSize: 40)),
            const SizedBox(height: 24),
            const SectionHeader('Name'),
            CupertinoTextField(
              controller: _name,
              placeholder: 'Your name',
              padding: const EdgeInsets.all(14),
            ),
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
              placeholder: 'at least 6 characters',
              obscureText: true,
              padding: const EdgeInsets.all(14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Create account',
                busy: vm.busy,
                onPressed: vm.busy
                    ? null
                    : () => vm.signUp(
                          email: _email.text.trim(),
                          password: _password.text,
                          name: _name.text.trim(),
                        ),
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
    );
  }
}
