// lib/presentation/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Ensure correct import paths for your project 'hoque_family_chores'
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
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
        minimumSize: const Size(double.infinity, 50), // Make buttons wider
        textStyle: const TextStyle(fontSize: 16),
        // Add more styling if needed
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
    // You can get user info here if needed, e.g., for a welcome message
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Potentially get user's name from a UserProvider or AuthProvider if it stores it

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
      body: SingleChildScrollView( // Allows content to scroll if it overflows
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Make buttons stretch
          children: <Widget>[
            // Welcome Message (Optional - can be enhanced later)
            const Text(
              'Welcome back!', // TODO: Personalize with user's name if available
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // --- Placeholder for "My Pending Tasks" (Story 4) ---
            // Card(child: ListTile(title: Text('My Pending Tasks - Coming Soon!'))),
            // const SizedBox(height: 16),

            // --- Placeholder for "Pick a Task" (Story 5) ---
            // Card(child: ListTile(title: Text('Pick a Task - Coming Soon!'))),
            // const SizedBox(height: 16),

            // --- Placeholder for "Task Summary Metrics" (Story 2) ---
            // Card(child: ListTile(title: Text('Task Metrics - Coming Soon!'))),
            // const SizedBox(height: 16),

            // --- Placeholder for "Leaderboard" (Story 3) ---
            // Card(child: ListTile(title: Text('Leaderboard - Coming Soon!'))),
            // const SizedBox(height: 24), // Extra space before navigation

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