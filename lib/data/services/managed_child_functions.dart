import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/repositories/managed_child_repository.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import 'callable.dart';

/// [ManagedChildRepository] over the managed-child Cloud Functions.
class ManagedChildFunctions implements ManagedChildRepository {
  ManagedChildFunctions([FirebaseFunctions? functions]) : _override = functions;

  final FirebaseFunctions? _override;

  // Resolved lazily, as in EconomyFunctions: constructing this must not need
  // a live Firebase app.
  FirebaseFunctions get _functions => _override ?? FirebaseFunctions.instance;

  @override
  Future<UserId> addManagedChild(FamilyId familyId, String name) async {
    final data = await callFunction(_functions, 'addManagedChild', {
      'familyId': familyId.value,
      'name': name,
    });
    return UserId(data!['childId'] as String);
  }

  @override
  Future<void> removeManagedChild(FamilyId familyId, UserId childId) =>
      callFunction(_functions, 'removeManagedChild', {
        'familyId': familyId.value,
        'childId': childId.value,
      });

  @override
  Future<LinkCode> createLinkCode(FamilyId familyId, UserId childId) async {
    final data = await callFunction(_functions, 'createLinkCode', {
      'familyId': familyId.value,
      'childId': childId.value,
    });
    return LinkCode(
      code: data!['code'] as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (data['expiresAt'] as num).toInt(),
      ),
    );
  }

  @override
  Future<String> redeemLinkCode(String code) async {
    final data = await callFunction(_functions, 'redeemLinkCode', {
      'code': code,
    });
    return data!['token'] as String;
  }

  @override
  Future<void> completeLink() async {
    await callFunction(_functions, 'completeLink', {});
  }
}
