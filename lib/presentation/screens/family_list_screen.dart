// lib/presentation/screens/family_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_notifier.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class FamilyListScreen extends ConsumerWidget {
  const FamilyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;
    final _logger = AppLogger();

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Watch family members
    final familyMembersAsync = ref.watch(familyMembersNotifierProvider(currentUser.familyId));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(familyMembersNotifierProvider(currentUser.familyId));
        },
        child: familyMembersAsync.when(
          data: (familyMembers) {
            if (familyMembers.isEmpty) {
              return const Center(child: Text('No family members found.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: familyMembers.length,
              itemBuilder: (context, index) {
                final member = familyMembers[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                              backgroundImage: member.photoUrl != null && member.photoUrl!.isNotEmpty
                                  ? NetworkImage(member.photoUrl!)
                                  : null,
                              child: member.photoUrl == null || member.photoUrl!.isEmpty
                                  ? Text(
                                      member.name.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withAlpha(26),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      member.role.name,
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              context,
                              Icons.star,
                              'Points',
                              '${member.points.value}',
                              Colors.amber,
                            ),
                            _buildStatItem(
                              context,
                              Icons.calendar_today,
                              'Joined',
                              '${member.joinedAt.day}/${member.joinedAt.month}/${member.joinedAt.year}',
                              Colors.blue,
                            ),
                            _buildStatItem(
                              context,
                              Icons.update,
                              'Updated',
                              '${member.updatedAt.day}/${member.updatedAt.month}/${member.updatedAt.year}',
                              Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            _logger.e(
              "Error loading family members: $error",
              error: error,
              stackTrace: stack,
            );
            return Center(child: Text('Error: $error'));
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}
