// lib/presentation/screens/family_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/services/interfaces/family_service_interface.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';

class FamilyListScreen extends StatefulWidget {
  const FamilyListScreen({super.key});

  @override
  State<FamilyListScreen> createState() => _FamilyListScreenState();
}

class _FamilyListScreenState extends State<FamilyListScreen> {
  final _logger = AppLogger();
  Future<List<FamilyMember>>? _familyMembersFuture;

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final familyService = Provider.of<FamilyServiceInterface>(
      context,
      listen: false,
    );

    if (authProvider.userFamilyId == null) {
      _logger.w("No family ID available in AuthProvider");
      return;
    }

    setState(() {
      _familyMembersFuture = familyService.getFamilyMembers(
        familyId: authProvider.userFamilyId!,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_familyMembersFuture == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Family Members')),
      body: RefreshIndicator(
        onRefresh: _loadFamilyMembers,
        child: FutureBuilder<List<FamilyMember>>(
          future: _familyMembersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              _logger.e(
                "Error loading family members: ${snapshot.error}",
                error: snapshot.error,
                stackTrace: snapshot.stackTrace,
              );
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No family members found.'));
            } else {
              final familyMembers = snapshot.data!;
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
                                backgroundColor:
                                    Theme.of(context).primaryColorLight,
                                backgroundImage:
                                    member.photoUrl != null &&
                                            member.photoUrl!.isNotEmpty
                                        ? NetworkImage(member.photoUrl!)
                                        : null,
                                child:
                                    member.photoUrl == null ||
                                            member.photoUrl!.isEmpty
                                        ? Text(
                                          member.name
                                              .substring(0, 1)
                                              .toUpperCase(),
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
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withAlpha(26),
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
                                '${member.points}',
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
            }
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
