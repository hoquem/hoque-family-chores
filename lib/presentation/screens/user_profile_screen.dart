// lib/presentation/screens/user_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_notifier.dart';
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

  /// Shows the family's invite code so it can be shared with someone joining.
  /// The code lives on the family, not the user, so it's fetched on demand.
  Future<void> _showInviteCode(
    BuildContext context,
    WidgetRef ref,
    FamilyId familyId,
  ) async {
    String? code;
    try {
      final family = await ref.read(familyNotifierProvider(familyId).future);
      code = family.inviteCode;
    } catch (_) {
      code = null;
    }
    if (!context.mounted) return;
    if (code == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load the invite code.")),
      );
      return;
    }
    final inviteCode = code;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Invite someone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this code so they can join your family:'),
            const SizedBox(height: 16),
            SelectableText(
              inviteCode,
              style: Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteCode));
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite code copied')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  /// Confirms intent, then leaves the family. On success the profile stream
  /// clears the user's ``familyId`` — this row disappears and the Family tab
  /// routes to onboarding; on failure we surface the reason.
  Future<void> _confirmAndLeave(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave family?'),
        content: const Text(
          "You'll lose access to this family's tasks and treats. Your star "
          'balance stays on your account. You can join again with an invite '
          'code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final error = await ref.read(authNotifierProvider.notifier).leaveFamily();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'You left the family.'),
        backgroundColor:
            error == null ? null : Theme.of(context).colorScheme.error,
      ),
    );
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

          // Inviting and leaving are both rare, family-membership actions, so
          // they live here rather than cluttering the Family screen (which is
          // now just the member roster). Shown only when in a family.
          if (currentUser.familyId.value.isNotEmpty) ...[
            ListTile(
              leading: const Icon(Icons.person_add_alt),
              title: const Text('Invite someone'),
              onTap: () => _showInviteCode(context, ref, currentUser.familyId),
            ),
            ListTile(
              leading: const Icon(Icons.group_remove),
              title: const Text('Leave family'),
              onTap: () => _confirmAndLeave(context, ref),
            ),
          ],

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
