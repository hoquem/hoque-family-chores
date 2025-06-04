// lib/presentation/screens/family_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/family_member.dart'; // Ensure this path is correct
import '../providers/family_list_provider.dart';
import '../../services/family_service_interface.dart'; // For potential direct injection if not using parent provider
import '../../services/mock_family_service.dart'; // To provide MockFamilyService

class FamilyListScreen extends StatelessWidget {
  const FamilyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Option 1: If FamilyListProvider is provided higher up in the widget tree (e.g., in main.dart or a route generator)
    // final familyProvider = Provider.of<FamilyListProvider>(context);
    // OR
    // final familyProvider = context.watch<FamilyListProvider>();
    // if (familyProvider.state == FamilyListState.initial) {
    //   familyProvider.fetchFamilyMembers(); // Fetch data if initial state
    // }

    // Option 2: Provide the FamilyListProvider specifically for this screen and its descendants.
    // This is good for features that are relatively self-contained.
    return ChangeNotifierProvider(
      // Here we inject the MockFamilyService into our FamilyListProvider
      // In a real app, you might get the FamilyServiceInterface from another provider
      // or a service locator like GetIt.
      create: (context) => FamilyListProvider(MockFamilyService())..fetchFamilyMembers(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Family Members'),
        ),
        body: Consumer<FamilyListProvider>(
          builder: (context, provider, child) {
            switch (provider.state) {
              case FamilyListState.loading:
                return const Center(child: CircularProgressIndicator());
              case FamilyListState.error:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${provider.errorMessage}'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => provider.fetchFamilyMembers(),
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                );
              case FamilyListState.loaded:
                if (provider.members.isEmpty) {
                  return const Center(child: Text('No family members found.'));
                }
                return ListView.builder(
                  itemCount: provider.members.length,
                  itemBuilder: (context, index) {
                    final member = provider.members[index];
                    return ListTile(
                      leading: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(member.avatarUrl!),
                              onBackgroundImageError: (exception, stackTrace) {
                                // Handle broken image links gracefully
                                // You could log the error or use a default icon
                              },
                              child: member.avatarUrl!.isEmpty ? const Icon(Icons.person) : null,
                            )
                          : CircleAvatar(
                              child: Text(member.name.isNotEmpty ? member.name[0] : 'N'), // Display initial
                            ),
                      title: Text(member.name),
                      subtitle: Text(member.role ?? 'Family Member'),
                      // You could add an onTap here for more actions
                    );
                  },
                );
              case FamilyListState.initial:
                // This case might not be hit if fetch is called on create,
                // but good to handle. Could show a button to load.
                return Center(
                  child: ElevatedButton(
                    onPressed: () => provider.fetchFamilyMembers(),
                    child: const Text('Load Members'),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}