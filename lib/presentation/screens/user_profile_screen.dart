// lib/presentation/screens/user_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/about_screen.dart';
import 'package:hoque_family_chores/presentation/screens/edit_profile_screen.dart';
import 'package:hoque_family_chores/presentation/screens/notifications_screen.dart';
import 'package:hoque_family_chores/presentation/widgets/help_button.dart';
import 'package:hoque_family_chores/presentation/widgets/user_avatar.dart';
import 'package:hoque_family_chores/presentation/screens/security_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  /// Asks for confirmation, then deletes the account. On failure the session
  /// survives and the error from [AuthState.errorMessage] is shown in a
  /// SnackBar.
  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This permanently deletes your account and profile data. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.tokens.brick),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(authNotifierProvider.notifier).deleteAccount();

    if (!context.mounted) return;
    final errorMessage = ref.read(authNotifierProvider).errorMessage;
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = currentUser.name;
    // Children join anonymously and have no email to show.
    final email = currentUser.email?.value ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [HelpButton(content: kProfileHelp)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User profile header
          Center(
            child: Column(
              children: [
                UserAvatar(user: currentUser, radius: 50),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${currentUser.points.value} ⭐ to spend',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),

          // Menu Options
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SecurityScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About & Feedback'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),

          ListTile(
            leading: Icon(Icons.delete_forever, color: context.tokens.brick),
            title: Text(
              'Delete Account',
              style: TextStyle(color: context.tokens.brick),
            ),
            onTap: () => _confirmDeleteAccount(context, ref),
          ),

          const Divider(),
          const SizedBox(height: 16),

          // Logout Button Section — a neutral outline, not a red fill: logging
          // out is routine and reversible, so red is reserved for the one
          // destructive control on this screen (Delete Account).
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.tokens.ink,
                side: BorderSide(color: context.tokens.inkMuted),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) {
                   Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
