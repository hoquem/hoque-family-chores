import 'package:flutter/material.dart';

/// The only way to turn a recurring series off (rule editing is future work).
/// A confirm dialog guards the delete because it is irreversible — the rule
/// doc is gone, though existing occurrences stay as ordinary tasks.
class StopRepeatingButton extends StatelessWidget {
  final Future<void> Function() onStop;

  const StopRepeatingButton({super.key, required this.onStop});

  Future<void> _confirm(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop this recurring chore?'),
        content: const Text(
            'New occurrences will stop. Existing ones stay on the list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await onStop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Recurring series stopped')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not stop repeating — try again')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirm(context),
      icon: const Icon(Icons.repeat),
      label: const Text('Stop repeating'),
    );
  }
}
