import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/repositories/auth_repository.dart';
import 'mock_auth_repository.dart';

void main() {
  test('signInWithGoogle sets currentUser and emits on authStateChanges',
      () async {
    final AuthRepository repo = MockAuthRepository();
    final emissions = <dynamic>[];
    final sub = repo.authStateChanges.listen(emissions.add);

    final user = await repo.signInWithGoogle();

    expect(user, isNotNull);
    expect(repo.currentUser, isNotNull);
    await Future<void>.delayed(Duration.zero);
    expect(emissions.last, isNotNull);
    await sub.cancel();
  });

  test('signInWithApple sets currentUser', () async {
    final AuthRepository repo = MockAuthRepository();
    final user = await repo.signInWithApple();
    expect(user, isNotNull);
    expect(repo.currentUser, isNotNull);
  });
}
