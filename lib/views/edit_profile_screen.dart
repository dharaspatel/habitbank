import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/primary_button.dart';
import '../widgets/section.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
  }

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
    final preview = vm.pickedPhoto;
    final url = vm.profile?.photoUrl;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppTheme.background,
        border: null,
        middle: Text('Edit profile'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: GestureDetector(
                onTap: vm.busy ? null : vm.pickPhoto,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.subtle,
                    image: preview != null
                        ? DecorationImage(
                            image: FileImage(preview), fit: BoxFit.cover)
                        : (url != null
                            ? DecorationImage(
                                image: NetworkImage(url), fit: BoxFit.cover)
                            : null),
                  ),
                  child: (preview == null && url == null)
                      ? const Icon(CupertinoIcons.person,
                          size: 36, color: AppTheme.muted)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: CupertinoButton(
                onPressed: vm.busy ? null : vm.pickPhoto,
                child:
                    const Text('Change photo', style: AppTheme.caption),
              ),
            ),
            const SectionHeader('Display name'),
            CupertinoTextField(
              controller: _name,
              placeholder: 'Your name',
              padding: const EdgeInsets.all(14),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Save',
              busy: vm.busy,
              onPressed: vm.busy
                  ? null
                  : () async {
                      await vm.save(name: _name.text.trim());
                      if (vm.error == null && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
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
