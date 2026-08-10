// Approving a chore records whether the approver was signing off their own
// work. Parents may do that by design, so it is not an error to prevent — but
// it is the one thing about approvals worth being able to count.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';

import '../mocks/mock_task_repository.dart';

final _familyId = FamilyId('family_1');
// Seeded by MockTaskRepository: 'Do laundry', assigned to user_2.
const _taskId = 'task_2';
final _doer = UserId('user_2');
final _someoneElse = UserId('user_9');

/// Approves [_taskId] as [approver] and returns the logged analytics params.
Future<Map<String, dynamic>?> _approveAndReadEvent(UserId approver) async {
  final db = FakeFirebaseFirestore();
  final container = ProviderContainer(
    overrides: [
      taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
      analyticsProvider.overrideWith((_) => Analytics(db)),
    ],
  );
  addTearDown(container.dispose);

  await container
      .read(taskListNotifierProvider(_familyId).notifier)
      .approveTask(_taskId, approver, _familyId);

  final docs = await db.collection('analyticsEvents').get();
  final approvals =
      docs.docs.where((d) => d.data()['name'] == 'taskApproved').toList();
  if (approvals.isEmpty) return null;
  return (approvals.single.data()['params'] as Map).cast<String, dynamic>();
}

void main() {
  group('the taskApproved event', () {
    test('records a self-approval as one', () async {
      final params = await _approveAndReadEvent(_doer);
      expect(params, isNotNull,
          reason: 'approving a chore must log a taskApproved event');
      expect(params!['selfApproved'], isTrue);
    });

    test('records a peer approval as not one', () async {
      final params = await _approveAndReadEvent(_someoneElse);
      expect(params, isNotNull);
      expect(params!['selfApproved'], isFalse);
    });

    test('carries no names — the collection is pseudonymous', () async {
      final db = FakeFirebaseFirestore();
      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
          analyticsProvider.overrideWith((_) => Analytics(db)),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(taskListNotifierProvider(_familyId).notifier)
          .approveTask(_taskId, _doer, _familyId);

      final docs = await db.collection('analyticsEvents').get();
      // Uids and booleans only: no display name, no email, no free text.
      expect(docs.docs.single.data().toString(), isNot(contains('@')));
    });
  });
}
