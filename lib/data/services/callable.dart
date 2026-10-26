import 'package:cloud_functions/cloud_functions.dart';

import '../../core/error/exceptions.dart';

/// Calls the Cloud Function [name] and maps its errors to the app's
/// [DataException] types, so use cases can surface the server's friendly
/// message.
///
/// :param functions: the Functions instance to call through.
/// :param name: the callable's exported name.
/// :param data: the request payload.
/// :returns: the response map, or null when the function returns nothing.
Future<Map<String, dynamic>?> callFunction(
  FirebaseFunctions functions,
  String name,
  Map<String, dynamic> data,
) async {
  try {
    final result = await functions.httpsCallable(name).call(data);
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
