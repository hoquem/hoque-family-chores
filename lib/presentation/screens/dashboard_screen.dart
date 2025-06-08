// lib/presentation/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';

// Imports from origin/main
import 'package:hoque_family_chores/presentation/providers/my_tasks_provider.dart';
import 'package:hoque_family_chores/presentation/providers/available_tasks_provider.dart';
import 'package:hoque_family_chores/presentation/providers/task_summary_provider.dart';
import 'package:hoque_family_chores/presentation/providers/leaderboard_provider.dart';

// --- Widgets --- (from origin/main)
import 'package:hoque_family_chores/presentation/widgets/my_tasks_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/quick_task_picker_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/task_summary_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/leaderboard_widget.dart';

// --- Services --- (from origin/main, used by its providers)
import 'package:hoque_family_chores/services/mock_task_service.dart';
import 'package:hoque_family_chores/services/mock_task_summary_service.dart';
import 'package:hoque_family_chores/services/mock_leaderboard_service.dart';

// --- Screens for Navigation --- (from origin/main)
import 'package:hoque_family_chores/presentation/screens/family_list_screen.dart';
import 'package:hoque_family_chores/presentation/screens/task_list_screen.dart';
import 'package:hoque_family_chores/presentation/screens/user_profile_screen.dart';
import 'package:hoque_family_chores/presentation/screens/settings_screen.dart';
import 'package:hoque_family_chores/presentation/screens/gamification_screen.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final displayName = authProvider.displayName ?? 'Family Member';
    final photoUrl = authProvider.photoUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Chores'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).primaryColorLight,
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          photoUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U'),
                        ),
                      )
                    : Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U'),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await authProvider.refreshUserProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $displayName!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).primaryColorLight,
                            child: authProvider.photoUrl != null && authProvider.photoUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.network(
                                      authProvider.photoUrl!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U'),
                                    ),
                                  )
                                : Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (authProvider.userEmail != null)
                                  Text(
                                    authProvider.userEmail!,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                const SizedBox(height: 4),
                                const Text('Level: 3 • Points: 850'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'My Tasks Summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTaskSummaryRow(
                        context, 'Pending', '3', Icons.pending_actions, Colors.orange),
                      const Divider(),
                      _buildTaskSummaryRow(
                        context, 'In Progress', '1', Icons.hourglass_top, Colors.blue),
                      const Divider(),
                      _buildTaskSummaryRow(
                        context, 'Completed', '12', Icons.task_alt, Colors.green),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Family Leaderboard Preview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildLeaderboardRow(context, '1', 'Amina', '1100', Colors.amber),
                      _buildLeaderboardRow(context, '2', 'Yusuf', '920', Colors.grey.shade400),
                      _buildLeaderboardRow(context, '3', 'Zahra', '850', Colors.brown),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildNavigationButton(
                context: context,
                icon: Icons.emoji_events,
                label: 'Achievements & Rewards',
                screen: const GamificationScreen(),
              ),
              const SizedBox(height: 24),
              
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

              const Text(
                'Detailed Task Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ChangeNotifierProvider(
                create: (context) => TaskSummaryProvider(MockTaskSummaryService())..fetchTaskSummary(),
                child: const TaskSummaryWidget(),
              ),
              const SizedBox(height: 24),

              const Text(
                'Detailed Family Leaderboard',
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
                icon: Icons.settings_rounded,
                label: 'Settings',
                screen: const SettingsScreen(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, 
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Family',
          ),
        ],
        onTap: (index) {
          Widget? screenToNavigate;
          
          switch (index) {
            case 0: // Dashboard
              Provider.of<AuthProvider>(context, listen: false).refreshUserProfile();
              return;
            case 1: // Tasks
              screenToNavigate = const TaskListScreen();
              break;
            case 2: // Family
              screenToNavigate = const FamilyListScreen();
              break;
          }

          if (screenToNavigate != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => screenToNavigate!),
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create new task feature coming soon!'),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add new task',
      ),
    );
  }
  
  // --- FIXED --- Helper methods are now fully included.
  
  // Helper method for simple task summary rows
  Widget _buildTaskSummaryRow(
    BuildContext context, 
    String title, 
    String count, 
    IconData icon, 
    Color color
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: Colors.grey.shade600),
        ],
      ),
    );
  }
  
  // Helper method for simple leaderboard rows
  Widget _buildLeaderboardRow(
    BuildContext context, 
    String position, 
    String name, 
    String points, 
    Color color
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                position,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            name,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Spacer(),
          Text(
            '$points pts',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for navigation buttons
  Widget _buildNavigationButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Widget screen,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
        minimumSize: const Size(double.infinity, 50), // Ensures buttons are same width
      ),
    );
  }
}