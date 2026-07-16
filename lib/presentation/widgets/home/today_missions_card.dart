import 'package:flutter/material.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/services/home_stats.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

/// The child's tasks for today: open ones first, then those waiting for
/// approval, then today's finished ones.
class TodayMissionsCard extends StatelessWidget {
  const TodayMissionsCard({
    super.key,
    required this.missions,
    required this.onComplete,
  });

  final TodayMissions missions;
  final void Function(Task task) onComplete;

  bool get _isEmpty =>
      missions.toDo.isEmpty &&
      missions.waiting.isEmpty &&
      missions.done.isEmpty;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              "Today's Missions",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (_isEmpty)
            const ListTile(title: Text('No missions today 🎈')),
          ...missions.toDo.map(
            (task) => ListTile(
              leading: IconButton(
                tooltip: 'Mark as done',
                icon: const Icon(Icons.circle_outlined),
                onPressed: () => onComplete(task),
              ),
              title: Text(task.title),
              trailing: Text(
                '+${task.points.value} ⭐',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          ...missions.waiting.map(
            (task) => ListTile(
              // Deep tone, not the base: amberWarn on cream is 2.01:1, under
              // the 3:1 WCAG floor for a meaningful icon.
              leading:
                  Icon(Icons.hourglass_top, color: context.tokens.amberWarnDeep),
              title: Text(task.title),
              subtitle: const Text('Waiting for approval ⏳'),
            ),
          ),
          ...missions.done.map(
            (task) => ListTile(
              // sprout on cream is 2.60:1; sproutDeep clears the 3:1 floor.
              leading: Icon(Icons.check_circle, color: context.tokens.sproutDeep),
              title: Text(
                task.title,
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              subtitle: const Text('Done today! ✅'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
