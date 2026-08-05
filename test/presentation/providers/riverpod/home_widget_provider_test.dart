import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/usecases/home/build_home_widget_data_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/home_widget_provider.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/utils/home_widget_bridge.dart';

const _uid = 'home_widget_user';
final _me = UserId(_uid);
final _familyId = FamilyId('family_hw');

User _testUser({String name = 'Maya'}) => User(
      id: _me,
      name: name,
      email: Email('maya@example.com'),
      familyId: _familyId,
      role: UserRole.child,
      points: Points(150),
      joinedAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 20),
    );

AuthState _authState(User? user) => AuthState(
      status: user == null ? AuthStatus.initial : AuthStatus.authenticated,
      user: user,
    );

/// Fixed auth notifier that returns a seeded state without touching Firebase.
class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;
}

/// Spy bridge that records every payload passed to [update].
class _SpyHomeWidgetBridge implements HomeWidgetBridge {
  final updates = <HomeWidgetData>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> update(HomeWidgetData data) async {
    updates.add(data);
  }
}

Task _task({
  required String id,
  required String title,
  UserId? assignedTo,
  TaskStatus status = TaskStatus.assigned,
  DateTime? due,
  DateTime? approvedAt,
}) {
  return Task(
    id: TaskId(id),
    title: title,
    description: '',
    status: status,
    difficulty: TaskDifficulty.easy,
    dueDate: due ?? DateTime(2026, 8, 1),
    assignedToId: assignedTo ?? _me,
    createdById: UserId('user_1'),
    createdAt: DateTime(2026, 7, 31),
    approvedAt: approvedAt,
    points: Points(10),
    tags: const [],
    familyId: _familyId,
  );
}

void main() {
  group('homeWidgetDataProvider', () {
    test('builds greeting, streak and missions from task stream and auth state',
        () async {
      final now = DateTime.now();
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FixedAuthNotifier(_authState(_testUser())),
          ),
          taskListStreamProvider(_familyId).overrideWith(
            (ref) => Stream.value([
              _task(id: 't1', title: 'Make bed', due: now),
              _task(id: 't2', title: 'Tidy room', due: now),
              _task(
                id: 't3',
                title: 'Approved today',
                status: TaskStatus.completed,
                due: now,
                approvedAt: now,
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Keep the provider alive and let the stream emit before reading.
      container.listen(homeWidgetDataProvider(_familyId, _me), (_, __) {});
      await Future.delayed(Duration.zero);

      final data = container.read(homeWidgetDataProvider(_familyId, _me));

      expect(data.greeting, 'Hi Maya! 🔥 1-day streak');
      expect(data.currentStreakDays, 1);
      expect(data.missionTitles, ['Make bed', 'Tidy room']);
      expect(data.pendingApprovalCount, 0);
    });

    test('counts pending approvals excluding the signed-in user', () async {
      final now = DateTime.now();
      final other = UserId('other_user');
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FixedAuthNotifier(_authState(_testUser())),
          ),
          taskListStreamProvider(_familyId).overrideWith(
            (ref) => Stream.value([
              _task(
                id: 't1',
                title: 'Waiting for me',
                status: TaskStatus.pendingApproval,
                assignedTo: _me,
                due: now,
              ),
              _task(
                id: 't2',
                title: 'Waiting for other',
                status: TaskStatus.pendingApproval,
                assignedTo: other,
                due: now,
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen(homeWidgetDataProvider(_familyId, _me), (_, __) {});
      await Future.delayed(Duration.zero);

      final data = container.read(homeWidgetDataProvider(_familyId, _me));

      expect(data.pendingApprovalCount, 1);
    });

    test('falls back to generic greeting when user is null', () async {
      final now = DateTime.now();
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FixedAuthNotifier(_authState(null)),
          ),
          taskListStreamProvider(_familyId).overrideWith(
            (ref) => Stream.value([
              _task(id: 't1', title: 'Make bed', due: now),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen(homeWidgetDataProvider(_familyId, _me), (_, __) {});
      await Future.delayed(Duration.zero);

      final data = container.read(homeWidgetDataProvider(_familyId, _me));

      expect(data.greeting, 'Hi there!');
      expect(data.missionTitles, ['Make bed']);
    });
  });

  group('homeWidgetBridgeProvider', () {
    test('can be overridden with a spy implementation', () async {
      final spy = _SpyHomeWidgetBridge();
      final container = ProviderContainer(
        overrides: [
          homeWidgetBridgeProvider.overrideWith((_) => spy),
        ],
      );
      addTearDown(container.dispose);

      final bridge = container.read(homeWidgetBridgeProvider);
      await bridge.update(
        const HomeWidgetData(
          greeting: 'Hi!',
          currentStreakDays: 2,
          missionTitles: ['Brush teeth'],
          pendingApprovalCount: 0,
        ),
      );

      expect(spy.updates, hasLength(1));
      expect(spy.updates.single.greeting, 'Hi!');
      expect(spy.updates.single.currentStreakDays, 2);
      expect(spy.updates.single.missionTitles, ['Brush teeth']);
    });
  });
}
