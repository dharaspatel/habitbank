import 'package:flutter/cupertino.dart';
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
        trailing: CupertinoButton(
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
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: vm.load),
            SliverToBoxAdapter(child: _GoalCard(vm: vm)),
            const SliverToBoxAdapter(child: SectionHeader('Members')),
            SliverList.separated(
              itemCount: vm.members.length,
              separatorBuilder: (_, __) => const ThinDivider(),
              itemBuilder: (_, i) {
                final m = vm.members[i];
                final progress = vm.progressForUser(m.userId);
                final challenge = vm.myChallenge?.userId == m.userId
                    ? vm.myChallenge
                    : null;
                return _MemberRow(
                  name: m.profile.name.isEmpty ? 'Member' : m.profile.name,
                  progress: progress,
                  goal: challenge?.goalTarget,
                  goalType: challenge?.goalType,
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
                        orElse: () => vm.members.first,
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
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.vm});
  final GroupViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = vm.myChallenge;
    final progress = vm.progressForUser(vm.currentUserId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This week', style: AppTheme.caption),
          const SizedBox(height: 4),
          if (c == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Set a goal', style: AppTheme.balanceLarge),
                const SizedBox(height: 12),
                SecondaryButton(
                    label: 'Set weekly goal',
                    onPressed: () => _openGoalSheet(context)),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$progress / ${c.goalTarget}',
                  style: AppTheme.balanceLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  c.goalType == GoalType.workouts
                      ? 'workouts • lose ${c.deductionX} if missed'
                      : 'minutes • lose ${c.deductionX} if missed',
                  style: AppTheme.caption,
                ),
                const SizedBox(height: 12),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child:
                      const Text('Edit goal', style: AppTheme.caption),
                  onPressed: () => _openGoalSheet(context),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _openGoalSheet(BuildContext context) {
    final vmRef = context.read<GroupViewModel>();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => _GoalSheet(vm: vmRef),
    );
  }
}

class _GoalSheet extends StatefulWidget {
  const _GoalSheet({required this.vm});
  final GroupViewModel vm;

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late GoalType _type = widget.vm.myChallenge?.goalType ?? GoalType.workouts;
  late int _target = widget.vm.myChallenge?.goalTarget ?? 3;
  late int _deduction = widget.vm.myChallenge?.deductionX ?? 10;

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: const Text('Weekly goal'),
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
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Target'),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() {
                  _target = (_target - (_type == GoalType.minutes ? 30 : 1))
                      .clamp(1, 1000);
                }),
                child: const Icon(CupertinoIcons.minus_circle),
              ),
              SizedBox(
                width: 56,
                child: Text('$_target',
                    textAlign: TextAlign.center,
                    style: AppTheme.headline),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() {
                  _target = (_target + (_type == GoalType.minutes ? 30 : 1))
                      .clamp(1, 1000);
                }),
                child: const Icon(CupertinoIcons.plus_circle),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Penalty'),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () =>
                    setState(() => _deduction = (_deduction - 5).clamp(5, 200)),
                child: const Icon(CupertinoIcons.minus_circle),
              ),
              SizedBox(
                width: 56,
                child: Text('$_deduction',
                    textAlign: TextAlign.center,
                    style: AppTheme.headline),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () =>
                    setState(() => _deduction = (_deduction + 5).clamp(5, 200)),
                child: const Icon(CupertinoIcons.plus_circle),
              ),
            ],
          ),
        ],
      ),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () async {
            await widget.vm.setGoal(
                type: _type, target: _target, deductionX: _deduction);
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

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.name,
    required this.progress,
    this.goal,
    this.goalType,
  });

  final String name;
  final int progress;
  final int? goal;
  final GoalType? goalType;

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
              child: const Icon(CupertinoIcons.camera, color: AppTheme.muted),
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
