import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/widgets/task_summary_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  int _calculateLevelFromPoints(int points) {
    return (points / 100).floor() + 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: (currentUser.photoUrl?.isNotEmpty ?? false)
                    ? NetworkImage(currentUser.photoUrl!)
                    : null,
                child: (currentUser.photoUrl?.isEmpty ?? true)
                    ? Text(
                        currentUser.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 30),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentUser.email.value,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        Text('Level ${_calculateLevelFromPoints(currentUser.points.value)}'),
                        const SizedBox(width: 10),
                        const Icon(Icons.attach_money),
                        Text('${currentUser.points.value} Points'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const TaskSummaryWidget(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
