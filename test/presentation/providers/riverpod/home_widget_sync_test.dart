import 'package:flutter/material.dart';
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

final _me = UserId('home_widget_sync_user');
final _familyId = FamilyId('family_hw_sync');

User _testUser() => User(
      id: _me,
      name: 'Maya',
      email: Email('maya@example.com'),
      familyId: _familyId,
      role: UserRole.child,
      points: Points(150),
      joinedAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 20),
    );

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;
}

class _SpyHomeWidgetBridge implements HomeWidgetBridge {
  _SpyHomeWidgetBridge({this.failure});

  final Object? failure;
  final updates = <HomeWidgetData>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> update(HomeWidgetData data) async {
    updates.add(data);
    if (failure != null) throw failure!;
  }
}

Task _task(String id, String title, DateTime due) => Task(
      id: TaskId(id),
      title: title,
      description: '',
      status: TaskStatus.assigned,
      difficulty: TaskDifficulty.easy,
      dueDate: due,
      assignedToId: _me,
      createdById: UserId('creator'),
      createdAt: DateTime(2026, 7, 31),
      points: Points(10),
      tags: const [],
      familyId: _familyId,
    );

/// Minimal host that calls the production sync exactly the way HomeScreen does.
class _Host extends ConsumerWidget {
  const _Host({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onBuild();
    syncHomeWidget(ref, _familyId, _me);
    return const SizedBox.shrink();
  }
}

/// Set by [_pumpHost]; calling it forces a fresh [_Host] build.
late void Function(VoidCallback) _rebuildHost;

Future<void> _pumpHost(
  WidgetTester tester,
  _SpyHomeWidgetBridge spy, {
  required List<Task> tasks,
  VoidCallback? onBuild,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FixedAuthNotifier(
            AuthState(status: AuthStatus.authenticated, user: _testUser()),
          ),
        ),
        taskListStreamProvider(_familyId).overrideWith((ref) => Stream.value(tasks)),
        homeWidgetBridgeProvider.overrideWith((_) => spy),
      ],
      child: MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            _rebuildHost = setState;
            return _Host(onBuild: onBuild ?? () {});
          },
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('syncHomeWidget', () {
    testWidgets('pushes the current payload without waiting for a change',
        (tester) async {
      final spy = _SpyHomeWidgetBridge();
      final now = DateTime.now();

      await _pumpHost(tester, spy, tasks: [_task('t1', 'Make bed', now)]);

      expect(spy.updates, isNotEmpty,
          reason: 'the widget must get its first payload on load, not only '
              'once something changes afterwards');
      expect(spy.updates.last.missionTitles, ['Make bed']);
    });

    testWidgets('does not re-push when nothing changed', (tester) async {
      final spy = _SpyHomeWidgetBridge();
      final now = DateTime.now();
      var builds = 0;

      await _pumpHost(
        tester,
        spy,
        tasks: [_task('t1', 'Make bed', now)],
        onBuild: () => builds++,
      );
      final afterFirst = spy.updates.length;

      // Force a rebuild of the host without changing the payload.
      _rebuildHost(() {});
      await tester.pump();

      expect(builds, greaterThan(1), reason: 'the host must have rebuilt');
      expect(spy.updates, hasLength(afterFirst),
          reason: 'a rebuild is not a data change; re-pushing burns the '
              'platform widget-reload budget');
    });

    testWidgets('a bridge failure does not escape into the widget tree',
        (tester) async {
      final spy = _SpyHomeWidgetBridge(failure: StateError('no widget found'));
      final now = DateTime.now();

      await _pumpHost(tester, spy, tasks: [_task('t1', 'Make bed', now)]);
      await tester.pump();

      expect(spy.updates, isNotEmpty);
      expect(tester.takeException(), isNull,
          reason: 'the home widget is a convenience; a native failure must be '
              'logged, not reported as a crash');
    });
  });
}
