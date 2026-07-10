import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/data/auth/oauth_error_mapper.dart';

void main() {
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
