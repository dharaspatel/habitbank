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
      child: const CupertinoApp(
        title: 'HabitBank',
        theme: AppTheme.theme,
        home: _Root(),
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  AuthStatus? _previous;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    // When the auth status flips, drop any pushed routes (sign-in, profile,
    // create-account, etc.) so the user lands on whichever screen _Root
    // is now rendering — Home after sign-in, Onboarding after sign-out.
    if (_previous != null && _previous != auth.status) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final nav = Navigator.of(context);
        if (nav.canPop()) nav.popUntil((r) => r.isFirst);
      });
    }
    _previous = auth.status;
    switch (auth.status) {
      case AuthStatus.signedIn:
        return const HomeScreen();
      case AuthStatus.signedOut:
      case AuthStatus.unknown:
        return const OnboardingScreen();
    }
  }
}
