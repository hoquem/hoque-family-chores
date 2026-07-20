import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/services/home_stats.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

// Wednesday evening; the current week started Monday 2026-07-13.
final _now = DateTime(2026, 7, 15, 18, 30);
final _me = UserId('me');
final _sibling = UserId('sibling');

Task _task({
  String id = 't',
  UserId? assignedTo,
  TaskStatus status = TaskStatus.assigned,
  DateTime? due,
  DateTime? completedAt,
  DateTime? approvedAt,
  int points = 10,
}) {
  return Task(
    id: TaskId(id),
    title: 'Task $id',
    description: '',
    status: status,
    difficulty: TaskDifficulty.easy,
    dueDate: due ?? _now,
    assignedToId: assignedTo,
    createdAt: _now.subtract(const Duration(days: 14)),
    completedAt: completedAt,
    approvedAt: approvedAt,
    points: Points(points),
    tags: const [],
    familyId: FamilyId('family_1'),
  );
}

User _member(String id, String name, {int points = 0}) {
  return User(
    id: UserId(id),
    name: name,
    email: Email('$id@example.com'),
    photoUrl: null,
    familyId: FamilyId('family_1'),
    role: UserRole.child,
    points: Points(points),
    joinedAt: _now.subtract(const Duration(days: 30)),
    updatedAt: _now,
  );
}

void main() {
  _claimableTests();
  group('todayMissions', () {
    test('includes my tasks due today and overdue, nothing else', () {
      final missions = todayMissions(
        [
          _task(id: 'today', assignedTo: _me, due: _now),
          _task(
              id: 'overdue',
              assignedTo: _me,
              due: _now.subtract(const Duration(days: 2))),
          _task(
              id: 'tomorrow',
              assignedTo: _me,
              due: _now.add(const Duration(days: 1))),
          _task(id: 'siblings', assignedTo: _sibling, due: _now),
          _task(id: 'unassigned', assignedTo: null, due: _now),
        ],
        _me,
        _now,
      );

      expect(missions.toDo.map((t) => t.id.value), ['today', 'overdue']);
      expect(missions.waiting, isEmpty);
      expect(missions.done, isEmpty);
    });

    test('splits by status: to-do, waiting for approval, done today', () {
      final missions = todayMissions(
        [
          _task(id: 'open', assignedTo: _me),
          _task(id: 'redo', assignedTo: _me, status: TaskStatus.needsRevision),
          _task(
              id: 'waiting',
              assignedTo: _me,
              status: TaskStatus.pendingApproval,
              completedAt: _now),
          _task(
              id: 'done',
              assignedTo: _me,
              status: TaskStatus.completed,
              completedAt: _now.subtract(const Duration(hours: 2))),
        ],
        _me,
        _now,
      );

      expect(missions.toDo.map((t) => t.id.value), ['open', 'redo']);
      expect(missions.waiting.map((t) => t.id.value), ['waiting']);
      expect(missions.done.map((t) => t.id.value), ['done']);
    });

    test('tasks completed on earlier days do not linger', () {
      final missions = todayMissions(
        [
          _task(
              id: 'old',
              assignedTo: _me,
              status: TaskStatus.completed,
              due: _now.subtract(const Duration(days: 3)),
              completedAt: _now.subtract(const Duration(days: 3))),
        ],
        _me,
        _now,
      );

      expect(missions.toDo, isEmpty);
      expect(missions.done, isEmpty);
      expect(missions.allDone, isFalse,
          reason: 'a day with no missions is empty, not celebrated');
    });

    test('allDone only when something was finished and nothing is left', () {
      final finished = todayMissions(
        [
          _task(
              id: 'waiting',
              assignedTo: _me,
              status: TaskStatus.pendingApproval,
              completedAt: _now),
        ],
        _me,
        _now,
      );
      expect(finished.allDone, isTrue);

      final stillWorking = todayMissions(
        [
          _task(id: 'open', assignedTo: _me),
          _task(
              id: 'waiting',
              assignedTo: _me,
              status: TaskStatus.pendingApproval,
              completedAt: _now),
        ],
        _me,
        _now,
      );
      expect(stillWorking.allDone, isFalse);

      final emptyDay = todayMissions([], _me, _now);
      expect(emptyDay.allDone, isFalse);
    });
  });

  group('streakDays', () {
    Task completed(String id, DateTime when, {UserId? by}) => _task(
        id: id,
        assignedTo: by ?? _me,
        status: TaskStatus.completed,
        due: when,
        completedAt: when,
        approvedAt: when);

    test('zero without any completions', () {
      expect(streakDays([_task(id: 'open', assignedTo: _me)], _me, _now), 0);
    });

    test('submitted-but-unapproved and rejected work do not count', () {
      final tasks = [
        // Submitted today, awaiting approval: has completedAt but no approvedAt.
        _task(
            id: 'pending',
            assignedTo: _me,
            status: TaskStatus.pendingApproval,
            completedAt: _now),
        // Rejected: bounced back, completedAt was never cleared.
        _task(
            id: 'rejected',
            assignedTo: _me,
            status: TaskStatus.needsRevision,
            completedAt: _now),
      ];
      expect(streakDays(tasks, _me, _now), 0,
          reason: 'a streak means stars earned, not work merely submitted');
    });

    test('counts consecutive days ending today', () {
      final tasks = [
        completed('d0', _now),
        completed('d1', _now.subtract(const Duration(days: 1))),
        completed('d2', _now.subtract(const Duration(days: 2))),
      ];
      expect(streakDays(tasks, _me, _now), 3);
    });

    test('today not yet done keeps yesterday\'s streak alive', () {
      final tasks = [
        completed('d1', _now.subtract(const Duration(days: 1))),
        completed('d2', _now.subtract(const Duration(days: 2))),
      ];
      expect(streakDays(tasks, _me, _now), 2);
    });

    test('a gap breaks the streak', () {
      final tasks = [
        completed('d0', _now),
        completed('d3', _now.subtract(const Duration(days: 3))),
      ];
      expect(streakDays(tasks, _me, _now), 1);
    });

    test('several completions on one day count once', () {
      final tasks = [
        completed('a', _now),
        completed('b', _now.subtract(const Duration(hours: 3))),
      ];
      expect(streakDays(tasks, _me, _now), 1);
    });

    test('only my completions count', () {
      final tasks = [
        completed('d0', _now),
        completed('sib', _now.subtract(const Duration(days: 1)),
            by: _sibling),
      ];
      expect(streakDays(tasks, _me, _now), 1);
    });
  });

  group('weeklyStars', () {
    test('sums this week\'s completed stars per member, sorted descending',
        () {
      final jane = _member('jane', 'Jane');
      final bob = _member('bob', 'Bob');
      final tasks = [
        // Jane: 25 this week.
        _task(
            id: 'j1',
            assignedTo: jane.id,
            status: TaskStatus.completed,
            approvedAt: DateTime(2026, 7, 13, 9),
            points: 25),
        // Bob: 10 + 50 this week, 100 last week (excluded).
        _task(
            id: 'b1',
            assignedTo: bob.id,
            status: TaskStatus.completed,
            approvedAt: DateTime(2026, 7, 14, 17),
            points: 10),
        _task(
            id: 'b2',
            assignedTo: bob.id,
            status: TaskStatus.completed,
            approvedAt: _now,
            points: 50),
        _task(
            id: 'b-old',
            assignedTo: bob.id,
            status: TaskStatus.completed,
            approvedAt: DateTime(2026, 7, 12, 12),
            points: 100),
      ];

      final ranking = weeklyStars(tasks, [jane, bob], _now);

      expect(ranking.map((e) => e.member.name), ['Bob', 'Jane']);
      expect(ranking.first.stars, 60);
      expect(ranking.last.stars, 25);
    });

    test('submitted-but-unapproved and rejected stars are not counted', () {
      final kid = _member('kid', 'Kid');
      final tasks = [
        // Submitted this week, awaiting approval — no approvedAt yet.
        _task(
            id: 'pending',
            assignedTo: kid.id,
            status: TaskStatus.pendingApproval,
            completedAt: _now,
            points: 40),
        // Rejected this week — completedAt lingers, but it was never approved.
        _task(
            id: 'rejected',
            assignedTo: kid.id,
            status: TaskStatus.needsRevision,
            completedAt: _now,
            points: 30),
      ];

      final ranking = weeklyStars(tasks, [kid], _now);

      expect(ranking.single.stars, 0,
          reason: 'the leaderboard must match the star economy: approved only');
    });

    test('members without completions rank last with zero stars', () {
      final jane = _member('jane', 'Jane');
      final idle = _member('idle', 'Idle');
      final tasks = [
        _task(
            id: 'j1',
            assignedTo: jane.id,
            status: TaskStatus.completed,
            approvedAt: _now,
            points: 10),
      ];

      final ranking = weeklyStars(tasks, [jane, idle], _now);

      expect(ranking.last.member.name, 'Idle');
      expect(ranking.last.stars, 0);
    });
  });

  group('levels', () {
    test('level from points', () {
      expect(levelFromPoints(0), 1);
      expect(levelFromPoints(99), 1);
      expect(levelFromPoints(100), 2);
      expect(levelFromPoints(150), 2);
    });

    test('progress toward the next level', () {
      expect(levelProgress(0), 0.0);
      expect(levelProgress(150), 0.5);
      expect(levelProgress(99), closeTo(0.99, 0.001));
    });
  });
}

