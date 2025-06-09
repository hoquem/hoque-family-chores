// lib/presentation/screens/family_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/services/data_service_interface.dart';

class FamilyListScreen extends StatefulWidget {
  const FamilyListScreen({super.key});

  @override
  State<FamilyListScreen> createState() => _FamilyListScreenState();
}

class _FamilyListScreenState extends State<FamilyListScreen> {
  late Future<List<FamilyMember>> _familyMembersFuture;

  @override
  void initState() {
    super.initState();
    // Fetch the family members when the screen loads
    final dataService = Provider.of<DataServiceInterface>(context, listen: false);
    // Assuming you have a way to get the current familyId, e.g., from an AuthProvider
    // For now, we'll use a placeholder.
    const String currentFamilyId = 'family_hoque_1'; 
    
    // Convert the List<Map> from the service into a List<FamilyMember>
    _familyMembersFuture = dataService
        .getFamilyMembers(familyId: currentFamilyId)
        .then((memberMaps) => memberMaps.map((map) {
              // We need a fromMap constructor on FamilyMember for this to be clean
              // For now, let's create it manually based on the model.
              return FamilyMember(
                id: map['id'],
                name: map['displayName'] ?? 'Unnamed Member',
                email: map['email'],
                avatarUrl: map['photoUrl'],
                familyId: map['familyId'],
              );
            }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
      ),
      body: FutureBuilder<List<FamilyMember>>(
        future: _familyMembersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No family members found.'));
          }

          final familyMembers = snapshot.data!;

          return ListView.builder(
            itemCount: familyMembers.length,
            itemBuilder: (context, index) {
              final member = familyMembers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                    child: member.avatarUrl == null ? Text(member.name[0]) : null,
                  ),
                  // THIS IS THE FIX: We can now use member.name directly without any null checks,
                  // because our model guarantees it will always have a value.
                  title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(member.email ?? 'No email'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}