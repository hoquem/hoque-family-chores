// lib/presentation/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';

// --- REMOVED --- All widget-specific providers and widgets are gone from the dashboard body.
// import 'package:hoque_family_chores/presentation/providers/available_tasks_provider.dart';
// import 'package:hoque_family_chores/presentation/widgets/quick_task_picker_widget.dart';

// --- REMOVED --- Mock services are no longer needed here.
// import 'package:hoque_family_chores/services/mock_task_service.dart';

// --- Screens for Navigation (still needed for BottomNavBar) ---
import 'package:hoque_family_chores/presentation/screens/family_list_screen.dart';
import 'package:hoque_family_chores/presentation/screens/task_list_screen.dart';
import 'package:hoque_family_chores/presentation/screens/user_profile_screen.dart';
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
              
              // --- REMOVED --- 'Grab an Unassigned Task!' section.
              
              // --- REMOVED --- The Divider and the entire 'Navigate' section with its buttons.
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
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Progress',
          ),
        ],
        onTap: (index) {
          // Prevent navigation to the current screen
          if (ModalRoute.of(context)?.settings.name == '/dashboard' && index == 0) return;

          Widget? screenToNavigate;
          
          switch (index) {
            case 0:
              // Since we are replacing, we need to handle going back to the dashboard
              screenToNavigate = const DashboardScreen(); 
              break;
            case 1:
              screenToNavigate = const TaskListScreen();
              break;
            case 2:
              screenToNavigate = const FamilyListScreen();
              break;
            case 3:
              screenToNavigate = const GamificationScreen();
              break;
          }

          if (screenToNavigate != null) {
              Navigator.pushReplacement(
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
  
  Widget _buildTaskSummaryRow(BuildContext context, String title, String count, IconData icon, Color color) {
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
  
  Widget _buildLeaderboardRow(BuildContext context, String position, String name, String points, Color color) {
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

  // --- REMOVED --- The _buildNavigationButton helper method is no longer used.
}