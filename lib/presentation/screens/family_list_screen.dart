// lib/presentation/screens/family_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/models/family_member.dart'; // Ensure FamilyMember is imported
import 'package:hoque_family_chores/services/data_service_interface.dart'; // Use aliased if necessary
import 'package:hoque_family_chores/services/logging_service.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';

class FamilyListScreen extends StatefulWidget {
  const FamilyListScreen({super.key});

  @override
  State<FamilyListScreen> createState() => _FamilyListScreenState();
}

class _FamilyListScreenState extends State<FamilyListScreen> {
  Future<List<FamilyMember>>? _familyMembersFuture;

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dataService = Provider.of<DataServiceInterface>(
      context,
      listen: false,
    );

    if (authProvider.userFamilyId == null) {
      logger.w("No family ID available in AuthProvider");
      return;
    }

    setState(() {
      _familyMembersFuture = dataService.getFamilyMembers(
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
      body: FutureBuilder<List<FamilyMember>>(
        future: _familyMembersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            logger.e(
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
              itemCount: familyMembers.length,
              itemBuilder: (context, index) {
                final member = familyMembers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: ListTile(
                    // Access properties directly using dot notation
                    leading: CircleAvatar(
                      backgroundImage:
                          member.avatarUrl != null &&
                                  member.avatarUrl!.isNotEmpty
                              ? NetworkImage(member.avatarUrl!)
                              : null,
                      child:
                          member.avatarUrl == null || member.avatarUrl!.isEmpty
                              ? Text(member.name.substring(0, 1).toUpperCase())
                              : null,
                    ),
                    title: Text(member.name), // <--- Use .name
                    subtitle: Text(
                      member.role?.name ?? 'Member',
                    ), // <--- Use .role?.name
                    trailing: Text('ID: ${member.id}'), // <--- Use .id
                    // You can add more details or actions here
                    onTap: () {
                      logger.d("Tapped on family member: ${member.name}");
                      // Navigate to member profile or show details
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
