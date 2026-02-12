import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/streak.dart';
import '../../domain/value_objects/user_id.dart';
import '../providers/riverpod/streak_notifier.dart';

/// Fire counter widget displaying streak count
/// 
/// Supports two layouts:
/// - Compact: Small emoji + number for headers/cards
/// - Expanded: Large emoji + text for profile pages
class FireCounterWidget extends ConsumerWidget {
  final UserId userId;
  final bool expanded;
  final VoidCallback? onTap;

  const FireCounterWidget({
    super.key,
    required this.userId,
    this.expanded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakNotifierProvider(userId));

    return streakAsync.when(
      data: (streak) => _buildCounter(context, streak),
      loading: () => _buildLoading(context),
      error: (error, stack) => _buildError(context),
    );
  }

  Widget _buildCounter(BuildContext context, Streak? streak) {
    final streakCount = streak?.currentStreak ?? 0;
    final state = streak?.state ?? StreakState.none;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(expanded ? 16.0 : 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: expanded
            ? _buildExpandedLayout(context, streakCount, state)
            : _buildCompactLayout(context, streakCount, state),
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    int streakCount,
    StreakState state,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFireEmoji(state, size: 24),
        const SizedBox(width: 4),
        Text(
          '$streakCount',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getStreakColor(state),
              ),
        ),
      ],
    );
  }

  Widget _buildExpandedLayout(
    BuildContext context,
    int streakCount,
    StreakState state,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFireEmoji(state, size: 48),
        const SizedBox(height: 8),
        Text(
          '$streakCount days',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getStreakColor(state),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Current Streak',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildFireEmoji(StreakState state, {required double size}) {
    final emoji = state == StreakState.none ? '🔥' : '🔥';
    final color = _getStreakColor(state);

    Widget fireWidget = Text(
      emoji,
      style: TextStyle(
        fontSize: size,
        color: state == StreakState.none ? Colors.grey : null,
      ),
    );

    // Add animations based on state
    if (state == StreakState.hot) {
      fireWidget = _PulsingWidget(child: fireWidget);
    } else if (state == StreakState.onFire) {
      fireWidget = _GlowingWidget(child: fireWidget, color: color);
    } else if (state == StreakState.legendary) {
      fireWidget = _ShimmeringWidget(child: fireWidget);
    }

    return fireWidget;
  }

  Widget _buildLoading(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(expanded ? 16.0 : 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(expanded ? 16.0 : 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Icon(
        Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
        size: expanded ? 48 : 24,
      ),
    );
  }

  Color _getStreakColor(StreakState state) {
    switch (state) {
      case StreakState.none:
        return Colors.grey;
      case StreakState.active:
        return const Color(0xFFFF5722);
      case StreakState.hot:
        return const Color(0xFFFF9800);
      case StreakState.onFire:
      case StreakState.legendary:
        return const Color(0xFFFFB300);
    }
  }
}

/// Pulsing animation widget for "hot" streaks
class _PulsingWidget extends StatefulWidget {
  final Widget child;

  const _PulsingWidget({required this.child});

  @override
  State<_PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<_PulsingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
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
      child: widget.child,
    );
  }
}

/// Glowing animation widget for "on fire" streaks
class _GlowingWidget extends StatelessWidget {
  final Widget child;
  final Color color;

  const _GlowingWidget({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Shimmering animation widget for "legendary" streaks
class _ShimmeringWidget extends StatefulWidget {
  final Widget child;

  const _ShimmeringWidget({required this.child});

  @override
  State<_ShimmeringWidget> createState() => _ShimmeringWidgetState();
}

class _ShimmeringWidgetState extends State<_ShimmeringWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFFFF0000),
                Color(0xFFFFFF00),
                Color(0xFF00FF00),
                Color(0xFF00FFFF),
                Color(0xFF0000FF),
                Color(0xFFFF00FF),
              ],
              stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: GradientRotation(_controller.value * 2 * 3.14159),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
