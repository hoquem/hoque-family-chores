import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/invite_card_dismissal_service.dart';
import '../../../domain/value_objects/family_id.dart';

/// Hand-written, not `@riverpod` codegen — a one-method service and its
/// per-family read, not worth a `build_runner` run over unrelated providers.
final inviteCardDismissalServiceProvider =
    Provider<InviteCardDismissalService>((_) => InviteCardDismissalService());

/// When the Home invite card was last dismissed for [familyId], or null if
/// never. Invalidate this after a dismissal to pick it back up.
final inviteCardDismissedAtProvider =
    FutureProvider.family<DateTime?, FamilyId>(
  (ref, familyId) =>
      ref.watch(inviteCardDismissalServiceProvider).dismissedAt(familyId),
);
