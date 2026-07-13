import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/usecases/user/stream_user_profile_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

import '../../../mocks/mock_user_repository.dart';

void main() {
  test('stream errors surface as Left instead of being swallowed', () async {
    final users = MockUserRepository();
    final useCase = StreamUserProfileUseCase(users);

    final events = <Either<Failure, User?>>[];
    final sub = useCase.call(userId: UserId('user_1')).listen(events.add);
    addTearDown(sub.cancel);
    // Let the stream deliver its initial value (and subscribe internally)
    // before injecting the error into the broadcast controller.
    await Future<void>.delayed(const Duration(milliseconds: 10));

    users.emitProfileError(
      const ServerException(
        'User profile data is malformed',
        code: 'USER_DATA_MALFORMED',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    // The mock (like Firestore) emits the current profile on listen, so the
    // error arrives as the second event.
    expect(events, hasLength(2),
        reason: 'the error must reach the listener as an event');
    final failure = events.last.fold((f) => f, (_) => null);
    expect(failure, isA<ServerFailure>());
    expect(failure!.message, contains('malformed'));
  });

  test('stream stays alive after an error and delivers later profiles',
      () async {
    final users = MockUserRepository();
    final useCase = StreamUserProfileUseCase(users);

    final events = <Either<Failure, User?>>[];
    final sub = useCase.call(userId: UserId('user_1')).listen(events.add);
    addTearDown(sub.cancel);

    users.emitProfileError(const ServerException('boom', code: 'X'));
    final profile = await users.getUserProfile(UserId('user_1'));
    await users.updateUserProfile(profile!);
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(2));
    expect(events.last.isRight(), isTrue,
        reason: 'a profile update after an error must still be delivered');
  });
}
