import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../services/supabase_service.dart';
import '../services/workout_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/group_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/primary_button.dart';
import '../widgets/section.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'join_group_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final auth = context.read<AuthViewModel>();
      final vm = context.read<HomeViewModel>();
      if (auth.userId != null) {
        // Defer until after the current build so notifyListeners() doesn't
        // mark provider scopes dirty during build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.load(auth.userId!);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final auth = context.watch<AuthViewModel>();
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.background,
        border: null,
        middle: const Text('HabitBank'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.person, color: AppTheme.foreground),
          onPressed: () => Navigator.of(context).push(
            CupertinoPageRoute<void>(
                builder: (_) => const ProfileScreen()),
          ),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                if (auth.userId != null) await vm.load(auth.userId!);
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total balance', style: AppTheme.caption),
                    const SizedBox(height: 4),
                    Text(_formatBalance(vm.totalBalance),
                        style: AppTheme.balanceLarge),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SectionHeader('Your groups')),
            if (vm.loading && vm.groups.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator()),
              )
            else if (vm.groups.isEmpty)
              SliverToBoxAdapter(child: _emptyState(context))
            else
              SliverList.separated(
                itemCount: vm.groups.length,
                separatorBuilder: (_, __) => const ThinDivider(),
                itemBuilder: (_, i) {
                  final g = vm.groups[i];
                  return _GroupTile(
                    group: g,
                    balance: vm.balanceForGroup(g.id),
                    onTap: () => _openGroup(g),
                  );
                },
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: 'Create group',
                      onPressed: () => _push(const CreateGroupScreen()),
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: 'Join with code',
                      onPressed: () => _push(const JoinGroupScreen()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Text(
        'No groups yet. Create one or join with a code.',
        style: AppTheme.body.copyWith(color: AppTheme.muted),
      ),
    );
  }

  void _push(Widget w) {
    final auth = context.read<AuthViewModel>();
    final home = context.read<HomeViewModel>();
    Navigator.of(context)
        .push(CupertinoPageRoute<void>(builder: (_) => w))
        .then((_) {
      if (auth.userId != null) home.load(auth.userId!);
    });
  }

  void _openGroup(Group g) {
    final auth = context.read<AuthViewModel>();
    final home = context.read<HomeViewModel>();
    final client = SupabaseService.client;
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => GroupViewModel(
            groupService: GroupService(client),
            workoutService: WorkoutService(client),
            group: g,
            currentUserId: auth.userId!,
          )..load(),
          child: const GroupDetailScreen(),
        ),
      ),
    ).then((_) {
      if (auth.userId != null) home.load(auth.userId!);
    });
  }
}

String _formatBalance(int n) {
  final sign = n < 0 ? '−' : '';
  return '$sign${n.abs()}';
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.balance,
    required this.onTap,
  });

  final Group group;
  final int balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name, style: AppTheme.headline),
                  const SizedBox(height: 2),
                  Text('Code ${group.inviteCode}', style: AppTheme.caption),
                ],
              ),
            ),
            Text(_formatBalance(balance), style: AppTheme.headline),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_right,
                size: 16, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }
}
