import '../../domain/entities/task.dart';

/// The word the family sees for a chore's state.
///
/// One source for wording that `DESIGN.md` owns. This lives in `presentation/`
/// rather than `domain/` on purpose: it is copy, not a rule. When the family
/// decides "Done" should read "Finished", the spec that changed is the design
/// spec, and nothing in the domain layer should have to move.
///
/// Pinned by `test/presentation/utils/task_status_label_test.dart` — one test
/// per status, so a rename that misses a call site cannot pass silently.
String taskStatusLabel(TaskStatus status) => switch (status) {
      TaskStatus.available => 'Up for grabs',
      TaskStatus.assigned => 'Assigned',
      TaskStatus.inProgress => 'On it',
      TaskStatus.pendingApproval => 'Pending Approval',
      TaskStatus.needsRevision => 'Have another go',
      TaskStatus.completed => 'Done',
    };
