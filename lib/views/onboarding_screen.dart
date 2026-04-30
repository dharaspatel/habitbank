import 'package:flutter/cupertino.dart';

import '../config/theme.dart';
import '../widgets/primary_button.dart';
import 'sign_in_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('HabitBank', style: AppTheme.balanceLarge),
              const SizedBox(height: 16),
              Text(
                'Stake virtual money on your weekly workouts.\n'
                'Miss your goal, your friends win the pool.',
                style: AppTheme.body.copyWith(color: AppTheme.muted),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Get started',
                onPressed: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => const SignInScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
