import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../providers/riverpod/family_notifier.dart';

/// Resolves a family member's display name for a label: 'you' for the viewer,
/// the member's name once the roster has loaded, '…' while it loads.
///
/// Shared so every surface that names a member — the task tile, the chore
/// timeline — says the same thing about the same person.
///
/// :param ref: widget ref used to watch the family roster.
/// :param familyId: the family whose roster to resolve against.
/// :param memberId: the member being named.
/// :param currentUser: the viewer, who is called 'you' rather than by name.
/// :returns: the name to show.
String memberDisplayName(
  WidgetRef ref,
  FamilyId familyId,
  UserId memberId,
  User currentUser,
) {
  if (memberId == currentUser.id) return 'you';
  final membersAsync = ref.watch(familyMembersNotifierProvider(familyId));
  return membersAsync.maybeWhen(
    data: (members) {
      for (final m in members) {
        if (m.id == memberId) return m.name;
      }
      return 'someone in the family';
    },
    orElse: () => '…',
  );
}
