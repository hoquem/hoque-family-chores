import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/services/home_stats.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/bottom_nav_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/home/approval_queue_card.dart';
import 'package:hoque_family_chores/presentation/widgets/home/celebration_card.dart';
import 'package:hoque_family_chores/presentation/widgets/home/greeting_header.dart';
import 'package:hoque_family_chores/presentation/widgets/home/leaderboard_card.dart';
import 'package:hoque_family_chores/presentation/widgets/home/progress_card.dart';
import 'package:hoque_family_chores/presentation/widgets/home/today_missions_card.dart';
import 'package:hoque_family_chores/utils/logger.dart';

/// The family hub: greeting, level progress, today's missions, and a
/// role-based bottom card (weekly leaderboard for children, approval
/// queue for parents).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.d("[HomeScreen] Building screen");
    // The AppBar keeps the content below the status bar/notch, matching
    // the other tabs.
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    if (currentUser == null) {
      // A profile that failed to load must surface the error with a way
      // out; an endless spinner strands the user with no escape.
      if (authState.status == AuthStatus.error ||
          authState.errorMessage != null) {
        logger.w(
            "[HomeScreen] Profile failed to load: ${authState.errorMessage}");
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: context.tokens.brick),
                const SizedBox(height: 16),
                const Text(
                  'Could not load your profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  authState.errorMessage ?? 'An unknown error occurred.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(authNotifierProvider.notifier).signOut(),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        );
      }
      logger.w("[HomeScreen] User profile is null - showing loading indicator");
      return const Center(child: CircularProgressIndicator());
    }

    if (currentUser.familyId.value.isEmpty) {
      logger.i("[HomeScreen] User has no family yet - showing setup hint");
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.family_restroom, size: 64, color: context.tokens.inkMuted),
              const SizedBox(height: 16),
              Text(
                'Welcome, ${currentUser.name}!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Head to the Family tab to create your family or join one with an invite code.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final tasksAsync = ref.watch(taskListNotifierProvider(currentUser.familyId));
    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) {
        logger.e("[HomeScreen] Task list failed to load", error: error);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: context.tokens.brick),
                const SizedBox(height: 8),
                const Text(
                  'Could not load tasks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref
                      .invalidate(taskListNotifierProvider(currentUser.familyId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
      data: (tasks) => _buildDashboard(context, ref, currentUser, tasks),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    User currentUser,
    List<Task> tasks,
  ) {
    final now = DateTime.now();
    final missions = todayMissions(tasks, currentUser.id, now);
    final streak = streakDays(tasks, currentUser.id, now);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(taskListNotifierProvider(currentUser.familyId));
        ref.invalidate(familyMembersNotifierProvider(currentUser.familyId));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          GreetingHeader(user: currentUser),
          const SizedBox(height: 16),
          ProgressCard(points: currentUser.points.value, streak: streak),
          const SizedBox(height: 8),
          if (missions.allDone) ...[
            const CelebrationCard(),
            const SizedBox(height: 8),
          ],
          TodayMissionsCard(
            missions: missions,
            onComplete: (task) => ref
                .read(taskListNotifierProvider(currentUser.familyId).notifier)
                .completeTask(
                    task.id.value, currentUser.id, currentUser.familyId),
            // Same claim path the Tasks tab uses; the task becomes theirs and
            // moves into their missions on the next build.
            onClaim: (task) => ref
                .read(taskListNotifierProvider(currentUser.familyId).notifier)
                .claimTask(task.id.value, currentUser.id, currentUser.familyId),
          ),
          const SizedBox(height: 8),
          // Anyone can sign off a task now, so anyone sees the queue — but only
          // work they're allowed to judge. Counting your own would tell a child
          // "1 waiting for you" about a chore they cannot act on, which is
          // worse than not showing it at all.
          if (_awaitingMyJudgement(tasks, currentUser.id) > 0)
            ApprovalQueueCard(
              count: _awaitingMyJudgement(tasks, currentUser.id),
              onTap: () {
                ref
                    .read(taskFilterNotifierProvider.notifier)
                    .setFilter(TaskFilterType.pendingApproval);
                // The Tasks tab is index 1 in MainScreen.
                ref.read(bottomNavIndexNotifierProvider.notifier).setIndex(1);
              },
            )
          else
            _buildLeaderboard(ref, currentUser, tasks, now),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(
    WidgetRef ref,
    User currentUser,
    List<Task> tasks,
    DateTime now,
  ) {
    final membersAsync =
        ref.watch(familyMembersNotifierProvider(currentUser.familyId));
    return membersAsync.when(
      loading: () => const Card(
        child: ListTile(title: Text('Loading family members…')),
      ),
      error: (error, _) => Card(
        child: ListTile(
          title: const Text('Could not load family members.'),
          trailing: TextButton(
            onPressed: () => ref
                .read(familyMembersNotifierProvider(currentUser.familyId)
                    .notifier)
                .refresh(),
            child: const Text('Retry'),
          ),
        ),
      ),
      data: (members) =>
          LeaderboardCard(ranking: weeklyStars(tasks, members, now)),
    );
  }
}

/// Tasks waiting for approval that [userId] is allowed to sign off.
///
/// Excludes their own: you cannot judge your own chore, so counting it would
/// promise an action they cannot take.
int _awaitingMyJudgement(List<Task> tasks, UserId userId) => tasks
    .where((t) =>
        t.status == TaskStatus.pendingApproval && t.assignedToId != userId)
    .length;
