import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/family.dart';

/// "This session just created a family, with nowhere else to remember it."
///
/// Hand-written, not `@riverpod` codegen, for the same reason
/// `ReviewPromptPendingSignal` is: one value with two mutators does not
/// need a generated provider file, and this also avoids a `build_runner`
/// run over unrelated providers for a change this small.
///
/// Set by `FamilyOnboardingNotifier.createFamily` right after a create
/// succeeds. [FamilyGate] watches it: while it holds a family, the gate
/// shows `InviteYourFamilyScreen` for that family instead of `MainScreen`,
/// even though the user's profile stream has already updated `familyId` and
/// would otherwise route straight past onboarding. "Maybe later"/"Done" on
/// that screen calls [clear], which sends the gate on to `MainScreen`.
///
/// Never set by `joinFamily` — the invite step is for whoever just created a
/// family, not whoever just joined one.
class JustCreatedFamilyNotifier extends Notifier<FamilyEntity?> {
  @override
  FamilyEntity? build() => null;

  /// Records the family just created, arming the invite step.
  void markCreated(FamilyEntity family) => state = family;

  /// Clears the signal once the invite step has been shown and left,
  /// whether or not the family was actually invited.
  void clear() {
    if (state != null) state = null;
  }
}

final justCreatedFamilyProvider =
    NotifierProvider<JustCreatedFamilyNotifier, FamilyEntity?>(
  JustCreatedFamilyNotifier.new,
);
