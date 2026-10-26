import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/user.dart';
import '../../domain/services/task_actions.dart';
import '../../domain/value_objects/user_id.dart';
import '../motion/animated_star_count.dart';
import '../motion/celebration_listener.dart';
import '../providers/riverpod/auth_notifier.dart';
import '../providers/riverpod/member_profile_provider.dart';
import '../providers/riverpod/task_list_notifier.dart';
import '../theme/app_tokens.dart';
import '../utils/task_status_label.dart';
import '../widgets/user_avatar.dart';
import 'rewards_screen.dart';
import 'task_details_screen.dart';

/// The child view: a managed child (no phone of their own) using a parent's
/// phone. Firebase stays signed in as the parent; this route passes the
/// child's id into the same use cases the rest of the app uses.
///
/// Being a pushed route is the whole "who is using the phone" state: nothing
/// is persisted, so a cold start always opens the parent's view, and popping
/// returns to it. The route closes itself if the child is removed or moves to
/// a phone of their own.
class ChildModeScreen extends ConsumerStatefulWidget {
  const ChildModeScreen({
    super.key,
    required this.childId,
    required this.parentName,
  });

  final UserId childId;
  final String parentName;

  @override
  ConsumerState<ChildModeScreen> createState() => _ChildModeScreenState();
}

class _ChildModeScreenState extends ConsumerState<ChildModeScreen> {
  int _tab = 0;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    final parent = ref.read(authNotifierProvider).user;
    if (parent != null) {
      ref.read(analyticsProvider).log(
            AnalyticsEventName.childModeEntered,
            userId: parent.id.value,
            familyId: parent.familyId.value,
          );
    }
  }

  /// Closes this screen's own route, and anything the child opened above it
  /// (e.g. chore details), so the parent's screen is left on top.
  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    final route = ModalRoute.of(context)!;
    final navigator = Navigator.of(context);
    navigator.popUntil((r) => r == route);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(memberProfileProvider(widget.childId));
    if (profile.hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load the profile: ${profile.error}',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('child_mode_back'),
                  onPressed: _close,
                  child: Text('Back to ${widget.parentName}'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!profile.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final child = profile.value;
    if (child == null || !child.isManaged) {
      // Removed, or moved to their own phone: this view no longer applies.
      WidgetsBinding.instance.addPostFrameCallback((_) => _close());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // This route covers MainScreen, whose CelebrationListener is offstage
    // under it, so the child's own celebrations (a treat claimed) play here.
    // No review prompt: the child, not the signed-in parent, has the phone.
    return CelebrationListener(
      offersReviewPrompt: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              UserAvatar(user: child, radius: 18),
              const SizedBox(width: 12),
              Flexible(child: Text(child.name, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 12),
              AnimatedStarCount(child.points.toInt()),
            ],
          ),
          actions: [
            TextButton.icon(
              key: const Key('child_mode_back'),
              icon: const Icon(Icons.swap_horiz),
              label: Text('Back to ${widget.parentName}'),
              onPressed: _close,
            ),
          ],
        ),
        body: _tab == 0 ? _ChildChores(child: child) : RewardsScreen(actingAs: child),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.checklist), label: 'My chores'),
            NavigationDestination(icon: Icon(Icons.card_giftcard), label: 'Treats'),
          ],
        ),
      ),
    );
  }
}

/// The child's own chores, then the ones up for grabs. Done and Take act as
/// the child; a photo-proof chore opens its details, where the camera flow
/// lives.
class _ChildChores extends ConsumerWidget {
  const _ChildChores({required this.child});

  final User child;

  static const _active = {
    TaskStatus.assigned,
    TaskStatus.inProgress,
    TaskStatus.needsRevision,
    TaskStatus.pendingApproval,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListStreamProvider(child.familyId));
    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load chores: $e')),
      data: (tasks) {
        final mine = tasks
            .where((t) => t.assignedToId == child.id && _active.contains(t.status))
            .toList();
        final open = tasks.where((t) => t.status == TaskStatus.available).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Your chores', style: Theme.of(context).textTheme.titleMedium),
            if (mine.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Nothing to do right now.'),
              ),
            for (final t in mine) _ChoreTile(task: t, child: child),
            const SizedBox(height: 16),
            Text('Up for grabs', style: Theme.of(context).textTheme.titleMedium),
            for (final t in open) _ChoreTile(task: t, child: child),
          ],
        );
      },
    );
  }
}

class _ChoreTile extends ConsumerWidget {
  const _ChoreTile({required this.task, required this.child});

  final Task task;
  final User child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions =
        taskActionsFor(task: task, viewerId: child.id, viewerRole: child.role);
    final notifier = ref.read(taskListNotifierProvider(child.familyId).notifier);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          backgroundColor: context.tokens.brickDeep,
        ));
      }
    }

    Widget? trailing;
    if (actions.contains(TaskAction.complete) && !task.requiresPhotoProof) {
      trailing = FilledButton(
        onPressed: () => run(() => notifier.completeTask(
              task.id.value,
              child.id,
              child.familyId,
            )),
        child: const Text('Done'),
      );
    } else if (actions.contains(TaskAction.claim)) {
      trailing = OutlinedButton(
        onPressed: () => run(() => notifier.claimTask(
              task.id.value,
              child.id,
              child.familyId,
            )),
        child: const Text('Take'),
      );
    }

    return Card(
      child: ListTile(
        title: Text(task.title),
        subtitle: Text('${taskStatusLabel(task.status)} · ${task.points.value} ⭐'),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TaskDetailsScreen(task: task, actingAs: child),
        )),
      ),
    );
  }
}
