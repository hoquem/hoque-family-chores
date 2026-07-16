import 'package:flutter/material.dart';

/// Brand + neutral + status tokens for the "Fridge Door" palette.
///
/// See ``DESIGN.md``. Status colors are always paired with an icon and a
/// label (the Status-Never-Alone Rule); the ``*Deep`` variants are AA-safe
/// button and snackbar backgrounds, paired with dark ``onPrimary`` text
/// inherited from the marigold-seeded [ColorScheme] (never white-on-light).
class CustomColors extends ThemeExtension<CustomColors> {
  // Brand
  final Color marigold;
  final Color marigoldDeep;
  final Color starGold;
  final Color coral;

  // Status (functional)
  final Color sprout;
  final Color sproutDeep;
  final Color amberWarn;
  final Color carrot;
  final Color carrotDeep;
  final Color brick;
  final Color brickDeep;

  // Warm neutrals (tinted toward marigold; never pure grey/black/white)
  final Color cream;
  final Color surface;
  final Color ink;
  final Color inkSoft;
  final Color inkMuted;
  final Color line;

  const CustomColors({
    required this.marigold,
    required this.marigoldDeep,
    required this.starGold,
    required this.coral,
    required this.sprout,
    required this.sproutDeep,
    required this.amberWarn,
    required this.carrot,
    required this.carrotDeep,
    required this.brick,
    required this.brickDeep,
    required this.cream,
    required this.surface,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.line,
  });

  @override
  CustomColors copyWith({
    Color? marigold,
    Color? marigoldDeep,
    Color? starGold,
    Color? coral,
    Color? sprout,
    Color? sproutDeep,
    Color? amberWarn,
    Color? carrot,
    Color? carrotDeep,
    Color? brick,
    Color? brickDeep,
    Color? cream,
    Color? surface,
    Color? ink,
    Color? inkSoft,
    Color? inkMuted,
    Color? line,
  }) {
    return CustomColors(
      marigold: marigold ?? this.marigold,
      marigoldDeep: marigoldDeep ?? this.marigoldDeep,
      starGold: starGold ?? this.starGold,
      coral: coral ?? this.coral,
      sprout: sprout ?? this.sprout,
      sproutDeep: sproutDeep ?? this.sproutDeep,
      amberWarn: amberWarn ?? this.amberWarn,
      carrot: carrot ?? this.carrot,
      carrotDeep: carrotDeep ?? this.carrotDeep,
      brick: brick ?? this.brick,
      brickDeep: brickDeep ?? this.brickDeep,
      cream: cream ?? this.cream,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkMuted: inkMuted ?? this.inkMuted,
      line: line ?? this.line,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      marigold: Color.lerp(marigold, other.marigold, t)!,
      marigoldDeep: Color.lerp(marigoldDeep, other.marigoldDeep, t)!,
      starGold: Color.lerp(starGold, other.starGold, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      sprout: Color.lerp(sprout, other.sprout, t)!,
      sproutDeep: Color.lerp(sproutDeep, other.sproutDeep, t)!,
      amberWarn: Color.lerp(amberWarn, other.amberWarn, t)!,
      carrot: Color.lerp(carrot, other.carrot, t)!,
      carrotDeep: Color.lerp(carrotDeep, other.carrotDeep, t)!,
      brick: Color.lerp(brick, other.brick, t)!,
      brickDeep: Color.lerp(brickDeep, other.brickDeep, t)!,
      cream: Color.lerp(cream, other.cream, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }
}

/// The "Fridge Door" light palette (DESIGN.md). Dark theme is a planned
/// follow-up; this token scaffold is what makes it a config swap rather
/// than a repo-wide color sweep.
const CustomColors kLightTokens = CustomColors(
  marigold: Color(0xFFE08A1E),
  marigoldDeep: Color(0xFFB86A12),
  starGold: Color(0xFFFFB300),
  coral: Color(0xFFFF6B5C),
  sprout: Color(0xFF4CAF50),
  sproutDeep: Color(0xFF2E7D32),
  amberWarn: Color(0xFFF59E0B),
  carrot: Color(0xFFFB8C00),
  carrotDeep: Color(0xFF9E5600),
  brick: Color(0xFFC6412A),
  brickDeep: Color(0xFF9E3022),
  cream: Color(0xFFFBF7F0),
  surface: Color(0xFFFCF9F4),
  ink: Color(0xFF241D14),
  inkSoft: Color(0xFF5C5346),
  inkMuted: Color(0xFF8A8067),
  line: Color(0xFFE8E0D2),
);

/// The app's light [ThemeData], seeding the "Fridge Door" [ColorScheme] and
/// registering [kLightTokens] so ``context.tokens`` resolves everywhere.
///
/// Shared by the app (``main.dart``) and the widget-test harnesses so a
/// screen pumped in a test sees the same tokens it sees in production.
final ThemeData appLightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: kLightTokens.marigold,
    primary: kLightTokens.marigold,
    secondary: kLightTokens.starGold,
    tertiary: kLightTokens.coral,
    error: kLightTokens.brick,
    surface: kLightTokens.surface,
  ),
  useMaterial3: true,
  primaryColor: kLightTokens.marigold,
  scaffoldBackgroundColor: kLightTokens.cream,
  // Touch-target floor (PRODUCT.md): M3 buttons default to ~40px tall, below
  // the 44px minimum for kids with developing motor control. Lift every
  // button to 48px. Widget-level styleFrom overrides still win where set.
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  extensions: const <ThemeExtension<dynamic>>[kLightTokens],
);

/// Convenience accessor for the design tokens.
extension CustomColorsContext on BuildContext {
  CustomColors get tokens => Theme.of(this).extension<CustomColors>()!;
}