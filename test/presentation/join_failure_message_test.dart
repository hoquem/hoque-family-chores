// What a person sees when joining a family fails.
//
// TASK-499 surfaced this: a locked-out join put
// "Failed to request to join family: [cloud_firestore/permission-denied] The
// caller does not have permission to execute the specified operation" on screen,
// in an app whose user may be nine years old. The rule that caused that
// particular denial is fixed, but any server failure would read the same way.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/join_failure_message.dart';

void main() {
  test('a server failure is not shown raw', () {
    const raw = 'Failed to request to join family: '
        '[cloud_firestore/permission-denied] The caller does not have '
        'permission to execute the specified operation.';

    final shown = joinFailureMessage(ServerFailure(raw));

    expect(shown, isNot(contains('cloud_firestore')));
    expect(shown, isNot(contains('permission-denied')));
    expect(shown, isNot(contains(raw)));
    expect(shown, isNotEmpty);
  });

  // The messages the domain writes for a person are already the right words;
  // replacing them with something generic would lose "you already belong to a
  // family", which tells the user exactly what to do next.
  test('a wrong code keeps its own words', () {
    expect(joinFailureMessage(NotFoundFailure('No family found for that invite code')),
        'No family found for that invite code');
  });

  test('already being in a family keeps its own words', () {
    expect(joinFailureMessage(BusinessFailure('You already belong to a family')),
        'You already belong to a family');
  });

  test('an empty code keeps its own words', () {
    expect(joinFailureMessage(ValidationFailure('Invite code cannot be empty')),
        'Invite code cannot be empty');
  });
}
