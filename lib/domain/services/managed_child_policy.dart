import '../entities/user.dart';

/// Whether [viewer] may act for [member] on a shared phone: hand them the
/// phone, claim or settle treats for them, link or remove them.
///
/// Mirrors the server's ``requireMayActFor`` (functions/managedChildren.js),
/// which is the real guard; this only decides what the app offers.
///
/// :param viewer: the signed-in user holding the phone.
/// :param member: the family member to act for.
/// :returns: true only for a parent or guardian and a managed child of the
///     same family.
bool canActForMember({required User viewer, required User member}) =>
    viewer.role.isAdmin &&
    member.isManaged &&
    member.familyId == viewer.familyId;
