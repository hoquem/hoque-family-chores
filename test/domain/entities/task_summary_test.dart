import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task_summary.dart';

void main() {
  group('TaskSummary', () {
    final summary = TaskSummary(
      totalTasks: 10,
      completedTasks: 4,
      pendingTasks: 2,
      availableTasks: 2,
      needsRevisionTasks: 1,
      assignedTasks: 1,
      dueToday: 3,
      pointsEarned: 100,
      completionPercentage: 40,
    );

    test('computed properties', () {
      expect(summary.totalCompleted, 4);
      expect(summary.waitingOverall, 3); // pending + needsRevision
      expect(summary.waitingAssigned, 2); // assigned + needsRevision
      expect(summary.waitingUnassigned, 2); // available
    });

    test('copyWith', () {
      final copy = summary.copyWith(completedTasks: 5);
      expect(copy.completedTasks, 5);
      expect(copy.totalTasks, 10);
    });

    test('equality', () {
      final other = TaskSummary(
        totalTasks: 10,
        completedTasks: 4,
        pendingTasks: 2,
        availableTasks: 2,
        needsRevisionTasks: 1,
        assignedTasks: 1,
        dueToday: 3,
        pointsEarned: 100,
        completionPercentage: 40,
      );
      expect(summary, equals(other));
    });
  });
}
