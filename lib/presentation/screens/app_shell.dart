import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
// Import all screens that will be part of the bottom navigation
import 'package:hoque_family_chores/presentation/screens/dashboard_screen.dart'; // This is now the content for the 'Home' tab
import 'package:hoque_family_chores/presentation/screens/task_list_screen.dart';
import 'package:hoque_family_chores/presentation/screens/family_list_screen.dart';
import 'package:hoque_family_chores/presentation/screens/gamification_screen.dart'; // Used as 'Progress'
import 'package:hoque_family_chores/presentation/screens/user_profile_screen.dart'; // For modal display
import 'package:hoque_family_chores/services/logging_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0; // Set initial index to 0 for the Dashboard content tab

  // List of main content widgets for each tab
  // Change to 'static final' because the widgets themselves might not be const,
  // especially if they are StatefulWidgets or contain dynamic Provider consumption.
  static final List<Widget> _widgetOptions = <Widget>[ // <--- CHANGED TO static final
    DashboardScreen(),     // Index 0: This is the actual Dashboard content
    TaskListScreen(),      // Index 1: Tasks
    FamilyListScreen(),    // Index 2: Family
    GamificationScreen(),  // Index 3: Progress/Gamification
  ];

  // Titles corresponding to each tab's AppBar
  static const List<String> _appBarTitles = <String>[
    'Dashboard',  // Title for DashboardScreen content
    'My Tasks',   // Title for TaskListScreen
    'Family',     // Title for FamilyListScreen
    'Progress',   // Title for GamificationScreen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _appBarTitles[_selectedIndex], // Dynamic title based on selected tab
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundImage: authProvider.photoUrl != null && authProvider.photoUrl!.isNotEmpty
                  ? NetworkImage(authProvider.photoUrl!)
                  : null,
              child: authProvider.photoUrl == null || authProvider.photoUrl!.isEmpty
                  ? Text(authProvider.displayName?.substring(0, 1).toUpperCase() ?? '')
                  : null,
            ),
            onPressed: () {
              logger.i("Navigating to User Profile Screen (Modal).");
              // This pushes the UserProfileScreen as a new full-screen route,
              // which will cover the NavBar.
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const UserProfileScreen()),
              );
            },
            tooltip: 'View Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              logger.i("Logging out user.");
              await authProvider.signOut();
              // AuthWrapper will handle navigation after sign-out
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack( // IndexedStack keeps all tabs alive and switches their visibility
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar( // The persistent NavBar
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home), // Icon for Dashboard
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.family_restroom),
            label: 'Family',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up), // Using a generic icon for 'Progress'
            label: 'Progress',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey, // Ensure unselected items are visible
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Use fixed type if you have more than 3 items
      ),
    );
  }
}