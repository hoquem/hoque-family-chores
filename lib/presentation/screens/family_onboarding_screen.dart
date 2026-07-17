import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_onboarding_notifier.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

/// Shown to a signed-in adult who has no family yet: create one, or join an
/// existing one with an invite code.
///
/// This is both the first-run gate (see [FamilyGate] in main.dart) and the
/// Family tab's empty state. An adult onboarding here is never a child — kids
/// join through the separate pre-auth child-join flow — so the join card offers
/// a parent/guardian choice, not parent/child.
class FamilyOnboardingScreen extends ConsumerStatefulWidget {
  final User currentUser;

  const FamilyOnboardingScreen({super.key, required this.currentUser});

  @override
  ConsumerState<FamilyOnboardingScreen> createState() =>
      _FamilyOnboardingScreenState();
}

class _FamilyOnboardingScreenState
    extends ConsumerState<FamilyOnboardingScreen> {
  final _familyNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  UserRole _joinRole = UserRole.parent;

  @override
  void dispose() {
    _familyNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    final name = _familyNameController.text.trim();
    if (name.isEmpty) return;

    final success = await ref
        .read(familyOnboardingNotifierProvider.notifier)
        .createFamily(name: name, creatorId: widget.currentUser.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Family "$name" created!')),
      );
    }
  }

  Future<void> _joinFamily() async {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) return;

    final success = await ref
        .read(familyOnboardingNotifierProvider.notifier)
        .joinFamily(
          inviteCode: code,
          userId: widget.currentUser.id,
          role: _joinRole,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome to the family!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(familyOnboardingNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family'),
        actions: [
          // The gate has no other way out; a wrong-account sign-in needs an
          // escape.
          IconButton(
            key: const Key('onboarding_sign_out'),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(Icons.family_restroom, size: 64, color: context.tokens.inkMuted),
          const SizedBox(height: 8),
          Text(
            'Set up your family',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Create a new family, or join one with an invite code.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (onboardingState.error != null) ...[
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  onboardingState.error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create a family',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('family_name_field'),
                    controller: _familyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Family name',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('create_family_button'),
                    onPressed:
                        onboardingState.isLoading ? null : _createFamily,
                    icon: const Icon(Icons.add_home),
                    label: const Text('Create family'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You will be the parent/admin of this family.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Join a family',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('invite_code_field'),
                    controller: _inviteCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Invite code',
                      hintText: 'e.g. AB3XY9',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Join as',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  SegmentedButton<UserRole>(
                    key: const Key('join_role_selector'),
                    segments: const [
                      ButtonSegment(
                        value: UserRole.parent,
                        label: Text('Parent'),
                        icon: Icon(Icons.person),
                      ),
                      ButtonSegment(
                        value: UserRole.guardian,
                        label: Text('Guardian'),
                        icon: Icon(Icons.shield_outlined),
                      ),
                    ],
                    selected: {_joinRole},
                    onSelectionChanged: (selection) =>
                        setState(() => _joinRole = selection.first),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const Key('join_family_button'),
                    onPressed: onboardingState.isLoading ? null : _joinFamily,
                    icon: const Icon(Icons.group_add),
                    label: const Text('Join family'),
                  ),
                ],
              ),
            ),
          ),
          if (onboardingState.isLoading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
