import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/widgets/task_summary_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/quick_task_picker_widget.dart';
import 'package:hoque_family_chores/presentation/providers/task_summary_provider.dart';
import 'package:hoque_family_chores/presentation/providers/task_provider.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _logger = AppLogger();

  Future<void> _refreshData() async {
    _logger.d('HomeScreen: Refreshing data');
    final taskSummaryProvider = context.read<TaskSummaryProvider>();
    final taskProvider = context.read<TaskProvider>();
    final userProfile = context.read<AuthProvider>().currentUserProfile;
    final familyId = context.read<AuthProvider>().userFamilyId;

    if (userProfile != null && familyId != null) {
      await Future.wait([
        taskSummaryProvider.fetchTaskSummary(
          familyId: familyId,
          userId: userProfile.member.id,
        ),
        taskProvider.fetchQuickTasks(
          familyId: familyId,
          userId: userProfile.member.id,
        ),
      ]);
    }
  }

  Widget _buildUserProfileSection(UserProfile userProfile) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          child: Text(
            userProfile.member.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(fontSize: 30),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userProfile.member.name,
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
                    'Level ${UserProfile.calculateLevelFromPoints(userProfile.points)}',
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.attach_money),
                  Text('${userProfile.points} Points'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('HomeScreen: Building screen');
    final authProvider = context.watch<AuthProvider>();
    final currentUserProfile = authProvider.currentUserProfile;

    if (currentUserProfile == null) {
      _logger.w('HomeScreen: User profile is null');
      return Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserProfileSection(currentUserProfile),
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
      ),
    );
  }
}
