// lib/presentation/screens/user_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = currentUser.name;
    final email = currentUser.email.value;

    return Scaffold(
      appBar: AppBar(
        // --- CHANGED --- Title updated to reflect its new purpose.
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User profile header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColorLight,
                  child: currentUser.photoUrl != null && currentUser.photoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.network(
                            currentUser.photoUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),

          // Menu Options
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to an edit profile screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Profile coming soon!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to notification settings
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification Settings coming soon!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to security settings
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security Settings coming soon!')),
              );
            },
          ),
          
          const Divider(),
          const SizedBox(height: 16),

          // Logout Button Section
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) {
                   Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}