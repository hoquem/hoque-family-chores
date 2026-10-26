import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/domain/usecases/family/link_child_device_usecase.dart';

import '../../../mocks/mock_auth_repository.dart';
import '../../../mocks/mock_managed_child_repository.dart';

void main() {
  test('redeems the code and signs this phone in as the child', () async {
    final auth = MockAuthRepository();
    final result = await LinkChildDeviceUseCase(MockManagedChildRepository(), auth)(
      code: 'kid_uid',
    );
    expect(result.getOrElse(() => throw 'failed').value, 'kid_uid');
    expect(auth.currentUser.uid, 'kid_uid');
  });

  test("the server's refusal reaches the child word for word", () async {
    final repo = MockManagedChildRepository()
      ..refusedCodes['OLDCODE'] = 'This code has expired. Ask a parent for a new one.';
    final result = await LinkChildDeviceUseCase(repo, MockAuthRepository())(code: 'OLDCODE');
    result.fold(
      (f) => expect(f.message, 'This code has expired. Ask a parent for a new one.'),
      (_) => fail('should not link'),
    );
  });

  test('a not-found refusal reaches the child word for word', () async {
    final repo = MockManagedChildRepository()
      ..failingCodes['TYPO'] = NotFoundException(
          "That code didn't work. Check it, or ask a parent for a new one.",
          code: 'not-found');
    final result = await LinkChildDeviceUseCase(repo, MockAuthRepository())(code: 'TYPO');
    result.fold(
      (f) => expect(f.message, "That code didn't work. Check it, or ask a parent for a new one."),
      (_) => fail('should not link'),
    );
  });

  test('a server fault shows a friendly message, not the raw server text', () async {
    final repo = MockManagedChildRepository()
      ..failingCodes['BROKEN'] = const ServerException('INTERNAL', code: 'internal');
    final result = await LinkChildDeviceUseCase(repo, MockAuthRepository())(code: 'BROKEN');
    result.fold(
      (f) => expect(f.message, 'Something went wrong. Ask a parent for a new code.'),
      (_) => fail('should not link'),
    );
  });

  test('an unexpected error shows the same friendly message', () async {
    final repo = MockManagedChildRepository()..failingCodes['ODD'] = StateError('boom');
    final result = await LinkChildDeviceUseCase(repo, MockAuthRepository())(code: 'ODD');
    result.fold(
      (f) => expect(f.message, 'Something went wrong. Ask a parent for a new code.'),
      (_) => fail('should not link'),
    );
  });

  test('an empty code is refused before calling the server', () async {
    final result = await LinkChildDeviceUseCase(MockManagedChildRepository(), MockAuthRepository())(
      code: ' - ',
    );
    expect(result.isLeft(), isTrue);
  });

  test('a sign-in that fails after the code was spent says to get a new code', () async {
    final auth = _FailingSignInAuth();
    final result = await LinkChildDeviceUseCase(MockManagedChildRepository(), auth)(code: 'kid_uid');
    result.fold(
      (f) => expect(f.message, "That didn't finish. Ask a parent for a new code."),
      (_) => fail('should not link'),
    );
  });
}

class _FailingSignInAuth extends MockAuthRepository {
  @override
  Future<dynamic> signInWithCustomToken(String token) async =>
      throw Exception('network');
}
