import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/value_objects/family_id.dart';
import '../providers/riverpod/pending_approvals_notifier.dart';
import '../theme/app_tokens.dart';
import '../theme/motion.dart';

/// Badge showing count of pending approvals
class PendingApprovalBadge extends ConsumerWidget {
  final FamilyId familyId;
  final bool animate;

  const PendingApprovalBadge({
    super.key,
    required this.familyId,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(pendingApprovalsNotifierProvider(familyId));

    return tasksAsync.when(
      data: (tasks) {
        final count = tasks.length;
        if (count == 0) {
          return const SizedBox.shrink();
        }

        return animate && !context.prefersReducedMotion
            ? _AttentionBadge(count: count)
            : _StaticBadge(count: count);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StaticBadge extends StatelessWidget {
  final int count;

  const _StaticBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final shown = count > 9 ? '9+' : count.toString();
    return Semantics(
      label: '$count ${count == 1 ? 'task' : 'tasks'} waiting for approval',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: context.tokens.amberWarn,
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        child: Text(
          shown,
          style: TextStyle(
            color: context.tokens.ink,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// One-shot attention draw: pulses once when the count *increases*, then rests.
class _AttentionBadge extends StatefulWidget {
  final int count;

  const _AttentionBadge({required this.count});

  @override
  State<_AttentionBadge> createState() => _AttentionBadgeState();
}

class _AttentionBadgeState extends State<_AttentionBadge>
    with SingleTickerProviderStateMixin {
  int? _previousCount;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(_AttentionBadge old) {
    super.didUpdateWidget(old);
    _previousCount ??= old.count;
    if (widget.count > _previousCount!) {
      _controller.forward(from: 0.0);
    }
    _previousCount = widget.count;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Transform.scale(
        scale: _animation.value,
        child: _StaticBadge(count: widget.count),
      ),
    );
  }
}
