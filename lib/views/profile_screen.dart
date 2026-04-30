import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/primary_button.dart';
import '../widgets/section.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppTheme.background,
        border: null,
        middle: Text('Profile'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SectionHeader('Signed in as'),
            Text(auth.userId ?? '—', style: AppTheme.body),
            const SizedBox(height: 32),
            PrimaryButton(label: 'Sign out', onPressed: auth.signOut),
          ],
        ),
      ),
    );
  }
}
