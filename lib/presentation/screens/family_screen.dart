import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/family_onboarding_screen.dart';
import 'package:hoque_family_chores/presentation/widgets/help_button.dart';
import 'package:hoque_family_chores/presentation/widgets/user_avatar.dart';
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
      return FamilyOnboardingScreen(currentUser: currentUser);
    }

    return _FamilyDetailsView(currentUser: currentUser);
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
      appBar: AppBar(
        title: const Text('Family'),
        actions: const [HelpButton(content: kFamilyHelp)],
      ),
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
                            leading: UserAvatar(user: member),
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
