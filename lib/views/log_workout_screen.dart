import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../viewmodels/log_workout_viewmodel.dart';
import '../widgets/primary_button.dart';
import '../widgets/section.dart';

class LogWorkoutScreen extends StatefulWidget {
  const LogWorkoutScreen({super.key});

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  late final TextEditingController _typeController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<LogWorkoutViewModel>();
    _typeController = TextEditingController(text: vm.workoutType);
  }

  @override
  void dispose() {
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LogWorkoutViewModel>();
    if (vm.saved != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
    }
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppTheme.background,
        border: null,
        middle: Text('Log workout'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SectionHeader('Photo proof'),
            GestureDetector(
              onTap: vm.busy ? null : vm.capturePhoto,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppTheme.subtle,
                  borderRadius: BorderRadius.circular(12),
                  image: vm.photo == null
                      ? null
                      : DecorationImage(
                          image: FileImage(vm.photo!),
                          fit: BoxFit.cover,
                        ),
                ),
                child: vm.photo != null
                    ? null
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.camera,
                                size: 32, color: AppTheme.muted),
                            SizedBox(height: 8),
                            Text('Tap to capture', style: AppTheme.caption),
                          ],
                        ),
                      ),
              ),
            ),
            const SectionHeader('Type'),
            CupertinoTextField(
              controller: _typeController,
              placeholder: 'general',
              padding: const EdgeInsets.all(14),
              onChanged: vm.setType,
            ),
            const SectionHeader('Duration'),
            Row(
              children: [
                Expanded(
                  child: Text('${vm.durationMinutes} min',
                      style: AppTheme.headline),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      vm.setDuration((vm.durationMinutes - 5).clamp(5, 600)),
                  child: const Icon(CupertinoIcons.minus_circle),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      vm.setDuration((vm.durationMinutes + 5).clamp(5, 600)),
                  child: const Icon(CupertinoIcons.plus_circle),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Save',
              busy: vm.busy,
              onPressed: vm.canSubmit ? vm.submit : null,
            ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(vm.error!,
                    style: const TextStyle(
                        color: CupertinoColors.systemRed, fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
}
