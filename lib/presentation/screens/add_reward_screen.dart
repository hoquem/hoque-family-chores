import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics.dart';
import '../../di/riverpod_container.dart';
import '../../domain/entities/reward.dart';
import '../../domain/value_objects/points.dart';
import '../providers/riverpod/auth_notifier.dart';
import '../providers/riverpod/rewards_notifier.dart';
import '../theme/app_tokens.dart';

/// Propose something worth working for.
///
/// Open to anyone in the family, deliberately. A child suggesting "bike ride
/// with Dad" is the feature working, and the list is visible to everyone, which
/// is the only control it needs.
class AddRewardScreen extends ConsumerStatefulWidget {
  /// When non-null, the screen edits this reward instead of creating one.
  final Reward? existingReward;

  const AddRewardScreen({super.key, this.existingReward});

  @override
  ConsumerState<AddRewardScreen> createState() => _AddRewardScreenState();
}

class _AddRewardScreenState extends ConsumerState<AddRewardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _cost = TextEditingController(text: '100');
  RewardTimeframe _timeframe = RewardTimeframe.openEnded;
  bool _saving = false;

  bool get _isEditing => widget.existingReward != null;

  @override
  void initState() {
    super.initState();
    final r = widget.existingReward;
    if (r != null) {
      _title.text = r.title;
      _cost.text = r.cost.value.toString();
      _timeframe = r.timeframe;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Reward' : 'Add a Reward')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('reward_title_field'),
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Reward',
                hintText: 'Walk in the park',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Give it a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('reward_cost_field'),
              controller: _cost,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stars',
                border: OutlineInputBorder(),
                suffixText: '⭐',
              ),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'How many stars?';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'When',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.inkSoft,
              ),
            ),
            const SizedBox(height: 8),
            // Three choices, no date picker. The deadline is not the
            // interesting part of a reward — the promise and the refund are.
            Row(
              children: [
                for (final option in RewardTimeframe.values) ...[
                  Expanded(
                    child: _TimeframeChip(
                      timeframe: option,
                      selected: option == _timeframe,
                      onTap: () => setState(() => _timeframe = option),
                    ),
                  ),
                  if (option != RewardTimeframe.values.last)
                    const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _timeframe == RewardTimeframe.openEnded
                  ? 'No deadline. Whoever claims it can still ask for their '
                      'stars back if it never happens.'
                  : 'If it has not happened by then, the stars go back '
                      'automatically.',
              style: TextStyle(fontSize: 14, color: t.inkSoft),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Add Reward'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(rewardRepositoryProvider);
      if (_isEditing) {
        await repo.updateReward(
          widget.existingReward!.copyWith(
            title: _title.text.trim(),
            cost: Points(int.parse(_cost.text.trim())),
            timeframe: _timeframe,
          ),
        );
      } else {
        await repo.createReward(
          Reward(
            id: '',
            familyId: user.familyId,
            title: _title.text.trim(),
            cost: Points(int.parse(_cost.text.trim())),
            timeframe: _timeframe,
            createdBy: user.id,
            createdAt: DateTime.now(),
          ),
        );
        ref.read(analyticsProvider).log(
              AnalyticsEventName.rewardCreated,
              userId: user.id.value,
              familyId: user.familyId.value,
              params: {'cost': int.tryParse(_cost.text.trim()) ?? 0},
            );
      }
      ref.invalidate(familyRewardsProvider(user.familyId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save that: $e'),
            backgroundColor: context.tokens.brickDeep,
          ),
        );
      }
    }
  }
}

class _TimeframeChip extends StatelessWidget {
  const _TimeframeChip({
    required this.timeframe,
    required this.selected,
    required this.onTap,
  });

  final RewardTimeframe timeframe;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? t.marigold : t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? t.marigold : t.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            timeframe.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              // Selection is not carried by colour alone.
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? t.ink : t.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
