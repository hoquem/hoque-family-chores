import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/usecases/family/join_family_usecase.dart'
    show formatInviteCode;
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/just_created_family_notifier.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/share_invite_button.dart';

/// Shown once, right after an adult creates a family: the invite code with a
/// primary Share action, so a new family is never left with just its
/// creator.
///
/// Only reachable from `FamilyGate`, which shows this in place of
/// `MainScreen` while `justCreatedFamilyProvider` holds the family just
/// created (see that provider's doc for why this cannot simply be a step
/// inside `FamilyOnboardingScreen`). Never shown after joining — see
/// `FamilyOnboardingNotifier.joinFamily`, which does not set that provider.
///
/// Always skippable: "Maybe later" (or "Done", once something has been
/// shared) continues straight to Home. This is never a dead end.
class InviteYourFamilyScreen extends ConsumerStatefulWidget {
  const InviteYourFamilyScreen({super.key, required this.family});

  final FamilyEntity family;

  @override
  ConsumerState<InviteYourFamilyScreen> createState() =>
      _InviteYourFamilyScreenState();
}

class _InviteYourFamilyScreenState
    extends ConsumerState<InviteYourFamilyScreen> {
  bool _hasShared = false;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authNotifierProvider).user?.id.value;
    if (userId != null) {
      ref.read(analyticsProvider).log(
            AnalyticsEventName.inviteStepShown,
            userId: userId,
            familyId: widget.family.id.value,
          );
    }
  }

  void _continue() {
    // A share already answers "did this step do its job?" — only count a
    // skip when nothing was shared.
    if (!_hasShared) {
      final userId = ref.read(authNotifierProvider).user?.id.value;
      if (userId != null) {
        ref.read(analyticsProvider).log(
              AnalyticsEventName.inviteStepSkipped,
              userId: userId,
              familyId: widget.family.id.value,
            );
      }
    }
    // Clearing this sends FamilyGate on to MainScreen.
    ref.read(justCreatedFamilyProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      appBar: AppBar(title: const Text('Invite your family')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.family_restroom, size: 64, color: t.inkMuted),
              const SizedBox(height: 16),
              Text(
                'Invite your family',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Chores Star works best with everyone in. Share your family '
                'code so the rest of the family can join.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SelectableText(
                formatInviteCode(widget.family.inviteCode),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              ShareInviteButton(
                inviteCode: widget.family.inviteCode,
                source: 'onboarding',
                onShared: () => setState(() => _hasShared = true),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('invite_step_copy_button'),
                icon: const Icon(Icons.copy),
                label: const Text('Copy'),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: widget.family.inviteCode),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite code copied')),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                key: const Key('invite_step_continue_button'),
                onPressed: _continue,
                child: Text(_hasShared ? 'Done' : 'Maybe later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
