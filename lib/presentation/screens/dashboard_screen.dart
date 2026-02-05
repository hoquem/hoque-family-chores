import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/widgets/task_summary_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/quick_task_picker_widget.dart';
// For logging

// This screen now represents the content for the 'Home' tab in the AppShell
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  int _calculateLevelFromPoints(int points) {
    // Simple level calculation: every 100 points = 1 level
    return (points / 100).floor() + 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch AuthProvider for user profile details
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    if (currentUser == null) {
      // Handle case where profile is not yet loaded or user is not fully set up (should be handled by AuthWrapper)
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      // Use SingleChildScrollView if content might overflow
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Summary Section
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
                      currentUser.name, // Display user's name
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentUser.email.value, // Display user's email
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        Text(
                          'Level ${_calculateLevelFromPoints(currentUser.points.value)}',
                        ), // Display user's level
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.attach_money,
                        ),
                        Text(
                          '${currentUser.points.value} Points',
                        ), // Display user's total points
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Task Summary Widget
          const TaskSummaryWidget(), // Your task summary widget
          const SizedBox(height: 20),

          // Quick Task Picker Widget
          SizedBox(
            height: 200, // Give a fixed height or wrap in Expanded in a Column with other widgets
            child: const QuickTaskPickerWidget(),
          ),
          const SizedBox(height: 50), // Spacer at the bottom
        ],
      ),
    );
  }
}
