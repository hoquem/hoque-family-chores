import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/presentation/motion/animated_star_count.dart';
import 'package:hoque_family_chores/presentation/motion/entrance_stagger.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/status_pill.dart';
import 'package:hoque_family_chores/presentation/widgets/user_avatar.dart';
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
    final familyId = widget.member.familyId;
    final tasksAsync = ref.watch(taskListStreamProvider(familyId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member.name),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          final memberTasks = tasks.where((t) {
            final assignedToId = t.assignedToId;
            final createdById = t.createdById;
            return (assignedToId != null &&
                    assignedToId.value == widget.member.id.value) ||
                (createdById != null &&
                    createdById.value == widget.member.id.value);
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
                    // Header card
                    _HeaderCard(
                      member: widget.member,
                      totalCompleted: totalCompleted,
                      totalStars: totalStars,
                      weekCount: weekCount,
                      weekStars: weekStars,
                    ),
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
                _TaskList(tasks: currentTasks, isCompleted: false, member: widget.member)
              else
                _TaskList(tasks: completedTasks, isCompleted: true, member: widget.member),
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
                        member.role.displayName,
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
