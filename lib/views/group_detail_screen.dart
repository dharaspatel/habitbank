import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/member_palette.dart';
import '../config/theme.dart';
import '../models/challenge.dart';
import '../models/weekly_result.dart';
import '../services/supabase_service.dart';
import '../services/workout_service.dart';
import '../viewmodels/group_viewmodel.dart';
import '../viewmodels/log_workout_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/avatar.dart';
import '../widgets/celebrate.dart';
import '../widgets/pool_bar.dart';
import '../widgets/money_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/section.dart';
import '../widgets/week_progress_ring.dart';
import 'group_feed_screen.dart';
import 'log_workout_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GroupViewModel>();
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.background,
        border: null,
        middle: Text(vm.group.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child:
                  const Icon(CupertinoIcons.share, color: AppTheme.foreground),
              onPressed: () => _showInviteSheet(context, vm),
            ),
            if (vm.isOwner)
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.pencil,
                    color: AppTheme.foreground),
                onPressed: () => _openEditChallenge(context),
              ),
          ],
        ),
      ),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverRefreshControl(onRefresh: vm.load),
              SliverSafeArea(
                bottom: false,
                sliver: SliverToBoxAdapter(child: _MembersHero(vm: vm)),
              ),
              SliverToBoxAdapter(child: _ChallengeRing(vm: vm)),
              SliverToBoxAdapter(
                child: PoolBar(
                  members: vm.members,
                  balances: vm.balances,
                  projectedDeltas: vm.projectedDeltas,
                ),
              ),
              SliverToBoxAdapter(child: _PotentialLossCard(vm: vm)),
              const SliverToBoxAdapter(child: SectionHeader('Members')),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList.separated(
                  itemCount: vm.members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final m = vm.members[i];
                    final progress = vm.progressForUser(m.userId);
                    final goal = vm.challenge?.goalTarget;
                    return _MemberCard(
                      name:
                          m.profile.name.isEmpty ? 'Member' : m.profile.name,
                      photoUrl: m.profile.photoUrl,
                      progress: progress,
                      goal: goal,
                    );
                  },
                ),
              ),
              if (vm.weeklyResults.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  key: ValueKey('analytics-header'),
                  child: SectionHeader('Weekly results'),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList.separated(
                    itemCount: vm.weeklyResults.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _WeeklyResultCard(result: vm.weeklyResults[i]),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 160 + MediaQuery.of(context).padding.bottom,
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: AppTheme.background.withValues(alpha: 0.2),
                  padding: EdgeInsets.fromLTRB(
                    24,
                    12,
                    24,
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SecondaryButton(
                        label: 'See feed',
                        onPressed: () => _openFeed(context),
                      ),
                      const SizedBox(height: 5),
                      PrimaryButton(
                        label: 'Log workout',
                        onPressed: () => _openLog(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLog(BuildContext context) async {
    final vm = context.read<GroupViewModel>();
    final picker = ImagePicker();
    final captured = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (captured == null) return;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => LogWorkoutViewModel(
            service: WorkoutService(SupabaseService.client),
            userId: vm.currentUserId,
            groupId: vm.group.id,
            goalType: vm.challenge?.goalType ?? GoalType.workouts,
            photo: File(captured.path),
            picker: picker,
          ),
          child: const LogWorkoutScreen(),
        ),
      ),
    );
    await vm.load();
  }

  void _openFeed(BuildContext context) {
    final vm = context.read<GroupViewModel>();
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (feedContext) => GroupFeedScreen(
          groupName: vm.group.name,
          logs: vm.logs,
          members: vm.members,
          onLogWorkout: () => _openLog(context),
        ),
      ),
    );
  }

  void _showInviteSheet(BuildContext context, GroupViewModel vm) {
    final code = vm.group.inviteCode;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetCtx) => CupertinoActionSheet(
        title: const Text('Invite code'),
        message: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(code, style: AppTheme.balanceLarge.copyWith(fontSize: 40)),
              const SizedBox(height: 8),
              const Text(
                'Friends type this in on the Join screen.',
                style: AppTheme.caption,
              ),
            ],
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
            },
            child: const Text('Copy code'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetCtx).pop(),
          child: const Text('Done'),
        ),
      ),
    );
  }
}

/// Avatar stack with a colored ring per member encoding their progress
/// (solid black = on track / hit goal, light = behind).
class _MembersHero extends StatelessWidget {
  const _MembersHero({required this.vm});
  final GroupViewModel vm;

