import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Needed to access AuthProvider
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart'; // Needed for AuthProvider
import 'package:hoque_family_chores/presentation/widgets/task_summary_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/quick_task_picker_widget.dart'; // <--- Ensure this import is here
// For logging

// This screen now represents the content for the 'Home' tab in the AppShell
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch AuthProvider for user profile details
    final authProvider = context.watch<AuthProvider>();

    // Retrieve user profile for display
    final currentUserProfile = authProvider.currentUserProfile;

    if (currentUserProfile == null) {
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
                backgroundImage:
                    currentUserProfile.avatarUrl != null &&
                            currentUserProfile.avatarUrl!.isNotEmpty
                        ? NetworkImage(currentUserProfile.avatarUrl!)
                        : null,
                child:
                    currentUserProfile.avatarUrl == null ||
                            currentUserProfile.avatarUrl!.isEmpty
                        ? Text(
                          currentUserProfile.name.substring(0, 1).toUpperCase(),
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
                      currentUserProfile.name, // Display user's name
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentUserProfile.email ??
                          'No Email', // Display user's email
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ), // This was missing const
                        Text(
                          'Level ${currentUserProfile.currentLevel}',
                        ), // Display user's level
                        const SizedBox(width: 10), // This was missing const
                        const Icon(
                          Icons.attach_money,
                        ), // This was missing const
                        Text(
                          '${currentUserProfile.totalPoints} Points',
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
            // <--- REMOVED const HERE
            height:
                200, // Give a fixed height or wrap in Expanded in a Column with other widgets
            child:
                QuickTaskPickerWidget(), // Not const, so parent SizedBox cannot be const
          ),
          const SizedBox(height: 50), // Spacer at the bottom
        ],
      ),
    );
  }
}
