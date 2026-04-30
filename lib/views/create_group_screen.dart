import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
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

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    return ChangeNotifierProvider(
      create: (_) =>
          CreateGroupViewModel(GroupService(SupabaseService.client), auth.userId!),
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
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Create',
                    busy: vm.busy,
                    onPressed: vm.busy ? null : () => vm.create(_name.text),
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
