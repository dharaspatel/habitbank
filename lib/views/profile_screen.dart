import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../services/profile_service.dart';
import '../services/supabase_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/money_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/section.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(
        service: ProfileService(SupabaseService.client),
        userId: auth.userId!,
      )..load(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final vm = context.watch<ProfileViewModel>();
    final home = context.watch<HomeViewModel>();
    final url = vm.profile?.photoUrl;
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
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.subtle,
                    image: url != null
                        ? DecorationImage(
                            image: NetworkImage(url), fit: BoxFit.cover)
                        : null,
                  ),
                  child: url != null
                      ? null
                      : const Icon(CupertinoIcons.person,
                          color: AppTheme.muted),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.profile?.name.isNotEmpty == true
                            ? vm.profile!.name
                            : 'Unnamed',
                        style: AppTheme.headline,
                      ),
                      Text(vm.profile?.email ?? '', style: AppTheme.caption),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Edit'),
                  onPressed: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: context.read<ProfileViewModel>(),
                        child: const EditProfileScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SectionHeader('Bank'),
            _StatRow(label: 'Total balance', display: _money(home.totalBalance)),
            const ThinDivider(),
            _StatRow(label: 'Groups', display: '${home.groups.length}'),
            const ThinDivider(),
            _StatRow(
              label: 'Streak',
              display:
                  '${home.currentStreakWeeks} ${home.currentStreakWeeks == 1 ? "week" : "weeks"}',
            ),
            const ThinDivider(),
            _StatRow(label: 'Best week', display: _money(home.bestWeekDelta)),
            const SizedBox(height: 32),
            PrimaryButton(label: 'Sign out', onPressed: auth.signOut),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.display});
  final String label;
  final String display;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTheme.body)),
          Text(display, style: AppTheme.headline),
        ],
      ),
    );
  }
}

String _money(int cents) {
  final abs = formatCents(cents.abs());
  return cents < 0 ? '−$abs' : abs;
}
