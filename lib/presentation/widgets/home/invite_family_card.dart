import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/share_invite_button.dart';

/// Home card shown while the viewer's family has exactly one member — see
/// `shouldShowInviteCard`. A one-line why, plus the same Share invite flow
/// every other entry point uses (source 'home_card'), and a dismiss action
/// the caller persists (see `InviteCardDismissalService`).
class InviteFamilyCard extends StatelessWidget {
  const InviteFamilyCard({
    super.key,
    required this.inviteCode,
    required this.onDismiss,
  });

  final String inviteCode;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.group_add_outlined, color: t.inkMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite your family',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chores Star works best with everyone in.',
                    style: TextStyle(color: t.inkSoft),
                  ),
                  const SizedBox(height: 12),
                  ShareInviteButton(inviteCode: inviteCode, source: 'home_card'),
                ],
              ),
            ),
            IconButton(
              key: const Key('invite_family_card_dismiss'),
              icon: const Icon(Icons.close),
              tooltip: 'Dismiss',
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
