import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hoque_family_chores/presentation/screens/audio_haptics_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AudioHapticsSettingsScreen', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should display screen title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AudioHapticsSettingsScreen(),
          ),
        ),
      );

      expect(find.text('Audio & Haptics'), findsOneWidget);
    });

    testWidgets('should display all section headers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AudioHapticsSettingsScreen(),
          ),
        ),
      );

      expect(find.text('🔊 SOUND EFFECTS'), findsOneWidget);
      expect(find.text('📳 HAPTICS'), findsOneWidget);
      expect(find.text('♿ ACCESSIBILITY'), findsOneWidget);
    });

    testWidgets('should display sound toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AudioHapticsSettingsScreen(),
          ),
        ),
      );

      expect(find.text('Play sounds for achievements'), findsOneWidget);
      expect(
        find.text('Quest completions, approvals, level ups'),
        findsOneWidget,
      );
    });

    testWidgets('should display haptics toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AudioHapticsSettingsScreen(),
          ),
        ),
      );

      expect(find.text('Vibrate on interactions'), findsOneWidget);
      expect(
        find.text('Taps, completions, and celebrations'),
        findsOneWidget,
      );
    });

    testWidgets('should display reduce motion toggle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AudioHapticsSettingsScreen(),
          ),
        ),
      );

      expect(find.text('Reduce motion'), findsOneWidget);
      expect(
        find.text(
            'Replaces confetti with simple animations for motion sensitivity'),
        findsOneWidget,
      );
    });

    testWidgets('should display sound preview cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AudioHapticsSettingsScreen(),
          ),
        ),
      );

      expect(find.text('Preview Sounds:'), findsOneWidget);
      expect(find.text('Quest\nComplete'), findsOneWidget);
      expect(find.text('Approval'), findsOneWidget);
      expect(find.text('Level Up'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
    });

    testWidgets('should display haptic preview cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AudioHapticsSettingsScreen(),
          ),
        ),
      );

      expect(find.text('Preview Haptics:'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);
      expect(find.text('Celebrate'), findsOneWidget);
    });

    testWidgets('should toggle sound switch', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AudioHapticsSettingsScreen(),
          ),
        ),
      );

      // Find the sound switch
      final soundSwitch = find.byType(Switch).first;

      // Verify initial state (should be on)
      Switch switchWidget = tester.widget(soundSwitch);
      expect(switchWidget.value, true);

      // Toggle switch
      await tester.tap(soundSwitch);
      await tester.pumpAndSettle();

      // Verify state changed
      switchWidget = tester.widget(soundSwitch);
      expect(switchWidget.value, false);
    });

    testWidgets('should have accessible widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AudioHapticsSettingsScreen(),
          ),
        ),
      );

      // Check for switch tiles which are accessible
      expect(find.byType(SwitchListTile), findsNWidgets(3));
      
      // Check for icons
      expect(find.byType(Icon), greaterThan(0));
    });
  });
}
