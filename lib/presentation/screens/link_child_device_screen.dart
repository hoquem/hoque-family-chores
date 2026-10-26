
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

/// For a child who has been using a parent's phone: enter the link code the
/// parent made ("Move … to their own phone") and carry on as the same member.
class LinkChildDeviceScreen extends ConsumerStatefulWidget {
  const LinkChildDeviceScreen({super.key});

  @override
  ConsumerState<LinkChildDeviceScreen> createState() => _LinkChildDeviceScreenState();
}

class _LinkChildDeviceScreenState extends ConsumerState<LinkChildDeviceScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    await ref.read(authNotifierProvider.notifier).linkChildDevice(code: _code.text);
    if (!mounted) return;
    if (ref.read(authNotifierProvider).status == AuthStatus.authenticated) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Use a link code')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ask a parent to open you in the Family tab and tap '
              '"Move … to their own phone". Type the code they see.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('link_code_field'),
              controller: _code,
              decoration: const InputDecoration(
                labelText: 'Link code',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
            ),
            if (authState.errorMessage?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 16),
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
                    key: const Key('link_code_submit'),
                    onPressed: _link,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: const Text('Link this phone'),
                  ),
          ],
        ),
      ),
    );
  }
}
