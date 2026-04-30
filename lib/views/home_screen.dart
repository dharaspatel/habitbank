import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../services/profile_service.dart';
import '../services/supabase_service.dart';
import '../services/workout_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/group_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/money_field.dart';
import '../widgets/section.dart';
import 'create_account_screen.dart';
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
      final home = context.read<HomeViewModel>();
      if (auth.userId != null) {
        final userId = auth.userId!;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          home.load(userId);
          // First-launch profile setup: a fresh signup leaves profiles.name
          // empty. Send the user through the avatar + name screen before
          // they see anything else.
          final profile =
              await ProfileService(SupabaseService.client).get(userId);
          if (!mounted) return;
          if (profile == null || profile.name.trim().isEmpty) {
            await Navigator.of(context).push(
              CupertinoPageRoute<void>(
                fullscreenDialog: true,
                builder: (_) => const CreateAccountScreen(),
              ),
            );
          }
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
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showAddSheet,
          child: const Icon(CupertinoIcons.add, color: AppTheme.foreground),
        ),
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
                    Text(_formatSignedMoney(vm.totalBalance),
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
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList.separated(
                  itemCount: vm.groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final g = vm.groups[i];
                    return _GroupTile(
                      group: g,
                      balance: vm.balanceForGroup(g.id),
                      onTap: () => _openGroup(g),
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Text(
        'No groups yet. Tap + to create or join one.',
        style: AppTheme.body.copyWith(color: AppTheme.muted),
      ),
    );
  }

  void _showAddSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetCtx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetCtx).pop();
              _push(const CreateGroupScreen());
            },
            child: const Text('Create group'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetCtx).pop();
              _push(const JoinGroupScreen());
            },
            child: const Text('Join with code'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetCtx).pop(),
          child: const Text('Cancel'),
        ),
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

/// "$1.20" or "−$1.20" — accepts a cents value.
String _formatSignedMoney(int cents) {
  final abs = formatCents(cents.abs());
  return cents < 0 ? '−$abs' : abs;
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
    return AppCard(
      onTap: onTap,
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
          Text(_formatSignedMoney(balance), style: AppTheme.headline),
          const SizedBox(width: 8),
          const Icon(CupertinoIcons.chevron_right,
              size: 16, color: AppTheme.muted),
        ],
      ),
    );
  }
}
