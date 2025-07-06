import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_notifier.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen> {
  final _familyNameController = TextEditingController();
  final _logger = AppLogger();

  @override
  void dispose() {
    _familyNameController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    if (_familyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Family name cannot be empty.")),
      );
      return;
    }

    try {
      final authState = ref.read(authNotifierProvider);
      final currentUser = authState.user;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in. Please re-authenticate.")),
        );
        return;
      }

      // Create family using the family notifier
      await ref.read(familyNotifierProvider(currentUser.familyId).notifier).createFamily(
        name: _familyNameController.text.trim(),
        description: 'Family created by ${currentUser.name}',
        creatorId: currentUser.id,
      );

      _logger.i("Family '${_familyNameController.text.trim()}' created successfully.");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Family created successfully!")),
        );
      }
    } catch (e, s) {
      _logger.e("Error creating family: $e", error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create family: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Setup Your Family')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Welcome! Let\'s set up your family.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _familyNameController,
                decoration: const InputDecoration(
                  labelText: 'Family Name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),
              if (authState.errorMessage != null)
                Text(
                  authState.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _createFamily,
                    child: const Text('Create Family'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50), // Make button full width
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
