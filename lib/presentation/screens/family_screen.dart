import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_onboarding_notifier.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/utils/logger.dart';

/// Family tab: create/join a family, or view the current family's details.
class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    logger.d('FamilyScreen: Building screen');

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Family')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (currentUser.familyId.value.isEmpty) {
      return _FamilyOnboardingView(currentUser: currentUser);
    }

    return _FamilyDetailsView(currentUser: currentUser);
  }
}

/// Shown when the user has no family yet: create one or join with a code.
class _FamilyOnboardingView extends ConsumerStatefulWidget {
  final User currentUser;

  const _FamilyOnboardingView({required this.currentUser});

  @override
  ConsumerState<_FamilyOnboardingView> createState() =>
      _FamilyOnboardingViewState();
}

class _FamilyOnboardingViewState extends ConsumerState<_FamilyOnboardingView> {
  final _familyNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _joinAsParent = false;

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
          role: _joinAsParent ? UserRole.parent : UserRole.child,
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
      appBar: AppBar(title: const Text('Family')),
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
                  SwitchListTile(
                    key: const Key('join_as_parent_switch'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('I am a parent/guardian'),
                    value: _joinAsParent,
                    onChanged: (value) =>
                        setState(() => _joinAsParent = value),
                  ),
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

/// Shown when the user belongs to a family: details, invite code, members.
class _FamilyDetailsView extends ConsumerWidget {
  final User currentUser;

  const _FamilyDetailsView({required this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyNotifierProvider(currentUser.familyId));
    final membersAsync =
        ref.watch(familyMembersNotifierProvider(currentUser.familyId));

    return Scaffold(
      appBar: AppBar(title: const Text('Family')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(familyNotifierProvider(currentUser.familyId));
          ref.invalidate(familyMembersNotifierProvider(currentUser.familyId));
        },
        child: familyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [Text('Could not load family: $error')],
          ),
          data: (family) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                family.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (family.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  family.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 16),
              if (family.inviteCode.isNotEmpty)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.key),
                    title: const Text('Invite code'),
                    subtitle: Text(
                      family.inviteCode,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy invite code',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: family.inviteCode),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invite code copied'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Members',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              membersAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Could not load members: $error'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(
                        familyMembersNotifierProvider(currentUser.familyId),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
                data: (members) => Column(
                  children: members
                      .map(
                        (member) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                member.name.isNotEmpty
                                    ? member.name[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(member.name),
                            subtitle: Text(member.role.displayName),
                            trailing: Text(
                              '${member.points.toInt()} ⭐',
                              style:
                                  Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
