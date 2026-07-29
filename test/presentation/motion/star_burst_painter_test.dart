import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/motion/star_burst_painter.dart';

void main() {
  testWidgets('paints at every phase of the burst without error', (tester) async {
    for (final progress in [0.0, 0.3, 0.7, 1.0]) {
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(300, 300),
          painter: StarBurstPainter(
            progress: progress,
            colors: const [Color(0xFFFFB300), Color(0xFF4CAF50), Color(0xFFC6412A)],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });

  test('repaints only when progress changes', () {
    const colors = [Color(0xFFFFB300)];
    final a = StarBurstPainter(progress: 0.2, colors: colors);
    final b = StarBurstPainter(progress: 0.2, colors: colors);
    final c = StarBurstPainter(progress: 0.4, colors: colors);
    expect(a.shouldRepaint(b), isFalse);
    expect(a.shouldRepaint(c), isTrue);
  });
}
