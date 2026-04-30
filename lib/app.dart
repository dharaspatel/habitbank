import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/group_service.dart';
import 'services/supabase_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'views/home_screen.dart';
import 'views/onboarding_screen.dart';

class HabitBankApp extends StatelessWidget {
  const HabitBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    final client = SupabaseService.client;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(AuthService(client)),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(GroupService(client)),
        ),
      ],
      child: CupertinoApp(
        title: 'HabitBank',
        theme: AppTheme.theme,
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    switch (auth.status) {
      case AuthStatus.signedIn:
        return const HomeScreen();
      case AuthStatus.signedOut:
      case AuthStatus.unknown:
        return const OnboardingScreen();
    }
  }
}
