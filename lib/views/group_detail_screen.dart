import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/challenge.dart';
import '../models/workout_log.dart';
import '../services/group_service.dart';
import '../services/supabase_service.dart';
import '../services/workout_service.dart';
import '../viewmodels/group_viewmodel.dart';
import '../viewmodels/log_workout_viewmodel.dart';
import '../viewmodels/weekly_results_viewmodel.dart';
import '../widgets/primary_button.dart';
import '../widgets/section.dart';
import 'log_workout_screen.dart';
import 'weekly_results_screen.dart';

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
              child: const Icon(CupertinoIcons.share,
                  color: AppTheme.foreground),
              onPressed: () => _showInviteSheet(context, vm),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.chart_bar,
                  color: AppTheme.foreground),
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => WeeklyResultsViewModel(
                        GroupService(SupabaseService.client),
                        vm.group.id,
                      )..load(),
                      child: const WeeklyResultsScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: vm.load),
            SliverToBoxAdapter(child: _ChallengeCard(vm: vm)),
            const SliverToBoxAdapter(child: SectionHeader('Members')),
            SliverList.separated(
              itemCount: vm.members.length,
              separatorBuilder: (_, __) => const ThinDivider(),
              itemBuilder: (_, i) {
                final m = vm.members[i];
                return _MemberRow(
                  name: m.profile.name.isEmpty ? 'Member' : m.profile.name,
                  progress: vm.progressForUser(m.userId),
                  goal: vm.challenge?.goalTarget,
                );
              },
            ),
            const SliverToBoxAdapter(child: SectionHeader('Activity')),
            if (vm.logs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No workouts logged yet.',
                      style: AppTheme.body.copyWith(color: AppTheme.muted)),
                ),
              )
            else
              SliverList.separated(
                itemCount: vm.logs.length,
                separatorBuilder: (_, __) => const ThinDivider(),
                itemBuilder: (_, i) => _LogRow(
                  log: vm.logs[i],
                  memberName: vm.members
                      .firstWhere(
                        (m) => m.userId == vm.logs[i].userId,
                        orElse: () => vm.members.isEmpty
                            ? throw StateError('no members')
                            : vm.members.first,
                      )
                      .profile
                      .name,
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: PrimaryButton(
                  label: 'Log workout',
                  onPressed: () => _openLog(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLog(BuildContext context) {
    final vm = context.read<GroupViewModel>();
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => LogWorkoutViewModel(
            service: WorkoutService(SupabaseService.client),
            userId: vm.currentUserId,
            groupId: vm.group.id,
          ),
          child: const LogWorkoutScreen(),
        ),
      ),
    ).then((_) => vm.load());
  }

  void _showInviteSheet(BuildContext context, GroupViewModel vm) {
    final code = vm.group.inviteCode;
    final url = vm.group.inviteUrl;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetCtx) => CupertinoActionSheet(
        title: const Text('Invite friends'),
        message: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(code,
                  style: AppTheme.balanceLarge.copyWith(fontSize: 36)),
              const SizedBox(height: 8),
              Text(url, style: AppTheme.caption),
            ],
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
            },
            child: const Text('Copy invite link'),
          ),
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

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.vm});
  final GroupViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = vm.challenge;
    final progress = vm.progressForUser(vm.currentUserId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This week', style: AppTheme.caption),
          const SizedBox(height: 4),
          if (c == null)
            const Text('No challenge yet', style: AppTheme.headline)
          else ...[
            Text('$progress / ${c.goalTarget}', style: AppTheme.balanceLarge),
            const SizedBox(height: 4),
            Text(
              c.goalType == GoalType.workouts
                  ? 'workouts • stake ${c.deductionX}/wk'
                  : 'minutes • stake ${c.deductionX}/wk',
              style: AppTheme.caption,
            ),
            if (vm.isOwner)
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('Edit challenge', style: AppTheme.caption),
                onPressed: () => _openEdit(context),
              ),
          ],
        ],
      ),
    );
  }

  void _openEdit(BuildContext context) {
    final vmRef = context.read<GroupViewModel>();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => _ChallengeEditor(vm: vmRef),
    );
  }
}

class _ChallengeEditor extends StatefulWidget {
  const _ChallengeEditor({required this.vm});
  final GroupViewModel vm;

  @override
  State<_ChallengeEditor> createState() => _ChallengeEditorState();
}

class _ChallengeEditorState extends State<_ChallengeEditor> {
  late GoalType _type =
      widget.vm.challenge?.goalType ?? GoalType.workouts;
  late int _target = widget.vm.challenge?.goalTarget ?? 3;
  late int _stake = widget.vm.challenge?.deductionX ?? 10;

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: const Text('Group challenge'),
      message: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoSegmentedControl<GoalType>(
            groupValue: _type,
            onValueChanged: (v) => setState(() => _type = v),
            children: const {
              GoalType.workouts: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Workouts'),
              ),
              GoalType.minutes: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Minutes'),
              ),
            },
          ),
          const SizedBox(height: 12),
          _StepperRow(
            label: 'Target',
            value: _target,
            step: _type == GoalType.minutes ? 30 : 1,
            onChange: (v) => setState(() => _target = v),
          ),
          _StepperRow(
            label: 'Stake / week',
            value: _stake,
            step: 5,
            onChange: (v) => setState(() => _stake = v),
          ),
        ],
      ),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () async {
            await widget.vm.updateChallenge(
                type: _type, target: _target, stakePerWeek: _stake);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
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
    return Row(
      children: [
        Text(label),
        const Spacer(),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => onChange((value - step).clamp(1, 1000)),
          child: const Icon(CupertinoIcons.minus_circle),
        ),
        SizedBox(
          width: 56,
          child: Text('$value',
              textAlign: TextAlign.center, style: AppTheme.headline),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => onChange((value + step).clamp(1, 1000)),
          child: const Icon(CupertinoIcons.plus_circle),
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.name,
    required this.progress,
    this.goal,
  });

  final String name;
  final int progress;
  final int? goal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
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

class _LogRow extends StatelessWidget {
  const _LogRow({required this.log, required this.memberName});
  final WorkoutLog log;
  final String memberName;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.MMMd().add_jm().format(log.loggedAt.toLocal());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (log.photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(log.photoUrl!,
                  width: 44, height: 44, fit: BoxFit.cover),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.subtle,
                borderRadius: BorderRadius.circular(6),
              ),
              child:
                  const Icon(CupertinoIcons.camera, color: AppTheme.muted),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(memberName, style: AppTheme.body),
                Text('${log.durationMinutes} min • ${log.workoutType}',
                    style: AppTheme.caption),
              ],
            ),
          ),
          Text(time, style: AppTheme.caption),
        ],
      ),
    );
  }
}
