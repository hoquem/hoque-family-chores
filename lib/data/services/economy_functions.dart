import 'package:cloud_functions/cloud_functions.dart';

import '../../core/error/exceptions.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/task_id.dart';

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

  Future<void> approveTask(FamilyId familyId, TaskId taskId) => _call(
        'approveTask',
        {'familyId': familyId.value, 'taskId': taskId.value},
      );

  /// Returns the new redemption's id.
  Future<String> claimReward(FamilyId familyId, String rewardId) async {
    final data = await _call('claimReward', {
      'familyId': familyId.value,
      'rewardId': rewardId,
    });
    return (data?['redemptionId'] as String?) ?? '';
  }

  Future<void> settleRedemption(
    FamilyId familyId,
    String redemptionId, {
    required bool happened,
  }) =>
      _call('settleRedemption', {
        'familyId': familyId.value,
        'redemptionId': redemptionId,
        'happened': happened,
      });

  Future<Map<String, dynamic>?> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call(data);
      return (result.data as Map?)?.cast<String, dynamic>();
    } on FirebaseFunctionsException catch (e) {
      throw _map(e);
    } catch (e) {
      throw ServerException('$name failed: $e', code: 'FUNCTION_ERROR');
    }
  }

  DataException _map(FirebaseFunctionsException e) {
    final message = e.message ?? 'Something went wrong.';
    switch (e.code) {
      case 'permission-denied':
        return PermissionException(message, code: e.code);
      case 'not-found':
        return NotFoundException(message, code: e.code);
      case 'failed-precondition':
      case 'invalid-argument':
        return ValidationException(message, code: e.code);
      case 'unauthenticated':
        return AuthException(message, code: e.code);
      default:
        return ServerException(message, code: e.code);
    }
  }
}
