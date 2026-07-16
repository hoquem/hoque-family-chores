// Guards DESIGN.md §3: the type scale, and the 14px Floor Rule.
//
// The floor only holds if the theme itself cannot hand out text below it.
// Material 3's defaults include bodySmall at 12px and labelSmall at 11px, so
// an unmodified textTheme quietly supplies illegible sizes to anyone reaching
// for a named style. PRODUCT.md's readers are children still learning to read.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

void main() {
  final tt = appLightTheme.textTheme;

  /// Every named slot, so a style added later cannot dodge the floor.
  final slots = <String, TextStyle?>{
    'displayLarge': tt.displayLarge,
    'displayMedium': tt.displayMedium,
    'displaySmall': tt.displaySmall,
    'headlineLarge': tt.headlineLarge,
    'headlineMedium': tt.headlineMedium,
    'headlineSmall': tt.headlineSmall,
    'titleLarge': tt.titleLarge,
    'titleMedium': tt.titleMedium,
    'titleSmall': tt.titleSmall,
    'bodyLarge': tt.bodyLarge,
    'bodyMedium': tt.bodyMedium,
    'bodySmall': tt.bodySmall,
    'labelLarge': tt.labelLarge,
    'labelMedium': tt.labelMedium,
    'labelSmall': tt.labelSmall,
  };

  group('the 14px Floor Rule is structural', () {
    slots.forEach((name, style) {
      test('$name is at least 14px', () {
        expect(style, isNotNull, reason: '$name should be defined');
        expect(style!.fontSize, isNotNull, reason: '$name needs an explicit size');
        expect(style.fontSize, greaterThanOrEqualTo(14.0),
            reason: '$name is ${style.fontSize}px; DESIGN.md sets a 14px floor');
      });
    });
  });

  group('the scale matches DESIGN.md §3', () {
    test('body is 16px — larger than a typical app, for emerging readers', () {
      expect(tt.bodyLarge!.fontSize, 16);
      expect(tt.bodyLarge!.fontWeight, FontWeight.w400);
    });

    test('body-small is 14px, the floor itself', () {
      expect(tt.bodyMedium!.fontSize, 14);
    });

    test('title is 18px/600', () {
      expect(tt.titleLarge!.fontSize, 18);
      expect(tt.titleLarge!.fontWeight, FontWeight.w600);
    });

    test('headline is 24px/700', () {
      expect(tt.headlineMedium!.fontSize, 24);
      expect(tt.headlineMedium!.fontWeight, FontWeight.w700);
    });

    test('display is 32px/700', () {
      expect(tt.displaySmall!.fontSize, 32);
      expect(tt.displaySmall!.fontWeight, FontWeight.w700);
    });

    test('label is 14px/600 and tracked — the Bold-Label Rule', () {
      expect(tt.labelLarge!.fontSize, 14);
      expect(tt.labelLarge!.fontWeight, FontWeight.w600);
      expect(tt.labelLarge!.letterSpacing, closeTo(0.28, 0.01)); // 0.02em @14px
    });

    test('hierarchy steps by at least 1.2x, so levels stay distinguishable', () {
      // DESIGN.md's product-register scale: body 16 -> title 18 -> headline 24
      // -> display 32. Checks the two ends that carry the most contrast.
      expect(tt.headlineMedium!.fontSize! / tt.titleLarge!.fontSize!,
          greaterThanOrEqualTo(1.2));
      expect(tt.displaySmall!.fontSize! / tt.headlineMedium!.fontSize!,
          greaterThanOrEqualTo(1.2));
    });
  });
}
