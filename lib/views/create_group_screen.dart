import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/challenge.dart';
import '../services/group_service.dart';
import '../services/supabase_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/create_group_viewmodel.dart';
import '../widgets/primary_button.dart';
import '../widgets/section.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _name = TextEditingController();
  GoalType _goalType = GoalType.workouts;
  int _target = 3;
  int _stake = 10;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    return ChangeNotifierProvider(
      create: (_) => CreateGroupViewModel(
          GroupService(SupabaseService.client), auth.userId!),
      child: Consumer<CreateGroupViewModel>(
        builder: (context, vm, _) {
          if (vm.created != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            });
          }
          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              backgroundColor: AppTheme.background,
              border: null,
              middle: Text('New group'),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SectionHeader('Group name'),
                  CupertinoTextField(
                    controller: _name,
                    placeholder: 'Sunrise crew',
                    padding: const EdgeInsets.all(14),
                  ),
                  const SectionHeader('Goal type'),
                  CupertinoSegmentedControl<GoalType>(
                    groupValue: _goalType,
                    onValueChanged: (v) => setState(() {
                      _goalType = v;
                      _target = v == GoalType.minutes ? 90 : 3;
                    }),
                    children: const {
                      GoalType.workouts: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Text('Workouts'),
                      ),
                      GoalType.minutes: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Text('Minutes'),
                      ),
                    },
                  ),
                  const SectionHeader('Weekly target'),
                  _Stepper(
                    value: _target,
                    suffix: _goalType == GoalType.minutes ? 'min' : '',
                    step: _goalType == GoalType.minutes ? 30 : 1,
                    min: 1,
                    max: 1000,
                    onChange: (v) => setState(() => _target = v),
                  ),
                  const SectionHeader('Weekly stake (virtual)'),
                  _Stepper(
                    value: _stake,
                    step: 5,
                    min: 5,
                    max: 200,
                    onChange: (v) => setState(() => _stake = v),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Create',
                    busy: vm.busy,
                    onPressed: vm.busy
                        ? null
                        : () => vm.create(
                              name: _name.text,
                              goalType: _goalType,
                              goalTarget: _target,
                              stakePerWeek: _stake,
                            ),
                  ),
                  if (vm.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(vm.error!,
                          style: const TextStyle(
                              color: CupertinoColors.systemRed,
                              fontSize: 13)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onChange,
    required this.min,
    required this.max,
    required this.step,
    this.suffix = '',
  });

  final int value;
  final int min;
  final int max;
  final int step;
  final String suffix;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => onChange((value - step).clamp(min, max)),
            child: const Icon(CupertinoIcons.minus_circle),
          ),
          Expanded(
            child: Center(
              child: Text(
                suffix.isEmpty ? '$value' : '$value $suffix',
                style: AppTheme.headline,
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => onChange((value + step).clamp(min, max)),
            child: const Icon(CupertinoIcons.plus_circle),
          ),
        ],
      ),
    );
  }
}
