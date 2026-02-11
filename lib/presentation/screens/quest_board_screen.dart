import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/widgets/quest_card.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:intl/intl.dart';

part 'quest_board_screen.g.dart';

/// Provider for connectivity status
@riverpod
Stream<bool> connectivityStatus(Ref ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    // results is List<ConnectivityResult>
    return results.any((result) => result != ConnectivityResult.none);
  });
}

class QuestBoardScreen extends ConsumerStatefulWidget {
  const QuestBoardScreen({super.key});

  @override
  ConsumerState<QuestBoardScreen> createState() => _QuestBoardScreenState();
}

class _QuestBoardScreenState extends ConsumerState<QuestBoardScreen> {
  @override
  void initState() {
    super.initState();
    // Quests are automatically streamed by the provider
  }

  Future<void> _refreshQuests() async {
    // Force a rebuild of the stream provider
    final authState = ref.read(authNotifierProvider);
    final currentUser = authState.user;
    if (currentUser != null) {
      logger.d('[QuestBoardScreen] Refreshing quests for family: ${currentUser.familyId}');
      ref.invalidate(taskListStreamProvider(currentUser.familyId));
    }
  }

  Future<void> _completeQuest(Task quest) async {
    final authState = ref.read(authNotifierProvider);
    final currentUser = authState.user;
    
    if (currentUser == null) return;

    // Check connectivity before attempting to complete
    final connectivityState = ref.read(connectivityStatusProvider);
    final isOnline = connectivityState.value ?? true;
    
    if (!isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot complete quest while offline. Please check your connection.'),
            backgroundColor: Color(0xFFF44336),
          ),
        );
      }
      return;
    }

    try {
      // Use the domain layer's completeTask use case (ensures business logic runs)
      await ref
          .read(taskListNotifierProvider(currentUser.familyId).notifier)
          .completeTask(quest.id.value, currentUser.id, currentUser.familyId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quest completed! +${quest.points.value} ⭐'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      logger.e('[QuestBoardScreen] Error completing quest: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to complete quest. Please try again.'),
            backgroundColor: const Color(0xFFF44336),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _completeQuest(quest),
            ),
          ),
        );
      }
    }
  }

  List<Task> _getTodayQuests(List<Task> allTasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return allTasks.where((task) {
      final taskDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      return taskDate.isAtSameMomentAs(today) || task.isOverdue;
    }).toList();
  }

  List<Task> _sortQuests(List<Task> quests) {
    final incomplete = quests.where((q) => !q.isCompleted).toList();
    final completed = quests.where((q) => q.isCompleted).toList();

    // Sort incomplete by stars (DESC), then by overdue status
    incomplete.sort((a, b) {
      if (a.isOverdue != b.isOverdue) {
        return a.isOverdue ? -1 : 1; // Overdue first
      }
      return b.points.value.compareTo(a.points.value); // Higher stars first
    });

    // Sort completed by completion time (most recent first)
    completed.sort((a, b) {
      if (a.completedAt == null || b.completedAt == null) return 0;
      return b.completedAt!.compareTo(a.completedAt!);
    });

    return [...incomplete, ...completed];
  }

  int _calculateAvailableStars(List<Task> todayQuests) {
    return todayQuests
        .where((q) => !q.isCompleted)
        .fold(0, (sum, q) => sum + q.points.value);
  }

  Widget _buildDateHeader(List<Task> todayQuests) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMM d').format(now);
    final availableStars = _calculateAvailableStars(todayQuests);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                '$availableStars ${availableStars == 1 ? 'star' : 'stars'} available today',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFFFB300),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🗺️',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            const Text(
              'No quests today!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enjoy your free time or create a new quest to earn stars ⭐',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllCompleteState(List<Task> todayQuests) {
    final totalStars = todayQuests.fold(0, (sum, q) => sum + q.points.value);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF6750A4).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                '🎉 Congratulations! 🎉',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'All quests completed!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You earned ', style: TextStyle(fontSize: 16)),
                  const Text('⭐', style: TextStyle(fontSize: 20)),
                  Text(
                    ' $totalStars ${totalStars == 1 ? 'star' : 'stars'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFB300),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            height: 96,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFF44336),
            ),
            const SizedBox(height: 16),
            const Text(
              'Couldn\'t load quests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your internet connection and try again',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshQuests,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange.shade700,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 16, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Offline — showing last synced data',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isParent = currentUser.role == UserRole.parent;
    
    // Use role-based filtered stream provider for real-time updates
    final taskListState = ref.watch(
      filteredQuestsStreamProvider(
        currentUser.familyId,
        currentUser.id,
        isParent,
      ),
    );

    // Watch connectivity status
    final connectivityState = ref.watch(connectivityStatusProvider);
    final isOnline = connectivityState.value ?? true;

    return Column(
      children: [
        // Offline banner
        if (!isOnline) _buildOfflineBanner(),
        // Main content
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshQuests,
            child: taskListState.when(
        data: (tasks) {
          final todayQuests = _getTodayQuests(tasks);
          final sortedQuests = _sortQuests(todayQuests);
          final allCompleted = todayQuests.isNotEmpty &&
              todayQuests.every((q) => q.isCompleted);

          if (todayQuests.isEmpty) {
            return _buildEmptyState();
          }

          return CustomScrollView(
            slivers: [
              // Date header
              SliverToBoxAdapter(
                child: _buildDateHeader(todayQuests),
              ),
              // All complete celebration banner
              if (allCompleted)
                SliverToBoxAdapter(
                  child: _buildAllCompleteState(todayQuests),
                ),
              // Quest cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final quest = sortedQuests[index];
                      final isCurrentUserQuest =
                          quest.assignedToId == currentUser.id;
                      final isParent = currentUser.role == UserRole.parent;

                      // Get assignee info (simplified - would normally fetch from family members)
                      User? assignee;
                      if (quest.assignedToId != null) {
                        // In a real implementation, fetch from family members list
                        assignee = currentUser;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: QuestCard(
                          quest: quest,
                          assignee: assignee,
                          isCurrentUserQuest: isCurrentUserQuest,
                          isParent: isParent,
                          onTap: () {
                            // TODO: Navigate to quest detail screen
                            logger.d('[QuestBoardScreen] Quest tapped: ${quest.id}');
                          },
                          onComplete: () => _completeQuest(quest),
                        ),
                      );
                    },
                    childCount: sortedQuests.length,
                  ),
                ),
              ),
              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          );
        },
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),
        ),
      ],
    );
  }
}
