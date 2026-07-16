import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

/// Account security: shows how the user signs in and, for email/password
/// accounts, lets them change the password.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _saving = false;
  String? _error;

  static const _providerNames = {
    'password': 'Email & Password',
    'apple.com': 'Apple',
    'google.com': 'Google',
  };

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    // The email comes from the Firebase session, not the Firestore profile:
    // password changes must work even while the profile is still loading.
    final email =
        ref.read(authRepositoryProvider).currentUser?.email as String?;
    if (email == null) {
      setState(() => _error = 'No signed-in account');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await ref.read(changePasswordUseCaseProvider).call(
          email: Email(email),
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = failure.message;
      }),
      (_) {
        setState(() => _saving = false);
        _currentPasswordController.clear();
        _newPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerIds = ref.watch(authRepositoryProvider).currentProviderIds;
    final hasPassword = providerIds.contains('password');
    final providerLabels = providerIds
        .map((id) => _providerNames[id] ?? id)
        .join(', ');

    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('Sign-in method'),
            subtitle: Text(
              providerLabels.isEmpty ? 'Unknown' : providerLabels,
            ),
          ),
          const Divider(),
          if (!hasPassword)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Your password is managed by your sign-in provider, '
                'so there is nothing to change here.',
              ),
            )
          else ...[
            TextField(
              key: const Key('current_password'),
              controller: _currentPasswordController,
              decoration: const InputDecoration(labelText: 'Current password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('new_password'),
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: 'New password'),
              obscureText: true,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _error!,
                  style: TextStyle(color: context.tokens.brick),
                ),
              ),
            const SizedBox(height: 24),
            _saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _changePassword,
                    child: const Text('Change Password'),
                  ),
          ],
        ],
      ),
    );
  }
}
