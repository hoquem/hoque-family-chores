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

        // This badge pulses forever, so it is the most intrusive motion in the
        // app for anyone who has asked their phone to stop moving things. The
        // count is the information; the pulse is only emphasis.
        return animate && !context.prefersReducedMotion
            ? _PulsatingBadge(count: count)
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
      // "3" on its own tells a screen-reader user nothing. The digits are a
      // glyph; the meaning has to be said out loud.
      label: '$count ${count == 1 ? 'task' : 'tasks'} waiting for approval',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: context.tokens.amberWarn,
          shape: BoxShape.circle,
        ),
        // 28, not 24: the count is 14px now (the floor), and the circle has to
        // hold "9+" without clipping it.
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

class _PulsatingBadge extends StatefulWidget {
  final int count;

  const _PulsatingBadge({required this.count});

  @override
  State<_PulsatingBadge> createState() => _PulsatingBadgeState();
}

class _PulsatingBadgeState extends State<_PulsatingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: _StaticBadge(count: widget.count),
    );
  }
}
