// lib/presentation/screens/family_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/family_list_provider.dart';
import 'package:hoque_family_chores/services/firebase_family_service.dart';

class FamilyListScreen extends StatelessWidget {
  const FamilyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FamilyListProvider(FirebaseFamilyService())..fetchFamilyMembers(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Family Members (Firebase)'),
          // You could add a refresh button here if desired:
          // actions: [
          //   Consumer<FamilyListProvider>( // To access provider for refresh
          //     builder: (context, provider, child) {
          //       // Avoid showing refresh button while already loading
          //       if (provider.state == FamilyListState.loading) {
          //         return const SizedBox.shrink(); // Or a disabled button
          //       }
          //       return IconButton(
          //         icon: const Icon(Icons.refresh),
          //         onPressed: () => provider.fetchFamilyMembers(),
          //       );
          //     },
          //   ),
          // ],
        ),
        body: Consumer<FamilyListProvider>(
          builder: (context, provider, child) {
            switch (provider.state) {
              case FamilyListState.loading:
                return const Center(child: CircularProgressIndicator());
              case FamilyListState.error:
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${provider.errorMessage}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => provider.fetchFamilyMembers(),
                          child: const Text('Retry'),
                        )
                      ],
                    ),
                  ),
                );
              case FamilyListState.loaded:
                if (provider.members.isEmpty) {
                  return const Center(
                    child: Text('No family members found in Firebase.'),
                  );
                }
                return ListView.builder(
                  itemCount: provider.members.length,
                  itemBuilder: (context, index) {
                    final member = provider.members[index];
                    Widget leadingAvatar;

                    if (member.avatarUrl != null && member.avatarUrl!.isNotEmpty) {
                      leadingAvatar = SizedBox(
                        width: 40, // Standard CircleAvatar width
                        height: 40, // Standard CircleAvatar height
                        child: ClipOval(
                          child: Image.network(
                            member.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                              // Error occurred loading image for member
                              return CircleAvatar( // Fallback CircleAvatar with icon
                                backgroundColor: Colors.grey[300],
                                child: Icon(Icons.person_outline, color: Colors.grey[700]),
                              );
                            },
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child; // Image is loaded
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    } else {
                      // Placeholder if avatarUrl is null or empty
                      leadingAvatar = CircleAvatar(
                        backgroundColor: Colors.blueGrey[100],
                        child: Text(
                          member.name.isNotEmpty ? member.name[0].toUpperCase() : 'N',
                          style: TextStyle(color: Colors.blueGrey[700]),
                        ),
                      );
                    }

                    return ListTile(
                      leading: leadingAvatar,
                      title: Text(member.name),
                      subtitle: Text(member.role ?? 'N/A'), // Display 'N/A' if role is null
                      // Example: Add an onTap for future functionality
                      // onTap: () {
                      //   print('Tapped on ${member.name}');
                      //   // Navigate to a detail screen, show a dialog, etc.
                      // },
                    );
                  },
                );
              case FamilyListState.initial:
                // This case might not be hit if fetch is called immediately on create,
                // but it's good practice to handle all enum states.
                // Could show a button to initiate loading if fetch wasn't called automatically.
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