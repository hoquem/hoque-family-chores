import 'package:firebase_auth/firebase_auth.dart';

import '../../core/error/exceptions.dart';

/// Translates a [FirebaseAuthException] raised during OAuth sign-in into the
/// app's [AuthException].
///
/// The app deliberately does not auto-link providers: when an email already
/// belongs to a different provider the user is told which provider to use
/// rather than having the credentials silently merged.
///
/// :param e: the exception raised by Firebase Auth.
/// :returns: the equivalent :class:`AuthException`.
AuthException mapOAuthError(FirebaseAuthException e) {
  if (e.code == 'account-exists-with-different-credential') {
    return const AuthException(
      'This email is already registered with a different sign-in method. '
      'Please use the provider you signed up with.',
      code: 'ACCOUNT_EXISTS_DIFFERENT_CREDENTIAL',
    );
  }
  return AuthException('OAuth sign-in failed: ${e.message}', code: e.code);
}
