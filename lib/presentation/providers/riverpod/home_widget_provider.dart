import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/services/home_stats.dart';
import 'package:hoque_family_chores/domain/usecases/home/build_home_widget_data_usecase.dart';
import 'package:hoque_family_chores/utils/home_widget_bridge.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'auth_notifier.dart';
import 'task_list_notifier.dart';

part 'home_widget_provider.g.dart';

/// Builds the data payload for the home-screen widget from the same state that
/// powers the home hub. Keeps the widget in sync without extra data fetching.
@riverpod
HomeWidgetData homeWidgetData(Ref ref, FamilyId familyId, UserId userId) {
  final tasksAsync = ref.watch(taskListStreamProvider(familyId));
  final userAsync = ref.watch(authNotifierProvider);

  final tasks = tasksAsync.valueOrNull ?? const <Task>[];
  final user = userAsync.user;

  final now = DateTime.now();
  final missions = todayMissions(tasks, userId, now);
  final streak = streakDays(tasks, userId, now);

  // Pending approvals the signed-in user is allowed to judge.
  final pendingApprovals = tasks
      .where(
        (t) => t.status == TaskStatus.pendingApproval && t.assignedToId != userId,
      )
      .length;

  // Widget missions are the tasks still to do, in the same order the home hub
  // would show them.
  final todayTasks = missions.toDo;

  // If the user record is temporarily missing, fall back to a generic greeting
  // so the widget never blocks on auth state.
  final effectiveUser = user ??
      User(
        id: userId,
        name: 'there',
        email: null,
        familyId: familyId,
        role: UserRole.child,
        points: Points(0),
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  return const BuildHomeWidgetDataUseCase()(
    user: effectiveUser,
    todayTasks: todayTasks,
    streakDays: streak,
    pendingApprovals: pendingApprovals,
  );
}


/// Provider for the platform bridge that pushes widget data to native.
/// Overridable in tests.
final homeWidgetBridgeProvider = Provider<HomeWidgetBridge>((_) => HomeWidgetBridgeImpl());