  @override
  Widget build(BuildContext context) {
    final avatars = [
      for (final m in vm.members)
        AvatarCircle(
          size: 44,
          photoUrl: m.profile.photoUrl,
          initial: m.profile.name.isNotEmpty ? m.profile.name : '·',
          ringColor: colorForUserId(m.userId),
          ringWidth: 2,
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Center(child: AvatarStack(avatars: avatars, size: 44)),
    );
  }
}

class _ChallengeRing extends StatelessWidget {
  const _ChallengeRing({required this.vm});
  final GroupViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = vm.challenge;
    final progress = vm.progressForUser(vm.currentUserId);
    if (c == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No challenge yet',
              style: AppTheme.headline.copyWith(color: AppTheme.muted)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            const Text('this week', style: AppTheme.caption),
            const SizedBox(height: 8),
            WeekProgressRing(
              value: progress,
              target: c.goalTarget,
              caption: 'complete',
            ),
          ],
        ),
      ),
    );
  }
}

/// "You could lose $X" — shown when the current user hasn't yet hit the
/// week's goal. Disappears once they're safe.
class _PotentialLossCard extends StatelessWidget {
  const _PotentialLossCard({required this.vm});
  final GroupViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = vm.challenge;
    if (c == null) return const SizedBox.shrink();
    final progress = vm.progressForUser(vm.currentUserId);
    if (progress >= c.goalTarget) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Text('🪙', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You could lose ${formatCents(c.stakeCents)}',
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${c.goalTarget - progress} to go',
              style: AppTheme.caption,
            ),
          ],
        ),
      ),
    );
  }
}

void _openEditChallenge(BuildContext context) {
  final vmRef = context.read<GroupViewModel>();
  Navigator.of(context, rootNavigator: true).push(
    CupertinoPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _ChallengeEditor(vm: vmRef),
    ),
  );
}

class _ChallengeEditor extends StatefulWidget {
  const _ChallengeEditor({required this.vm});
  final GroupViewModel vm;

  @override
  State<_ChallengeEditor> createState() => _ChallengeEditorState();
}

class _ChallengeEditorState extends State<_ChallengeEditor> {
  late GoalType _type = widget.vm.challenge?.goalType ?? GoalType.workouts;
  late int _target = widget.vm.challenge?.goalTarget ?? 4;
  late int _stakeCents = widget.vm.challenge?.stakeCents ?? 100;
  bool _saving = false;

  bool get _canSave => _stakeCents > 0 && _target > 0 && !_saving;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    await widget.vm.updateChallenge(
      type: _type,
      target: _target,
      stakeCents: _stakeCents,
    );
    if (!mounted) return;
    Celebrate.fire(context);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.background,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        middle: const Text('Edit challenge'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _canSave ? _save : null,
          child: Text(
            'Save',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _canSave ? AppTheme.foreground : AppTheme.muted,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SectionHeader('Goal type'),
            CupertinoSegmentedControl<GoalType>(
              groupValue: _type,
              onValueChanged: (v) => setState(() {
                _type = v;
                _target = v == GoalType.minutes ? 90 : 4;
              }),
              children: const {
                GoalType.workouts: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text('Workouts'),
                ),
                GoalType.minutes: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text('Minutes'),
                ),
              },
            ),
            const SectionHeader('Weekly target'),
            _StepperRow(
              label: _type == GoalType.minutes ? 'Minutes' : 'Workouts',
              value: _target,
              step: _type == GoalType.minutes ? 30 : 1,
              onChange: (v) => setState(() => _target = v),
            ),
            const SectionHeader('Weekly stake'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MoneyField(
                cents: _stakeCents,
                onChanged: (v) => setState(() => _stakeCents = v),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Each member wins this stake when they hit the goal and '
                'loses it when they miss.',
                style: AppTheme.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.step,
    required this.onChange,
  });

  final String label;
  final int value;
  final int step;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(label, style: AppTheme.body),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => onChange((value - step).clamp(1, 1000)),
            child: const Icon(CupertinoIcons.minus_circle),
          ),
          SizedBox(
            width: 64,
            child: Text('$value',
                textAlign: TextAlign.center, style: AppTheme.headline),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => onChange((value + step).clamp(1, 1000)),
            child: const Icon(CupertinoIcons.plus_circle),
          ),
        ],
      ),
    );
  }
}

class _WeeklyResultCard extends StatelessWidget {
  const _WeeklyResultCard({required this.result});
  final WeeklyResult result;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.MMMd();
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${df.format(result.weekStart)} – ${df.format(result.weekEnd)}',
                style: AppTheme.body
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              Text(formatCents(result.poolAmount), style: AppTheme.headline),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${result.winners.length} won '
            '(+${formatCents(result.perWinner)} each) • '
            '${result.losers.length} missed',
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.name,
    required this.progress,
    this.photoUrl,
    this.goal,
  });

  final String name;
  final int progress;
  final String? photoUrl;
  final int? goal;

  @override
  Widget build(BuildContext context) {
    final hit = goal != null && progress >= goal!;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          AvatarCircle(
            size: 36,
            photoUrl: photoUrl,
            initial: name,
            ringColor: hit ? AppTheme.foreground : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: AppTheme.body)),
          Text(
            goal == null ? '$progress' : '$progress / $goal',
            style: AppTheme.body.copyWith(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

