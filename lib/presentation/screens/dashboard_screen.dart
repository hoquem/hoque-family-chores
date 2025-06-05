// lib/presentation/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// App-specific imports - ensure all paths are correct for your project
// --- Providers ---
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/presentation/providers/my_tasks_provider.dart';
import 'package:hoque_family_chores/presentation/providers/available_tasks_provider.dart';
import 'package:hoque_family_chores/presentation/providers/task_summary_provider.dart';
import 'package:hoque_family_chores/presentation/providers/leaderboard_provider.dart';

// --- Widgets ---
import 'package:hoque_family_chores/presentation/widgets/my_tasks_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/quick_task_picker_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/task_summary_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/leaderboard_widget.dart';

// --- Services ---
import 'package:hoque_family_chores/services/mock_task_service.dart';
import 'package:hoque_family_chores/services/mock_task_summary_service.dart';
import 'package:hoque_family_chores/services/mock_leaderboard_service.dart';

// --- Screens for Navigation ---
import 'package:hoque_family_chores/presentation/screens/family_list_screen.dart';
import 'package:hoque_family_chores/presentation/screens/task_list_screen.dart';
import 'package:hoque_family_chores/presentation/screens/user_profile_screen.dart';
import 'package:hoque_family_chores/presentation/screens/settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Helper method to create styled navigation buttons
  Widget _buildNavigationButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Widget screen,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        textStyle: const TextStyle(fontSize: 16),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Welcome Message
            const Text(
              'Welcome back!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // --- My Pending Tasks Section ---
            const Text(
              'My Pending Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ChangeNotifierProvider(
              create: (context) => MyTasksProvider(MockTaskService())..fetchMyPendingTasks(),
              child: const MyTasksWidget(),
            ),
            const SizedBox(height: 24),
            
            // --- Quick Task Picker Section ---
            const Text(
              'Grab an Unassigned Task!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ChangeNotifierProvider(
              create: (context) => AvailableTasksProvider(MockTaskService())..fetchAvailableTasks(),
              child: const QuickTaskPickerWidget(),
            ),
            const SizedBox(height: 24),

            // --- Task Summary Metrics Section ---
            const Text(
              'Task Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ChangeNotifierProvider(
              create: (context) => TaskSummaryProvider(MockTaskSummaryService())..fetchTaskSummary(),
              child: const TaskSummaryWidget(),
            ),
            const SizedBox(height: 24),

            // --- Leaderboard Section ---
            const Text(
              'Family Leaderboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ChangeNotifierProvider(
              create: (context) => LeaderboardProvider(MockLeaderboardService())..fetchLeaderboard(),
              child: const LeaderboardWidget(),
            ),
            const SizedBox(height: 24),

            const Divider(height: 32, thickness: 1),

            // Navigation Section
            const Text(
              'Navigate',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            _buildNavigationButton(
              context: context,
              icon: Icons.list_alt_rounded,
              label: 'Task List',
              screen: const TaskListScreen(),
            ),
            const SizedBox(height: 12),

            _buildNavigationButton(
              context: context,
              icon: Icons.family_restroom_rounded,
              label: 'Family Members',
              screen: const FamilyListScreen(),
            ),
            const SizedBox(height: 12),

            _buildNavigationButton(
              context: context,
              icon: Icons.person_rounded,
              label: 'My Profile',
              screen: const UserProfileScreen(),
            ),
            const SizedBox(height: 12),

            _buildNavigationButton(
              context: context,
              icon: Icons.settings_rounded,
              label: 'Settings',
              screen: const SettingsScreen(),
            ),
          ],
        ),
      ),
    );
  }
}