void _claimableTests() {
  // The dead end this fixes: a child with nothing assigned sees "No missions
  // today 🎈" on the one screen meant to make them open the app. Unclaimed
  // family tasks are already in the list the home screen holds — they were just
  // being dropped.
  group('claimable', () {
    test('offers unclaimed tasks due today', () {
      final missions = todayMissions([
        _task(id: 'free', status: TaskStatus.available, assignedTo: null),
      ], _me, _now);

      expect(missions.claimable.map((t) => t.id.value), ['free']);
    });

    test('never offers a task someone else has claimed', () {
      final missions = todayMissions([
        _task(id: 'theirs', status: TaskStatus.assigned, assignedTo: _sibling),
      ], _me, _now);

      expect(missions.claimable, isEmpty);
    });

    test('does not offer work due later — this card is about today', () {
      final missions = todayMissions([
        _task(
          id: 'friday',
          status: TaskStatus.available,
          assignedTo: null,
          due: _now.add(const Duration(days: 2)),
        ),
      ], _me, _now);

      expect(missions.claimable, isEmpty,
          reason: 'offering Friday\'s work under "Today\'s Missions" is a small '
              'lie; coherence beats filling the space');
    });

    test('offers overdue unclaimed work', () {
      final missions = todayMissions([
        _task(
          id: 'stale',
          status: TaskStatus.available,
          assignedTo: null,
          due: _now.subtract(const Duration(days: 3)),
        ),
      ], _me, _now);

      expect(missions.claimable.map((t) => t.id.value), ['stale'],
          reason: 'an overdue unclaimed chore is exactly what wants picking up');
    });

    test('my own missions are not claimable', () {
      final missions = todayMissions([
        _task(id: 'mine', assignedTo: _me),
      ], _me, _now);

      expect(missions.toDo.map((t) => t.id.value), ['mine']);
      expect(missions.claimable, isEmpty);
    });
  });
}
