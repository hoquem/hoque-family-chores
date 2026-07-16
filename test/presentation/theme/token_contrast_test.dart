// Guards the contrast promises DESIGN.md makes, against the real token values.
//
// PRODUCT.md sets WCAG AA as a hard product requirement: the app is handed to
// children who are emerging readers. These are the pairings the UI actually
// renders, so a token tweak that breaks legibility fails here rather than on a
// kid's phone.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

/// WCAG 2.1 relative luminance of [c].
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG 2.1 contrast ratio between [fg] and [bg]; both must be opaque.
double contrast(Color fg, Color bg) {
  final a = _luminance(fg);
  final b = _luminance(bg);
  final hi = math.max(a, b);
  final lo = math.min(a, b);
  return (hi + 0.05) / (lo + 0.05);
}

/// Composites [fg] over [bg] at [alpha], as the status pill's tint does.
Color _over(Color fg, Color bg, double alpha) => Color.fromARGB(
      255,
      ((fg.r * alpha + bg.r * (1 - alpha)) * 255).round(),
      ((fg.g * alpha + bg.g * (1 - alpha)) * 255).round(),
      ((fg.b * alpha + bg.b * (1 - alpha)) * 255).round(),
    );

/// The alpha the status pills tint their background with.
const _pillTint = 0.12;

void main() {
  final t = kLightTokens;

  group('body and surface text', () {
    void expectAA(String name, Color fg, Color bg, {double min = 4.5}) {
      final r = contrast(fg, bg);
      expect(r, greaterThanOrEqualTo(min),
          reason: '$name is ${r.toStringAsFixed(2)}:1, needs $min:1');
    }

    test('ink on cream meets AA', () => expectAA('ink/cream', t.ink, t.cream));
    test('inkSoft on cream meets AA',
        () => expectAA('inkSoft/cream', t.inkSoft, t.cream));
    test('ink on marigold meets AA (primary button)',
        () => expectAA('ink/marigold', t.ink, t.marigold));
    test('ink on starGold meets AA (FAB, tonal)',
        () => expectAA('ink/starGold', t.ink, t.starGold));

    test('inkMuted on cream is large-text only, never body', () {
      // DESIGN.md permits inkMuted for hints/large text (3:1), not body (4.5:1).
      // Pinning both bounds documents the constraint instead of leaving the
      // next reader to guess which it is.
      final r = contrast(t.inkMuted, t.cream);
      expect(r, greaterThanOrEqualTo(3.0),
          reason: 'inkMuted must clear 3:1 for large text');
      expect(r, lessThan(4.5),
          reason: 'if inkMuted ever clears 4.5:1, DESIGN.md should promote it');
    });
  });

  group('status pills: ink label on a 12% tint, icon in the deep tone', () {
    // (label, base colour, deep tone used for the icon)
    final pills = <String, List<Color>>{
      'Done': [t.sprout, t.sproutDeep],
      'Waiting': [t.amberWarn, t.amberWarnDeep],
      'In progress': [t.carrot, t.carrotDeep],
      'Try again': [t.brick, t.brickDeep],
    };

    pills.forEach((label, colors) {
      final base = colors[0];
      final deep = colors[1];
      final tint = _over(base, t.cream, _pillTint);

      test('$label: ink label meets AA on the tint', () {
        final r = contrast(t.ink, tint);
        expect(r, greaterThanOrEqualTo(4.5),
            reason: '$label label is ${r.toStringAsFixed(2)}:1, needs 4.5:1');
      });

      test('$label: icon meets 3:1 on the tint', () {
        final r = contrast(deep, tint);
        expect(r, greaterThanOrEqualTo(3.0),
            reason: '$label icon is ${r.toStringAsFixed(2)}:1, needs 3:1');
      });

      test('$label: the base tone would fail as label text', () {
        // The regression this suite exists to prevent. DESIGN.md used to spec
        // the full-saturation status colour as the label; it cannot pass AA on
        // a 12% tint of itself. Locking the failure in stops a well-meaning
        // "use the status colour" change from shipping.
        expect(contrast(base, tint), lessThan(4.5),
            reason: '$label base tone unexpectedly passes; re-check DESIGN.md');
      });
    });
  });

  group('buttons resolve to AA pairs', () {
    // The token pairs above being sound does not make the buttons sound: what
    // ships is whatever ColorScheme.fromSeed derives unless the theme states
    // the colours. Marigold is a light seed, so M3 hands back a light
    // container with coloured text — 2.43:1 on the live Create Task button.
    // These resolve the real ButtonStyle, which is the only thing that catches
    // it (see issue #132).
    ButtonStyle styleOf(String name, ButtonStyle? s) {
      expect(s, isNotNull, reason: '$name should be themed, not left to M3');
      return s!;
    }

    void expectPair(String name, ButtonStyle style, Set<WidgetState> states) {
      final bg = style.backgroundColor?.resolve(states);
      final fg = style.foregroundColor?.resolve(states);
      expect(bg, isNotNull, reason: '$name needs an explicit background');
      expect(fg, isNotNull, reason: '$name needs an explicit foreground');
      final r = contrast(fg!, bg!);
      expect(r, greaterThanOrEqualTo(4.5),
          reason: '$name is ${r.toStringAsFixed(2)}:1 for states $states');
    }

    test('ElevatedButton: default and pressed', () {
      final s = styleOf('elevatedButton', appLightTheme.elevatedButtonTheme.style);
      expectPair('elevatedButton', s, <WidgetState>{});
      expectPair('elevatedButton', s, {WidgetState.pressed});
    });

    test('FilledButton: default and pressed', () {
      final s = styleOf('filledButton', appLightTheme.filledButtonTheme.style);
      expectPair('filledButton', s, <WidgetState>{});
      expectPair('filledButton', s, {WidgetState.pressed});
    });

    test('OutlinedButton label reads on the page', () {
      // Transparent fill, so the label is measured against the page.
      final s = styleOf('outlinedButton', appLightTheme.outlinedButtonTheme.style);
      final fg = s.foregroundColor?.resolve(<WidgetState>{});
      expect(fg, isNotNull, reason: 'outlinedButton needs an explicit label colour');
      final r = contrast(fg!, t.cream);
      expect(r, greaterThanOrEqualTo(4.5),
          reason: 'outlined label is ${r.toStringAsFixed(2)}:1 on cream; M3 '
              'defaults it to primary (marigold), which is 2.51:1');
    });

    test('marigoldDeep is not usable as a button fill', () {
      // 4.05:1 with Ink, 3.85:1 with Cream — it fails both ways, so DESIGN.md's
      // "pressed = marigold-deep" cannot be right. Pinned so nobody adopts it.
      expect(contrast(t.ink, t.marigoldDeep), lessThan(4.5));
      expect(contrast(t.cream, t.marigoldDeep), lessThan(4.5));
    });
  });

  group('prohibited pairings stay prohibited', () {
    const white = Color(0xFFFFFFFF);
    test('white on marigold fails', () {
      expect(contrast(white, t.marigold), lessThan(4.5));
    });
    test('white on starGold fails', () {
      expect(contrast(white, t.starGold), lessThan(4.5));
    });
  });
}
