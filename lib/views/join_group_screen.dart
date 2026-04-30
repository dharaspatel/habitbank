import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../services/group_service.dart';
import '../services/supabase_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/join_group_viewmodel.dart';
import '../widgets/primary_button.dart';
import '../widgets/section.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    return ChangeNotifierProvider(
      create: (_) =>
          JoinGroupViewModel(GroupService(SupabaseService.client), auth.userId!),
      child: Consumer<JoinGroupViewModel>(
        builder: (context, vm, _) {
          if (vm.joined != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            });
          }
          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              backgroundColor: AppTheme.background,
              border: null,
              middle: Text('Join group'),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SectionHeader('Invite code'),
                  CupertinoTextField(
                    controller: _code,
                    placeholder: 'XXXXXX',
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) =>
                        vm.busy ? null : vm.join(_code.text),
                    padding: const EdgeInsets.all(14),
                    style: AppTheme.headline,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Join',
                      busy: vm.busy,
                      busyLabel: 'Joining…',
                      onPressed: vm.busy ? null : () => vm.join(_code.text),
                    ),
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
        },
      ),
    );
  }
}
