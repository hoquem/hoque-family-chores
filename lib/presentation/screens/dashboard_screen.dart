// lib/presentation/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/services/data_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dataService = Provider.of<DataService>(context, listen: false);
    
    // Get user display name or use "Family Member" as fallback
    final displayName = authProvider.displayName ?? 'Family Member';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Chores'),
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
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh user data when pulled down
          await authProvider.refreshUserProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Text(
                'Welcome, $displayName!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // User info card
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
                            child: authProvider.photoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.network(
                                      authProvider.photoUrl!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => 
                                          Text(displayName[0].toUpperCase()),
                                    ),
                                  )
                                : Text(
                                    displayName[0].toUpperCase(),
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
              
              // Task summary section
              Text(
                'My Tasks',
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
                        '3', 
                        Icons.pending_actions, 
                        Colors.orange
                      ),
                      const Divider(),
                      _buildTaskSummaryRow(
                        context, 
                        'In Progress', 
                        '1', 
                        Icons.hourglass_top, 
                        Colors.blue
                      ),
                      const Divider(),
                      _buildTaskSummaryRow(
                        context, 
                        'Completed', 
                        '12', 
                        Icons.task_alt, 
                        Colors.green
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Family leaderboard preview
              Text(
                'Family Leaderboard',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // These would be populated with real data in a full implementation
                      _buildLeaderboardRow(context, '1', 'Amina', '1100', Colors.amber),
                      _buildLeaderboardRow(context, '2', 'Yusuf', '920', Colors.grey.shade400),
                      _buildLeaderboardRow(context, '3', 'Zahra', '850', Colors.brown),
                    ],
                  ),
                ),
              ),
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
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          // This would navigate to different screens in a full implementation
          if (index != 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Navigation to ${[
                  'Dashboard', 
                  'Tasks', 
                  'Family', 
                  'Profile'
                ][index]} coming soon!'),
              ),
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
}
