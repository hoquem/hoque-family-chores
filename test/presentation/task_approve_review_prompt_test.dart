// Approving a chore hands someone else stars — the same kind of payoff
// moment their own celebration gives the doer, just for the approver
// instead. This proves the hook wired into TaskListNotifier.approveTask (the
// path task_details_screen.dart, add_task_screen.dart and task_list_tile.dart
// all call): a successful approval by a parent/guardian records one positive
// moment toward the review-prompt gate, a failed approval records nothing, a
// child never records one even if it somehow reached this path, and a
// self-approval (the approver is also the doer) skips the hook entirely —
// that stars-to-self rise already celebrates and counts a moment through
// StarAwardWatcher, so recording a second one here would double-count.
//
// It never asserts the review sheet is offered: an approval always calls
// ReviewPromptService.onPositiveMoment with canShowSheetNow: false (see
// review_prompt_positive_moment.dart for why). reviewRequesterProvider is
// still overridden — with an unstubbed mock — as a trip wire: mocktail
// throws (a TypeError, from an unstubbed call returning null into a non-null
// return type) if isAvailable()/requestReview() are ever reached, which
// ReviewPromptService's own try/catch would otherwise log and swallow
// silently. The explicit verifyNever calls below are the actual assertion;
// the unstubbed mock is a second, independent tripwire for the same thing.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hoque_family_chores/data/services/review_requester.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';

import '../mocks/mock_task_repository.dart';

class _MockReviewRequester extends Mock implements ReviewRequester {}

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

final _familyId = FamilyId('family_1');
// Seeded by MockTaskRepository.
const _existingTaskId = 'task_2';
const _missingTaskId = 'does_not_exist';
final _approverId = UserId('approver_1');

User _user(UserRole role) => User(
  id: _approverId,
  name: 'Approver',
  familyId: _familyId,
  role: role,
  points: Points(0),
  joinedAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

class _Harness {
  _Harness(this.container, this.reviewRequester);
  final ProviderContainer container;
  final _MockReviewRequester reviewRequester;
}

_Harness _containerFor(UserRole role) {
  SharedPreferences.setMockInitialValues({
    'review_prompt_positive_moment_count': 0,
  });
  final reviewRequester = _MockReviewRequester();
  final container = ProviderContainer(
    overrides: [
      taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
      authNotifierProvider.overrideWith(
        () => _FixedAuthNotifier(AuthState(user: _user(role))),
      ),
      // Left unstubbed on purpose — see the file header.
      reviewRequesterProvider.overrideWith((_) => reviewRequester),
    ],
  );
  return _Harness(container, reviewRequester);
}

Future<int> _positiveMomentCount() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('review_prompt_positive_moment_count') ?? 0;
}

void main() {
  test('a parent approving a chore records a positive moment', () async {
    final harness = _containerFor(UserRole.parent);
    addTearDown(harness.container.dispose);

    await harness.container
        .read(taskListNotifierProvider(_familyId).notifier)
        .approveTask(_existingTaskId, _approverId, _familyId);

    expect(await _positiveMomentCount(), 1);
    verifyNever(() => harness.reviewRequester.isAvailable());
    verifyNever(() => harness.reviewRequester.requestReview());
  });

  test('a guardian approving a chore records a positive moment too', () async {
    final harness = _containerFor(UserRole.guardian);
    addTearDown(harness.container.dispose);

    await harness.container
        .read(taskListNotifierProvider(_familyId).notifier)
        .approveTask(_existingTaskId, _approverId, _familyId);

    expect(await _positiveMomentCount(), 1);
  });

  test('a failed approval records nothing', () async {
    final harness = _containerFor(UserRole.parent);
    addTearDown(harness.container.dispose);

    await expectLater(
      harness.container
          .read(taskListNotifierProvider(_familyId).notifier)
          .approveTask(_missingTaskId, _approverId, _familyId),
      throwsA(anything),
    );

    expect(await _positiveMomentCount(), 0);
  });

  test(
    'a child never records a positive moment, even approving successfully',
    () async {
      final harness = _containerFor(UserRole.child);
      addTearDown(harness.container.dispose);

      await harness.container
          .read(taskListNotifierProvider(_familyId).notifier)
          .approveTask(_existingTaskId, _approverId, _familyId);

      expect(await _positiveMomentCount(), 0);
    },
  );

  test(
    'a parent approving their own chore records nothing from this hook — '
    'their own stars rising already celebrates and counts separately',
    () async {
      final harness = _containerFor(UserRole.parent);
      addTearDown(harness.container.dispose);

      // task_2 is assigned to user_2 (MockTaskRepository); approving as its
      // own assignee is the self-approval case.
      await harness.container
          .read(taskListNotifierProvider(_familyId).notifier)
          .approveTask(_existingTaskId, UserId('user_2'), _familyId);

      expect(await _positiveMomentCount(), 0);
    },
  );
}
