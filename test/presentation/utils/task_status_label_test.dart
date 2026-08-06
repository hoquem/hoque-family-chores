import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/presentation/utils/task_status_label.dart';

/// The words the family sees for each chore state.
///
/// These were duplicated in three widgets before this function existed, which
/// is how `pendingApproval` drifted from the wording `DESIGN.md` specifies.
/// One test, one source, so the next rename is a one-line change.
void main() {
  group('taskStatusLabel', () {
    test('an unclaimed chore is up for grabs', () {
      expect(taskStatusLabel(TaskStatus.available), 'Up for grabs');
    });

    test('a claimed chore is assigned', () {
      expect(taskStatusLabel(TaskStatus.assigned), 'Assigned');
    });

    test('a chore someone has started is on it', () {
      expect(taskStatusLabel(TaskStatus.inProgress), 'On it');
    });

    // DESIGN.md:204,261,442 specify "Waiting", and :302 names "Awaiting
    // Approval" as a prohibited phrasing. The code said "Pending Approval" in
    // three places until they were unified above; this pins the spec.
    test('a chore waiting for a sign-off says Waiting, not Pending Approval',
        () {
      expect(taskStatusLabel(TaskStatus.pendingApproval), 'Waiting');
    });

    test('a sent-back chore says have another go', () {
      expect(taskStatusLabel(TaskStatus.needsRevision), 'Have another go');
    });

    test('an approved chore is done', () {
      expect(taskStatusLabel(TaskStatus.completed), 'Done');
    });

    test('every status has a non-empty label', () {
      for (final status in TaskStatus.values) {
        expect(taskStatusLabel(status), isNotEmpty, reason: '$status');
      }
    });
  });
}
