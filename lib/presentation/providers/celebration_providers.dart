import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/services/sound_manager.dart';
import 'package:hoque_family_chores/presentation/services/haptic_manager.dart';
import 'package:hoque_family_chores/presentation/services/preferences_service.dart';
import 'package:hoque_family_chores/presentation/services/celebration_service.dart';

/// Provider for SoundManager instance.
final soundManagerProvider = Provider<SoundManager>((ref) {
  final manager = SoundManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// Provider for HapticManager instance.
final hapticManagerProvider = Provider<HapticManager>((ref) {
  return HapticManager();
});

/// Provider for PreferencesService instance.
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

/// Provider for CelebrationService instance.
final celebrationServiceProvider = Provider<CelebrationService>((ref) {
  final service = CelebrationService(
    soundManager: ref.watch(soundManagerProvider),
    hapticManager: ref.watch(hapticManagerProvider),
    preferencesService: ref.watch(preferencesServiceProvider),
  );
  
  // Initialize service when first accessed
  service.initialize();
  
  ref.onDispose(() => service.dispose());
  return service;
});

/// State provider for sound enabled setting.
final soundEnabledProvider = StateProvider<bool>((ref) => true);

/// State provider for haptics enabled setting.
final hapticsEnabledProvider = StateProvider<bool>((ref) => true);

/// State provider for reduce motion setting.
final reduceMotionEnabledProvider = StateProvider<bool>((ref) => false);

/// Async provider that loads initial settings.
final celebrationSettingsProvider = FutureProvider<Map<String, bool>>((ref) async {
  final preferencesService = ref.watch(preferencesServiceProvider);
  
  final soundEnabled = await preferencesService.getSoundEnabled();
  final hapticsEnabled = await preferencesService.getHapticsEnabled();
  final reduceMotion = await preferencesService.getReduceMotionEnabled();
  
  // Update state providers
  ref.read(soundEnabledProvider.notifier).state = soundEnabled;
  ref.read(hapticsEnabledProvider.notifier).state = hapticsEnabled;
  ref.read(reduceMotionEnabledProvider.notifier).state = reduceMotion;
  
  return {
    'sound': soundEnabled,
    'haptics': hapticsEnabled,
    'reduceMotion': reduceMotion,
  };
});
