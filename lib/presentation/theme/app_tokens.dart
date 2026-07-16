import 'package:flutter/material.dart';

/// Brand + neutral + status tokens for the "Fridge Door" palette.
///
/// See ``DESIGN.md``. Status colors are always paired with an icon and a label
/// (the Status-Never-Alone Rule).
///
/// The ``*Deep`` variants do two jobs: they are snackbar/button backgrounds
/// that clear AA against the light text M3 puts on them (sprout 5.13:1,
/// carrot 5.55:1, brick 7.24:1, amberWarn 5.41:1), and they are the icon tone
/// on a 12% tint of their base, where the base itself only manages 1.8–2.3:1.
///
/// [marigoldDeep] is the exception and is **not** a light-text background:
/// 4.11:1 with white, 3.85:1 with cream. It is a pressed state for the
/// marigold primary, which carries Ink text. There is no white-text variant in
/// this palette.
///
/// ``test/presentation/theme/token_contrast_test.dart`` holds these to account.
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
  final Color amberWarnDeep;
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
    required this.amberWarnDeep,
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
    Color? amberWarnDeep,
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
      amberWarnDeep: amberWarnDeep ?? this.amberWarnDeep,
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
      amberWarnDeep: Color.lerp(amberWarnDeep, other.amberWarnDeep, t)!,
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
  amberWarnDeep: Color(0xFF935F06),
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

/// The "Fridge Door" type scale (DESIGN.md §3), stated explicitly.
///
/// Without this the app inherits Material 3's geometry, which hands out
/// ``bodySmall`` at 12px and ``labelSmall`` at 11px — below the 14px Floor
/// Rule. A floor that the theme itself undercuts is not a floor, so every
/// slot is pinned at 14px or above: reaching for any named style now yields
/// something a six-year-old can read.
///
/// Sizes skew larger than a typical product app on purpose (body is 16px, not
/// 14px) for emerging readers. ``test/presentation/theme/type_scale_test.dart``
/// asserts the floor and the scale.
const TextTheme kFridgeDoorTextTheme = TextTheme(
  // Display — the greeting, celebration titles. One per screen at most.
  displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, height: 1.15),
  displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, height: 1.15),
  displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2),

  // Headline — screen titles, family name, the splash wordmark.
  headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.25),
  headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25),
  headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),

  // Title — card titles, section headers.
  titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
  titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
  titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),

  // Body — 16px default; 14px for secondary. Never below.
  bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.45),
  bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4),
  bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4),

  // Label — the Bold-Label Rule: 600, never 400, slightly tracked.
  labelLarge: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: 0.28),
  labelMedium: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: 0.28),
  labelSmall: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: 0.28),
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
  textTheme: kFridgeDoorTextTheme,
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