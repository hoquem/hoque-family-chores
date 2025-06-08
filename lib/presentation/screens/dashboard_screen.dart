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
// Note: These are specific mock services. Our DataService (when MockDataService is active)
// could potentially provide this data, but for merge conflict resolution,
// we keep origin/main's provider dependencies as they were.
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
    // final dataService = Provider.of<DataService>(context, listen: false); // Available if needed by HEAD's sections
    
    // Get user display name or use "Family Member" as fallback
    final displayName = authProvider.displayName ?? 'Family Member';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Chores'), // Title from HEAD
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Logout',
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator( // From HEAD
        onRefresh: () async {
          // Refresh user data when pulled down
          await authProvider.refreshUserProfile();
          // TODO: Consider refreshing other providers if necessary and feasible
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // From HEAD
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Alignment from HEAD
            children: [
              // Welcome message (from HEAD)
              Text(
                'Welcome, $displayName!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // User info card (from HEAD)
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
                                // This would be populated with real data in a full implementation
                                // For now, it's a placeholder. Real data would come from a GamificationProvider or UserProfileProvider
                                const Text('Level: 3 • Points: 850'), // Placeholder from HEAD
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
              
              // Task summary section (preview style from HEAD)
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
                      // These would be populated with real data in a full implementation
                      _buildTaskSummaryRow(
                        context, 
                        'Pending', 
                        '3', // Placeholder
                        Icons.pending_actions, 
                        Colors.orange
                      ),
                      const Divider(),
                      _buildTaskSummaryRow(
                        context, 
                        'In Progress', 
                        '1', // Placeholder
                        Icons.hourglass_top, 
                        Colors.blue
                      ),
                      const Divider(),
                      _buildTaskSummaryRow(
                        context, 
                        'Completed', 
                        '12', // Placeholder
                        Icons.task_alt, 
                        Colors.green
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Family leaderboard preview (style from HEAD)
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
                      // These would be populated with real data in a full implementation
                      _buildLeaderboardRow(context, '1', 'Amina', '1100', Colors.amber), // Placeholder, using amber
                      _buildLeaderboardRow(context, '2', 'Yusuf', '920', Colors.grey.shade400), // Placeholder
                      _buildLeaderboardRow(context, '3', 'Zahra', '850', Colors.brown), // Placeholder
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --Gamification Section--- (from origin/main)
              _buildNavigationButton(
                context: context,
                icon: Icons.emoji_events,
                label: 'Achievements & Rewards',
                screen: const GamificationScreen(),
              ),
              const SizedBox(height: 24), // Added spacing
              
              // --- My Pending Tasks Section --- (from origin/main)
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
              
              // --- Quick Task Picker Section --- (from origin/main)
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

              // --- Task Summary Metrics Section --- (from origin/main)
              const Text(
                'Detailed Task Summary', // Differentiated title
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ChangeNotifierProvider(
                create: (context) => TaskSummaryProvider(MockTaskSummaryService())..fetchTaskSummary(),
                child: const TaskSummaryWidget(),
              ),
              const SizedBox(height: 24),

              // --- Leaderboard Section --- (from origin/main)
              const Text(
                'Detailed Family Leaderboard', // Differentiated title
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ChangeNotifierProvider(
                create: (context) => LeaderboardProvider(MockLeaderboardService())..fetchLeaderboard(),
                child: const LeaderboardWidget(),
              ),
              const SizedBox(height: 24),

              const Divider(height: 32, thickness: 1), // from origin/main

              // Navigation Section (from origin/main)
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
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar( // From HEAD
        currentIndex: 0, // Default to Dashboard tab
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          // This would navigate to different screens in a full implementation
          // For now, map to existing navigation or show snackbar
          Widget? screenToNavigate;
          String screenName = '';

          switch (index) {
            case 0: // Dashboard
              // Already on dashboard, do nothing or refresh
              Provider.of<AuthProvider>(context, listen: false).refreshUserProfile();
              return;
            case 1: // Tasks
              screenToNavigate = const TaskListScreen();
              screenName = 'Tasks';
              break;
            case 2: // Family
              screenToNavigate = const FamilyListScreen();
              screenName = 'Family';
              break;
            case 3: // Profile
              screenToNavigate = const UserProfileScreen();
              screenName = 'Profile';
              break;
          }

          if (screenToNavigate != null) {
             Navigator.push(
               context,
               MaterialPageRoute(builder: (context) => screenToNavigate!),
             );
          } else if (screenName.isNotEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('Navigation to $screenName coming soon!'),
               ),
             );
          }
        },
      ),
      floatingActionButton: FloatingActionButton( // From HEAD
        onPressed: () {
          // Navigate to a create task screen or show a dialog
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
  
  // Helper method for simple task summary rows (from HEAD)
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
  
  // Helper method for simple leaderboard rows (from HEAD)
  Widget _buildLeaderboardRow(
    BuildContext context, 
    String position, 
    String name, 
    String points, 
    Color color // e.g., Colors.amber for 1st, Colors.grey.shade400 for 2nd
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

  // Helper method for navigation buttons (from origin/main)
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
      ),
    );
  }
}
