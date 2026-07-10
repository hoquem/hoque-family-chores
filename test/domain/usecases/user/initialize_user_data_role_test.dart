import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/usecases/user/initialize_user_data_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

import '../../../mocks/mock_user_repository.dart';

void main() {
  late MockUserRepository userRepository;
  late InitializeUserDataUseCase useCase;

  setUp(() {
    userRepository = MockUserRepository();
    useCase = InitializeUserDataUseCase(userRepository);
  });

  test('creates a parent when role: UserRole.parent is supplied', () async {
    const id = 'oauth_parent_uid';

    final result = await useCase.call(
      userId: UserId(id),
      name: 'Ada',
      email: 'ada@example.com',
      role: UserRole.parent,
    );

    final user = result.fold((failure) => throw StateError('$failure'), (u) => u);
    expect(user.role, UserRole.parent);
    expect(user.familyId.value, isEmpty);

    final persisted = await userRepository.getUserProfile(UserId(id));
    expect(persisted, isNotNull);
    expect(persisted!.role, UserRole.parent);
  });

  test('defaults to child when no role is supplied', () async {
    final result = await useCase.call(
      userId: UserId('legacy_uid'),
      name: 'Kid',
      email: 'kid@example.com',
    );

    final user = result.fold((failure) => throw StateError('$failure'), (u) => u);
    expect(user.role, UserRole.child);
  });

  test('still rejects an empty email even when a role is supplied', () async {
    final result = await useCase.call(
      userId: UserId('no_email_uid'),
      name: 'Ada',
      email: '',
      role: UserRole.parent,
    );

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('expected a ValidationFailure for an empty email'),
    );
  });
}
