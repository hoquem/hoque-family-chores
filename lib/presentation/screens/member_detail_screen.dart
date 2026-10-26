import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/repositories/managed_child_repository.dart';
import 'package:hoque_family_chores/domain/services/managed_child_policy.dart';
import 'package:hoque_family_chores/domain/usecases/family/join_family_usecase.dart'
    show formatInviteCode;
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/member_profile_provider.dart';
import 'package:hoque_family_chores/presentation/screens/child_mode_screen.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/presentation/motion/animated_star_count.dart';
import 'package:hoque_family_chores/presentation/motion/entrance_stagger.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/status_pill.dart';
import 'package:hoque_family_chores/presentation/widgets/user_avatar.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import '../utils/task_status_label.dart';

/// Detail screen for a family member: shows their task activity, current
/// assignments, and completed chore history.
class MemberDetailScreen extends ConsumerStatefulWidget {
  final User member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  int _selectedSegment = 0; // 0 = Current tasks, 1 = Completed tasks

  @override
  Widget build(BuildContext context) {
    // The live profile, so stars and the managed state follow the server; the
    // member passed in is what shows until the stream's first event.
    final profile = ref.watch(memberProfileProvider(widget.member.id));
    ref.listen(memberProfileProvider(widget.member.id), (_, next) {
      if (next.hasError) {
        logger.e('MemberDetailScreen: live profile failed',
            error: next.error, stackTrace: next.stackTrace);
      }
    });
    if (profile.hasValue && profile.valueOrNull == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.member.name)),
        body: Center(
          child: Text('${widget.member.name} is no longer in this family'),
        ),
      );
    }
    final member = profile.valueOrNull ?? widget.member;
    final familyId = member.familyId;
    final tasksAsync = ref.watch(taskListStreamProvider(familyId));

    return Scaffold(
      appBar: AppBar(
        title: Text(member.name),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          final memberTasks = tasks.where((t) {
            final assignedToId = t.assignedToId;
            final createdById = t.createdById;
            return (assignedToId != null &&
                    assignedToId.value == member.id.value) ||
                (createdById != null &&
                    createdById.value == member.id.value);
          });

          final currentTasks = memberTasks
              .where((t) =>
                  t.status == TaskStatus.assigned ||
                  t.status == TaskStatus.inProgress ||
                  t.status == TaskStatus.pendingApproval ||
                  t.status == TaskStatus.needsRevision)
              .toList();

          final completedTasks = memberTasks
              .where((t) => t.status == TaskStatus.completed)
              .toList()
            ..sort((a, b) {
              // Sort by approvedAt desc, fallback to completedAt or createdAt
              final aDate = a.approvedAt ?? a.createdAt;
              final bDate = b.approvedAt ?? b.createdAt;
              return bDate.compareTo(aDate);
            });

          final totalCompleted = completedTasks.length;
          final totalStars = completedTasks.fold(0, (sum, t) => sum + t.points.value);

          // Weekly stats (last 7 days)
          final weekAgo = DateTime.now().subtract(const Duration(days: 7));
          final weekTasks = completedTasks.where((t) =>
              (t.approvedAt ?? t.createdAt).isAfter(weekAgo));
          final weekCount = weekTasks.length;
          final weekStars = weekTasks.fold(0, (sum, t) => sum + t.points.value);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profile.hasError)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          "Couldn't update ${member.name}'s details",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    // Header card
                    _HeaderCard(
                      member: member,
                      totalCompleted: totalCompleted,
                      totalStars: totalStars,
                      weekCount: weekCount,
                      weekStars: weekStars,
                    ),
                    _ManagedChildActions(member: member),
                    // Segmented control
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(
                            value: 0,
                            label: Text('Current'),
                          ),
                          ButtonSegment(
                            value: 1,
                            label: Text('Completed'),
                          ),
                        ],
                        selected: {
                          _selectedSegment,
                        },
                        onSelectionChanged: (value) => setState(() {
                          _selectedSegment = value.first;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedSegment == 0)
                _TaskList(tasks: currentTasks, isCompleted: false, member: member)
              else
                _TaskList(tasks: completedTasks, isCompleted: true, member: member),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load chores: $error'),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final User member;
  final int totalCompleted;
  final int totalStars;
  final int weekCount;
  final int weekStars;

  const _HeaderCard({
    required this.member,
    required this.totalCompleted,
    required this.totalStars,
    required this.weekCount,
    required this.weekStars,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                UserAvatar(user: member, radius: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        member.isManaged
                            ? '${member.role.displayName} · No phone'
                            : member.role.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.tokens.inkSoft,
                            ),
                      ),
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodyLarge!,
                        child: AnimatedStarCount(member.points.toInt()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatBlock(
                    label: 'This week',
                    count: weekCount,
                    subtitle: '$weekStars ⭐',
                  ),
                ),
                Expanded(
                  child: _StatBlock(
                    label: 'All time',
                    count: totalCompleted,
                    subtitle: '$totalStars ⭐',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final int count;
  final String subtitle;

  const _StatBlock({
    required this.label,
    required this.count,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.tokens.inkSoft,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.tokens.ink,
              ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.tokens.inkSoft,
              ),
        ),
      ],
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<Task> tasks;
  final bool isCompleted;
  final User member;

  const _TaskList({
    required this.tasks,
    required this.isCompleted,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle_outline : Icons.assignment_outlined,
                  size: 48,
                  color: context.tokens.inkMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  isCompleted
                      ? 'No completed chores yet'
                      : 'No active chores',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: context.tokens.inkMuted,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final task = tasks[index];
          return EntranceStagger(
            index: index,
            child: _TaskTile(
              task: task,
              isCompleted: isCompleted,
              member: member,
            ),
          );
        },
        childCount: tasks.length,
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final bool isCompleted;
  final User member;

  const _TaskTile({
    required this.task,
    required this.isCompleted,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    final date = task.approvedAt ?? task.createdAt;
    final dateText = '${date.day}/${date.month}/${date.year}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(
          task.title,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? context.tokens.inkMuted : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (!isCompleted)
              StatusPill(
                status: task.status,
                label: taskStatusLabel(task.status),
              )
            else
              Row(
                children: [
                  Text(
                    '${task.points.value} ⭐',
                    style: TextStyle(color: context.tokens.starGold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateText,
                    style: TextStyle(color: context.tokens.inkSoft, fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
        trailing: isCompleted
            ? Icon(Icons.check_circle, color: context.tokens.sproutDeep)
            : null,
      ),
    );
  }
}

/// Hand the phone over, move to their own phone, or remove: only for a
/// parent or guardian looking at a managed child (see canActForMember).
class _ManagedChildActions extends ConsumerStatefulWidget {
  const _ManagedChildActions({required this.member});

  final User member;

  @override
  ConsumerState<_ManagedChildActions> createState() =>
      _ManagedChildActionsState();
}

class _ManagedChildActionsState extends ConsumerState<_ManagedChildActions> {
  /// True while the link code is being created (a 3-7 s callable): the button
  /// shows progress and ignores taps so a second request cannot start.
  bool _creatingLinkCode = false;

  User get member => widget.member;

  @override
  Widget build(BuildContext context) {
    final viewer = ref.watch(authNotifierProvider).user;
    if (viewer == null || !canActForMember(viewer: viewer, member: member)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            icon: const Icon(Icons.phone_iphone),
            label: Text('Hand the phone to ${member.name}'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  ChildModeScreen(childId: member.id, parentName: viewer.name),
            )),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: _creatingLinkCode
                ? const SizedBox(
                    key: Key('link_code_progress'),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.qr_code),
            label: Text('Move ${member.name} to their own phone'),
            onPressed: _creatingLinkCode ? null : _showLinkCode,
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.tokens.brick),
            onPressed: _remove,
            child: Text('Remove ${member.name}'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLinkCode() async {
    setState(() => _creatingLinkCode = true);
    final LinkCode link;
    try {
      link = await ref
          .read(managedChildRepositoryProvider)
          .createLinkCode(member.familyId, member.id);
    } on DataException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } finally {
      if (mounted) setState(() => _creatingLinkCode = false);
    }
    if (!mounted) return;
    // The child may have linked a phone while the code was being made.
    final viewer = ref.read(authNotifierProvider).user;
    if (viewer == null || !canActForMember(viewer: viewer, member: member)) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Move ${member.name} to their own phone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('On ${member.name}\'s phone: install Chores Star, tap '
                '"I\'m a kid", then "Use a link code", and enter:'),
            const SizedBox(height: 16),
            SelectableText(
              formatInviteCode(link.code),
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text('It works once, for 24 hours.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${member.name}?'),
        content: Text('${member.name}\'s chores go back to the family, and '
            'their stars are gone for good.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(managedChildRepositoryProvider)
          .removeManagedChild(member.familyId, member.id);
    } on DataException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    ref.invalidate(familyMembersNotifierProvider(member.familyId));
    Navigator.of(context).pop();
  }
}
