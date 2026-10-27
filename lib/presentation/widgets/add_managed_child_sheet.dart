import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics.dart';
import '../../di/riverpod_container.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../providers/riverpod/auth_notifier.dart';
import '../providers/riverpod/family_notifier.dart';

/// Asks for a name and adds a child with no phone of their own to
/// [familyId]. [source] says where it was opened from, for analytics
/// ('onboarding', 'home_card' or 'family_tab').
///
/// :returns: the new member's id, or null if the sheet was dismissed.
Future<UserId?> showAddManagedChildSheet(
  BuildContext context,
  WidgetRef ref, {
  required FamilyId familyId,
  required String source,
}) async {
  final childId = await showModalBottomSheet<UserId>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddManagedChildSheet(familyId: familyId, source: source),
  );
  if (childId != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added. Hand them your phone from the Family tab.'),
      ),
    );
  }
  return childId;
}

class _AddManagedChildSheet extends ConsumerStatefulWidget {
  const _AddManagedChildSheet({required this.familyId, required this.source});

  final FamilyId familyId;
  final String source;

  @override
  ConsumerState<_AddManagedChildSheet> createState() =>
      _AddManagedChildSheetState();
}

class _AddManagedChildSheetState extends ConsumerState<_AddManagedChildSheet> {
  final _name = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(addManagedChildUseCaseProvider)(
      familyId: widget.familyId,
      name: _name.text,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = failure.message;
      }),
      (childId) {
        final userId = ref.read(authNotifierProvider).user?.id.value;
        if (userId != null) {
          ref
              .read(analyticsProvider)
              .log(
                AnalyticsEventName.managedChildAdded,
                userId: userId,
                familyId: widget.familyId.value,
                params: {'source': widget.source},
              );
        }
        ref.invalidate(familyMembersNotifierProvider(widget.familyId));
        Navigator.of(context).pop(childId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add a child without a phone',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            "They'll use Chores Star on your phone. Open them from the Family "
            'tab and tap "Hand the phone to…". You can move them to their own '
            'phone later, stars and all.',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('managed_child_name_field'),
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Their name',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onSubmitted: (_) => _add(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('managed_child_add_button'),
            onPressed: _saving ? null : _add,
            child:
                _saving
                    ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Add'),
          ),
        ],
      ),
    );
  }
}
