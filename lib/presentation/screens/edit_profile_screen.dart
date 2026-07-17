import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/widgets/user_avatar.dart';

/// Edits the signed-in user's display name.
///
/// The saved profile flows back through the profile stream, so the rest of
/// the app (including [AuthNotifier] state) updates without manual refresh.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  String? _error;
  // The pending avatar choice: null/'' shows the initial, an emoji shows it.
  String? _avatarEmoji;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name cannot be empty');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await ref
        .read(updateUserProfileUseCaseProvider)
        .call(userId: user.id, name: name, avatarEmoji: _avatarEmoji ?? '');

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = failure.message;
      }),
      (_) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        Navigator.of(context).maybePop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_initialized) {
      _nameController.text = user.name;
      _avatarEmoji = user.avatarEmoji;
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  InkWell(
                    key: const Key('edit_avatar'),
                    borderRadius: BorderRadius.circular(40),
                    onTap: () async {
                      final picked = await showAvatarEmojiPicker(
                        context,
                        current: _avatarEmoji,
                      );
                      // null = dismissed; '' = use initial; emoji = chosen.
                      if (picked != null) {
                        setState(() => _avatarEmoji = picked);
                      }
                    },
                    child: UserAvatar(
                      user: user.copyWith(avatarEmoji: _avatarEmoji ?? ''),
                      radius: 40,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to change your avatar',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: _error,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            if (user.email != null)
              Text(
                user.email!.value,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 24),
            _saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
          ],
        ),
      ),
    );
  }
}
