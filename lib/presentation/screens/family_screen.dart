import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    logger.d('FamilyScreen: Building screen');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              currentUser != null
                  ? 'Family: ${currentUser.familyId.value}'
                  : 'No family found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Family management coming soon!'),
          ],
        ),
      ),
    );
  }
}
