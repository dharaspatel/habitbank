import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/onboarding_carousel.dart';
import '../widgets/primary_button.dart';
import '../widgets/section.dart';

/// Combined intro + sign-in screen. The 3-page carousel pitches the app;
/// email + password below auto sign-in or sign-up via [AuthViewModel].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  static const _pages = [
    OnboardingPage(
      headline: 'Bet on yourself.',
      body: 'Stake real money on weekly fitness goals you actually want to hit.',
    ),
    OnboardingPage(
      headline: 'Bet with friends.',
      body: 'Create a group, set the goal, and put a stake on it together.',
    ),
    OnboardingPage(
      headline: 'Stay consistent.',
      body: 'Hit the goal — keep your stake. Miss it — lose it.',
    ),
  ];

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
      child: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            children: [
              const OnboardingCarousel(pages: _pages),
              const SizedBox(height: 32),
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
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email
                ],
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
                  label: 'Continue',
                  busy: vm.busy,
                  busyLabel: 'Signing in…',
                  onPressed: vm.busy ? null : _submit,
                ),
              ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    vm.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Continue tries to sign you in;\nif no account exists yet, we create one.',
                  textAlign: TextAlign.center,
                  style: AppTheme.caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
