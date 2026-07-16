import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

/// Lets a child join their family with just a first name and the family's
/// invite code — no email or password. An anonymous account is created
/// behind the scenes; on success authStateChanges routing takes over.
class ChildJoinScreen extends ConsumerStatefulWidget {
  const ChildJoinScreen({super.key});

  @override
  ConsumerState<ChildJoinScreen> createState() => _ChildJoinScreenState();
}

class _ChildJoinScreenState extends ConsumerState<ChildJoinScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    await ref.read(authNotifierProvider.notifier).joinFamilyAsChild(
          name: _nameController.text,
          inviteCode: _codeController.text,
        );
    if (!mounted) return;
    // On success authStateChanges swaps the whole tree to MainScreen; if we
    // are still here with this screen mounted, pop back off the login stack.
    if (ref.read(authNotifierProvider).status == AuthStatus.authenticated) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Join your family')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.family_restroom, size: 64, color: context.tokens.inkMuted),
            const SizedBox(height: 16),
            const Text(
              'Ask a parent for your family code, then type it in with '
              'your name!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('child_name_field'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('child_code_field'),
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Family code',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
            ),
            if (authState.errorMessage != null &&
                authState.errorMessage!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  authState.errorMessage!,
                  style: TextStyle(color: context.tokens.brick),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            authState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _join,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Join'),
                  ),
          ],
        ),
      ),
    );
  }
}
