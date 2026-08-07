import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/usecases/home/build_home_widget_data_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

User _testUser({required String name}) => User(
      id: UserId('u1'),
      name: name,
      email: Email('a@b.com'),
      familyId: FamilyId('fam1'),
      role: UserRole.child,
      points: Points(0),
      joinedAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Task _task(String title) => Task(
      id: TaskId('t1'),
      title: title,
      description: '',
      status: TaskStatus.assigned,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 8, 4),
      assignedToId: UserId('u1'),
      createdById: UserId('u2'),
      createdAt: DateTime(2026, 8, 1),
      points: Points(10),
      tags: const [],
      familyId: FamilyId('fam1'),
    );

void main() {
  const useCase = BuildHomeWidgetDataUseCase();

  test('truncates mission list to 3 items', () {
    final data = useCase(
      user: _testUser(name: 'Aisha'),
      todayTasks: [
        _task('Feed cat'),
        _task('Water plants'),
        _task('Tidy room'),
        _task('Make bed'),
      ],
      streakDays: 0,
      pendingApprovals: 0,
    );

    expect(data.missionTitles.length, 3);
    expect(data.missionTitles, ['Feed cat', 'Water plants', 'Tidy room']);
  });

  test('shows streak when non-zero', () {
    final data = useCase(
      user: _testUser(name: 'Aisha'),
      todayTasks: const [],
      streakDays: 5,
      pendingApprovals: 0,
    );

    expect(data.currentStreakDays, 5);
    expect(data.greeting, contains('5'));
  });

  test('shows pending approval count when non-zero', () {
    final data = useCase(
      user: _testUser(name: 'Aisha'),
      todayTasks: const [],
      streakDays: 0,
      pendingApprovals: 2,
    );

    expect(data.pendingApprovalCount, 2);
  });

  test('falls back to a calm greeting when no missions exist', () {
    final data = useCase(
      user: _testUser(name: 'Aisha'),
      todayTasks: const [],
      streakDays: 0,
      pendingApprovals: 0,
    );

    expect(data.missionTitles, isEmpty);
    expect(data.greeting, isNotEmpty);
    expect(data.greeting, contains('Aisha'));
  });

  // An empty mission list means two very different things, and the widget used
  // to render "No missions today 🎉" for both — telling a child who had just
  // finished their chores that they never had any. The message is decided here
  // so the two native widgets stay dumb renderers and cannot drift apart.
  group('empty-state message', () {
    test('nothing was scheduled — says so, without celebrating', () {
      final data = useCase(
        user: _testUser(name: 'Aisha'),
        todayTasks: const [],
        streakDays: 0,
        pendingApprovals: 0,
        missionsWaiting: 0,
        missionsDone: 0,
      );

      expect(data.emptyMessage, 'No missions today');
    });

    test('everything is handed in — celebrates, in the app\'s words', () {
      final data = useCase(
        user: _testUser(name: 'Aisha'),
        todayTasks: const [],
        streakDays: 0,
        pendingApprovals: 0,
        missionsWaiting: 1,
        missionsDone: 0,
      );

      expect(data.emptyMessage, 'All done for today! 🎉',
          reason: 'matches CelebrationCard so the widget and the home hub say '
              'the same thing about the same day');
    });

    test('everything is approved — celebrates too', () {
      final data = useCase(
        user: _testUser(name: 'Aisha'),
        todayTasks: const [],
        streakDays: 0,
        pendingApprovals: 0,
        missionsWaiting: 0,
        missionsDone: 2,
      );

      expect(data.emptyMessage, 'All done for today! 🎉');
    });

    test('work still to do — the message is not used, but stays coherent', () {
      final data = useCase(
        user: _testUser(name: 'Aisha'),
        todayTasks: [_task('Feed cat')],
        streakDays: 0,
        pendingApprovals: 0,
        missionsWaiting: 1,
        missionsDone: 0,
      );

      expect(data.missionTitles, ['Feed cat']);
      expect(data.emptyMessage, isNotEmpty);
    });
  });
}
