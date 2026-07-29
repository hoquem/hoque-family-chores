import 'dart:math';
import 'package:flutter/material.dart';

/// The single owner-approved overshoot (DESIGN.md carve-out): one-shot,
/// bounded, never perpetual. Lives only in lib/presentation/motion/.
const Curve kCelebrationOvershoot = Curves.easeOutBack;

class StarBurstPainter extends CustomPainter {
  StarBurstPainter({required this.progress, required this.colors});

  /// 0 → 1 over the burst envelope.
  final double progress;
  final List<Color> colors;

  static const int _count = 12;
  static final List<double> _jitter = List.unmodifiable(
    List.generate(_count, (i) => Random(7 * i + 3).nextDouble()),
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.38;
    final travel = kCelebrationOvershoot.transform(progress.clamp(0.0, 1.0));
    final fade = (1.0 - progress).clamp(0.0, 1.0);

    for (var i = 0; i < _count; i++) {
      final angle = (2 * pi * i / _count) + _jitter[i] * 0.4;
      final distance = radius * travel * (0.7 + 0.3 * _jitter[i]);
      // Gravity: particles sag as the burst ends.
      final gravity = 18.0 * progress * progress;
      final pos = center +
          Offset(cos(angle) * distance, sin(angle) * distance + gravity);
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: fade);
      final side = 7.0 * (0.6 + 0.4 * _jitter[i]) * (1.0 - 0.3 * progress);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: pos, width: side, height: side),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StarBurstPainter old) =>
      old.progress != progress || old.colors != colors;
}
