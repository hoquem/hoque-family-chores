import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PreferencesService', () {
    late PreferencesService preferencesService;

    setUp(() async {
      // Initialize with empty preferences
      SharedPreferences.setMockInitialValues({});
      preferencesService = PreferencesService();
    });

    group('Sound Settings', () {
      test('should default to enabled when not set', () async {
        final enabled = await preferencesService.getSoundEnabled();
        expect(enabled, true);
      });

      test('should persist sound enabled state', () async {
        await preferencesService.setSoundEnabled(false);
        final enabled = await preferencesService.getSoundEnabled();
        expect(enabled, false);
      });

      test('should update sound enabled state', () async {
        await preferencesService.setSoundEnabled(false);
        expect(await preferencesService.getSoundEnabled(), false);

        await preferencesService.setSoundEnabled(true);
        expect(await preferencesService.getSoundEnabled(), true);
      });
    });

    group('Haptics Settings', () {
      test('should default to enabled when not set', () async {
        final enabled = await preferencesService.getHapticsEnabled();
        expect(enabled, true);
      });

      test('should persist haptics enabled state', () async {
        await preferencesService.setHapticsEnabled(false);
        final enabled = await preferencesService.getHapticsEnabled();
        expect(enabled, false);
      });

      test('should update haptics enabled state', () async {
        await preferencesService.setHapticsEnabled(false);
        expect(await preferencesService.getHapticsEnabled(), false);

        await preferencesService.setHapticsEnabled(true);
        expect(await preferencesService.getHapticsEnabled(), true);
      });
    });

    group('Reduce Motion Settings', () {
      test('should default to disabled when not set', () async {
        final enabled = await preferencesService.getReduceMotionEnabled();
        expect(enabled, false);
      });

      test('should persist reduce motion state', () async {
        await preferencesService.setReduceMotionEnabled(true);
        final enabled = await preferencesService.getReduceMotionEnabled();
        expect(enabled, true);
      });

      test('should update reduce motion state', () async {
        await preferencesService.setReduceMotionEnabled(true);
        expect(await preferencesService.getReduceMotionEnabled(), true);

        await preferencesService.setReduceMotionEnabled(false);
        expect(await preferencesService.getReduceMotionEnabled(), false);
      });
    });
  });
}
