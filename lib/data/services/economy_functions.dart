import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/task_id.dart';
import '../../domain/value_objects/user_id.dart';
import 'callable.dart';

/// Calls the star-economy Cloud Functions.
///
/// Every change to a user's stars happens server-side — the client cannot write
/// `points` — so approving a task (earn), claiming a reward (spend) and settling
/// a claim (refund) all go through these callables. Errors are mapped back to
/// the app's [DataException] types so use cases can surface friendly messages.
class EconomyFunctions {
  EconomyFunctions([FirebaseFunctions? functions]) : _override = functions;

  final FirebaseFunctions? _override;

  // Resolved lazily: constructing this (e.g. inside a repository built with a
  // fake Firestore in a test) must not reach for FirebaseFunctions.instance,
  // which needs a live Firebase app.
  FirebaseFunctions get _functions => _override ?? FirebaseFunctions.instance;

  Future<void> approveTask(FamilyId familyId, TaskId taskId) => callFunction(
    _functions,
    'approveTask',
    {'familyId': familyId.value, 'taskId': taskId.value},
  );

  /// Returns the new redemption's id. [forMemberId] claims for a managed
  /// child on the shared phone.
  Future<String> claimReward(
    FamilyId familyId,
    String rewardId, {
    UserId? forMemberId,
  }) async {
    final data = await callFunction(_functions, 'claimReward', {
      'familyId': familyId.value,
      'rewardId': rewardId,
      if (forMemberId != null) 'forMemberId': forMemberId.value,
    });
    return (data?['redemptionId'] as String?) ?? '';
  }

  Future<void> settleRedemption(
    FamilyId familyId,
    String redemptionId, {
    required bool happened,
    UserId? forMemberId,
  }) => callFunction(_functions, 'settleRedemption', {
    'familyId': familyId.value,
    'redemptionId': redemptionId,
    'happened': happened,
    if (forMemberId != null) 'forMemberId': forMemberId.value,
  });
}
