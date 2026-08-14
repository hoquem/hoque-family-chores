import 'package:flutter/material.dart';
import 'package:hoque_family_chores/domain/services/recurrence.dart';

/// The "Repeat" row on the add-task screen — Never / Daily / Weekly / Monthly.
/// Shown to parents only ([visible]); children never see it.
class RepeatSelector extends StatelessWidget {
  final RepeatPreset value;
  final ValueChanged<RepeatPreset> onChanged;
  final bool visible;

  const RepeatSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.visible,
  });

  static const Map<RepeatPreset, String> _labels = {
    RepeatPreset.never: 'Never',
    RepeatPreset.daily: 'Daily',
    RepeatPreset.weekly: 'Weekly',
    RepeatPreset.monthly: 'Monthly',
  };

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    // Match the field style of the date-picker row on this screen.
    return InputDecorator(
      isEmpty: false,
      decoration: const InputDecoration(
        labelText: 'Repeat',
        border: OutlineInputBorder(),
      ),
      child: DropdownButton<RepeatPreset>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: [
          for (final preset in RepeatPreset.values)
            DropdownMenuItem(
              value: preset,
              child: Text(_labels[preset]!),
            ),
        ],
        onChanged: (p) {
          if (p != null) onChanged(p);
        },
      ),
    );
  }
}
