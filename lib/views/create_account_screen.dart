import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../services/profile_service.dart';
import '../services/supabase_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/avatar.dart';
import '../widgets/primary_button.dart';
import '../widgets/section.dart';

/// Post-signup profile setup. The auth flow only needs email + password;
/// new users land here so they can pick an avatar and a display name before
/// they reach the home screen.
class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(
        service: ProfileService(SupabaseService.client),
        userId: auth.userId!,
      )..load(),
      child: const _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _name = TextEditingController();
  bool _hydrated = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    if (!_hydrated && vm.profile != null) {
      _hydrated = true;
      _name.text = vm.profile!.name;
    }
    final canSave = _name.text.trim().isNotEmpty && !vm.busy;
    final preview = vm.pickedPhoto;
    final url = vm.profile?.photoUrl;
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppTheme.background,
        border: null,
        middle: Text('Create account'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: vm.busy ? null : vm.pickPhoto,
                child: preview != null
                    ? ClipOval(
                        child: Image.file(preview,
                            width: 120, height: 120, fit: BoxFit.cover),
                      )
                    : AvatarCircle(size: 120, photoUrl: url),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: CupertinoButton(
                onPressed: vm.busy ? null : vm.pickPhoto,
                child:
                    const Text('Add photo', style: AppTheme.caption),
              ),
            ),
            const SectionHeader('Name'),
            CupertinoTextField(
              controller: _name,
              placeholder: 'Your name',
              padding: const EdgeInsets.all(14),
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Next',
                busy: vm.busy,
                busyLabel: 'Saving…',
                onPressed: canSave
                    ? () async {
                        final navigator = Navigator.of(context);
                        await vm.save(name: _name.text.trim());
                        if (vm.error == null) {
                          if (navigator.canPop()) navigator.pop();
                        }
                      }
                    : null,
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
    );
  }
}
