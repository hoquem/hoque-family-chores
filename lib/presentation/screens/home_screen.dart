import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/widgets/task_summary_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/quick_task_picker_widget.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_summary_notifier.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refreshData(WidgetRef ref) async {
    logger.i("[HomeScreen] Refreshing data...");
    final authState = ref.read(authNotifierProvider);
    final currentUser = authState.user;
    final familyId = currentUser?.familyId;

    if (currentUser != null && familyId != null) {
      logger.d("[HomeScreen] User profile and family ID available. User: ${currentUser.id}, Family: $familyId");
      try {
        await Future.wait([
          ref.read(taskSummaryNotifierProvider(familyId).notifier).refresh(),
        ]);
        logger.i("[HomeScreen] Data refresh completed successfully");
      } catch (e, s) {
        logger.e("[HomeScreen] Error refreshing data: $e", error: e, stackTrace: s);
      }
    } else {
      logger.w("[HomeScreen] Cannot refresh data - missing user profile or family ID. User: $currentUser, FamilyId: $familyId");
    }
  }

  Widget _buildUserProfileSection(User currentUser) {
    logger.d("[HomeScreen] Building user profile section for user: ${currentUser.id}");
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          child: Text(
            currentUser.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(fontSize: 30),
          ),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  Text(
                    'Level ${_calculateLevelFromPoints(currentUser.points.value)}',
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.attach_money),
                  Text('${currentUser.points.value} Points'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _calculateLevelFromPoints(int points) {
    // Simple level calculation: every 100 points = 1 level
    return (points / 100).floor() + 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.d("[HomeScreen] Building screen");
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    if (currentUser == null) {
      logger.w("[HomeScreen] User profile is null - showing loading indicator");
      return const Center(child: CircularProgressIndicator());
    }

    logger.d("[HomeScreen] Building home screen for user: ${currentUser.id}");
    return RefreshIndicator(
      onRefresh: () => _refreshData(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserProfileSection(currentUser),
              const SizedBox(height: 24.0),
              const Text(
                'Task Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              const TaskSummaryWidget(),
              const SizedBox(height: 24.0),
              const Text(
                'Quick Tasks',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              const QuickTaskPickerWidget(),
              const SizedBox(height: 50.0), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
