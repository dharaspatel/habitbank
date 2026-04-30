import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../viewmodels/log_workout_viewmodel.dart';
import '../widgets/primary_button.dart';

class LogWorkoutScreen extends StatelessWidget {
  const LogWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LogWorkoutViewModel>();
    if (vm.saved != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
    }
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppTheme.background,
        border: null,
        previousPageTitle: 'Group',
        middle: Text('Log workout'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    color: AppTheme.subtle,
                    child: Image.file(vm.photo, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: vm.busy
                        ? null
                        : () async {
                            await vm.retake();
                          },
                    child: const Text('Retake', style: AppTheme.caption),
                  ),
                  const Spacer(),
                  if (vm.tracksMinutes)
                    _DurationPill(
                      value: vm.durationMinutes,
                      onTap: vm.busy ? null : vm.cycleDuration,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Submit',
                  busy: vm.busy,
                  onPressed: vm.canSubmit ? vm.submit : null,
                ),
              ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(vm.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: CupertinoColors.systemRed, fontSize: 13)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({required this.value, required this.onTap});
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.foreground,
      borderRadius: BorderRadius.circular(999),
      onPressed: onTap,
      child: Text(
        '$value min',
        style: const TextStyle(
          color: AppTheme.background,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
