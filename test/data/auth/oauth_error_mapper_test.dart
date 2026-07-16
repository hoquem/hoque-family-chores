import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/data/auth/oauth_error_mapper.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

void main() {
  test('Apple sheet cancellation maps to SIGN_IN_CANCELLED, not an error', () {
    // Dismissing the Apple sheet (ASAuthorizationError 1001) is a choice,
    // not a failure — it must map to the same silent cancel code Google uses.
    final result = mapAppleAuthorizationError(
      const SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.canceled,
        message: 'The operation couldn’t be completed. '
            '(com.apple.AuthenticationServices.AuthorizationError error 1001.)',
      ),
    );

    expect(result.code, 'SIGN_IN_CANCELLED');
  });

  test('other Apple authorization failures surface a real error', () {
    final result = mapAppleAuthorizationError(
      const SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.failed,
        message: 'boom',
      ),
    );

    expect(result.code, isNot('SIGN_IN_CANCELLED'));
    expect(result.message, contains('Apple'));
    expect(result.message, contains('boom'));
  });

  test('maps account-exists-with-different-credential to guidance message', () {
    final result = mapOAuthError(
      FirebaseAuthException(code: 'account-exists-with-different-credential'),
    );

    expect(result, isA<AuthException>());
    expect(result.code, 'ACCOUNT_EXISTS_DIFFERENT_CREDENTIAL');
    expect(result.message, contains('different sign-in method'));
  });

  test('passes other codes through with the original message', () {
    final result = mapOAuthError(
      FirebaseAuthException(code: 'network-request-failed', message: 'offline'),
    );

    expect(result.code, 'network-request-failed');
    expect(result.message, contains('offline'));
  });
}
