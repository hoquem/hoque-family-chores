import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/widgets/hero_panel.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/usecases/family/join_family_usecase.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/member_profile_provider.dart';
import 'package:hoque_family_chores/presentation/screens/family_onboarding_screen.dart';
import 'package:hoque_family_chores/presentation/motion/animated_star_count.dart';
import 'package:hoque_family_chores/presentation/screens/member_detail_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/add_managed_child_sheet.dart';
import 'package:hoque_family_chores/presentation/widgets/help_button.dart';
import 'package:hoque_family_chores/presentation/widgets/share_invite_button.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: 'Invite someone',
            onPressed: () => _showInviteCode(context, ref),
          ),
          const HelpButton(content: kFamilyHelp),
        ],
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
              HeroPanel(
                // Builder: the styles below must resolve inside the panel's theme.
                child: Builder(builder: (context) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
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
              // A second, always-visible entry point next to the app bar's
              // bare icon: this one shares directly in a single tap, while
              // the icon still opens the dialog below for Copy.
              Center(
                child: ShareInviteButton(
                  inviteCode: family.inviteCode,
                  source: 'family_tab',
                  label: 'Invite someone',
                ),
              ),
                    ],
                  ),
                )),
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
                data: (members) => Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < members.length; i++) ...[
                        _MemberRow(snapshot: members[i]),
                        if (i < members.length - 1)
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: context.tokens.line,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              if (currentUser.role.isAdmin)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('family_add_child_button'),
                    icon: const Icon(Icons.child_care),
                    label: const Text('Add a child without a phone'),
                    onPressed: () => showAddManagedChildSheet(context, ref,
                        familyId: currentUser.familyId, source: 'family_tab'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the family's invite code so it can be shared with someone joining.
  /// Kept as an on-demand action rather than an always-on card — inviting is
  /// rare, but this is where people look for it.
  Future<void> _showInviteCode(BuildContext context, WidgetRef ref) async {
    String? code;
    try {
      final family =
          await ref.read(familyNotifierProvider(currentUser.familyId).future);
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
            // The code is the only thing guarding the family's data and
            // cannot be changed yet, and Share makes it easy to post
            // anywhere.
            const Text('Share this code only with people joining your family:'),
            const SizedBox(height: 16),
            // Grouped for reading aloud, and wrapped rather than clipped: a
            // twelve-character code at headline size does not fit one line on
            // a small phone, and a code you can only see two thirds of is no
            // code at all. Whatever the reader does with the spaces, the join
            // screen normalises them away.
            SelectableText(
              formatInviteCode(inviteCode),
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                    letterSpacing: 2,
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
          // Builder: the share sheet on iPad is a popover anchored to this
          // button, so it needs the button's own context for its position.
          Builder(
            builder: (buttonContext) => FilledButton(
              onPressed: () {
                final box = buttonContext.findRenderObject() as RenderBox?;
                final origin = box == null
                    ? null
                    : box.localToGlobal(Offset.zero) & box.size;
                Navigator.of(dialogContext).pop();
                shareInvite(
                  context,
                  ref,
                  inviteCode: inviteCode,
                  source: 'dialog',
                  origin: origin,
                );
              },
              child: const Text('Share invite'),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of the member list. Shows the member's live profile so stars and
/// the "No phone" note follow the server; the list's one-shot snapshot is only
/// what is shown until the stream's first event.
class _MemberRow extends ConsumerWidget {
  const _MemberRow({required this.snapshot});

  final User snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(memberProfileProvider(snapshot.id));
    ref.listen(memberProfileProvider(snapshot.id), (_, next) {
      if (next.hasError) {
        logger.e('FamilyScreen: live profile failed',
            error: next.error, stackTrace: next.stackTrace);
      }
    });
    // The snapshot stands in only while the stream has not produced anything.
    if (profile.hasValue && profile.valueOrNull == null) {
      return ListTile(
        leading: UserAvatar(user: snapshot),
        title: Text(snapshot.name),
        subtitle: const Text('No longer in this family'),
      );
    }
    final member = profile.valueOrNull ?? snapshot;
    final updateFailed = profile.hasError;
    return ListTile(
      leading: UserAvatar(user: member),
      title: Text(member.name),
      subtitle: updateFailed
          ? Text("Couldn't update",
              style: TextStyle(color: Theme.of(context).colorScheme.error))
          : Text(member.isManaged
              ? '${member.role.displayName} · No phone'
              : member.role.displayName),
      trailing: DefaultTextStyle(
        style: Theme.of(context).textTheme.titleMedium!,
        child: AnimatedStarCount(member.points.toInt()),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MemberDetailScreen(member: member),
        ),
      ),
    );
  }
}
