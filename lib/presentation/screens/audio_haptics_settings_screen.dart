import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/celebration_providers.dart';
import 'package:hoque_family_chores/presentation/services/sound_manager.dart';
import 'package:hoque_family_chores/presentation/services/haptic_manager.dart';

/// Screen for managing audio and haptics settings.
/// 
/// Allows users to toggle sound effects, haptic feedback, and reduced motion.
class AudioHapticsSettingsScreen extends ConsumerWidget {
  const AudioHapticsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundEnabled = ref.watch(soundEnabledProvider);
    final hapticsEnabled = ref.watch(hapticsEnabledProvider);
    final reduceMotion = ref.watch(reduceMotionEnabledProvider);
    final celebrationService = ref.watch(celebrationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio & Haptics'),
      ),
      body: ListView(
        children: [
          // Sound Effects Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '🔊 SOUND EFFECTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Play sounds for achievements'),
            subtitle: const Text('Quest completions, approvals, level ups'),
            value: soundEnabled,
            onChanged: (bool value) async {
              ref.read(soundEnabledProvider.notifier).state = value;
              await celebrationService.setSoundEnabled(value);
            },
            secondary: const Icon(Icons.volume_up),
            thumbColor: WidgetStateProperty.resolveWith<Color>(
              (states) => states.contains(WidgetState.selected)
                  ? const Color(0xFF6750A4)
                  : Colors.grey,
            ),
          ),
          const Divider(height: 1),

          // Preview Sounds
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preview Sounds:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SoundPreviewCard(
                        icon: Icons.music_note,
                        label: 'Quest\nComplete',
                        soundEffect: SoundEffect.questComplete,
                        enabled: soundEnabled,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SoundPreviewCard(
                        icon: Icons.celebration,
                        label: 'Approval',
                        soundEffect: SoundEffect.approvalCelebrate,
                        enabled: soundEnabled,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SoundPreviewCard(
                        icon: Icons.stars,
                        label: 'Level Up',
                        soundEffect: SoundEffect.levelUp,
                        enabled: soundEnabled,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SoundPreviewCard(
                        icon: Icons.local_fire_department,
                        label: 'Streak',
                        soundEffect: SoundEffect.streakMilestone,
                        enabled: soundEnabled,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 32, thickness: 8),

          // Haptics Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '📳 HAPTICS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Vibrate on interactions'),
            subtitle: const Text('Taps, completions, and celebrations'),
            value: hapticsEnabled,
            onChanged: (bool value) async {
              ref.read(hapticsEnabledProvider.notifier).state = value;
              await celebrationService.setHapticsEnabled(value);
            },
            secondary: const Icon(Icons.vibration),
            thumbColor: WidgetStateProperty.resolveWith<Color>(
              (states) => states.contains(WidgetState.selected)
                  ? const Color(0xFF6750A4)
                  : Colors.grey,
            ),
          ),
          const Divider(height: 1),

          // Preview Haptics
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preview Haptics:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _HapticPreviewCard(
                        icon: Icons.check,
                        label: 'Complete',
                        hapticPattern: HapticPattern.questComplete,
                        enabled: hapticsEnabled,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HapticPreviewCard(
                        icon: Icons.celebration,
                        label: 'Celebrate',
                        hapticPattern: HapticPattern.approvalCelebration,
                        enabled: hapticsEnabled,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 32, thickness: 8),

          // Accessibility Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '♿ ACCESSIBILITY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Reduce motion'),
            subtitle: const Text(
              'Replaces confetti with simple animations for motion sensitivity',
            ),
            value: reduceMotion,
            onChanged: (bool value) async {
              ref.read(reduceMotionEnabledProvider.notifier).state = value;
              await celebrationService.setReduceMotionEnabled(value);
            },
            secondary: const Icon(Icons.accessibility_new),
            thumbColor: WidgetStateProperty.resolveWith<Color>(
              (states) => states.contains(WidgetState.selected)
                  ? const Color(0xFF6750A4)
                  : Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Card for previewing sound effects.
class _SoundPreviewCard extends ConsumerWidget {
  final IconData icon;
  final String label;
  final SoundEffect soundEffect;
  final bool enabled;

  const _SoundPreviewCard({
    required this.icon,
    required this.label,
    required this.soundEffect,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundManager = ref.watch(soundManagerProvider);

    return Card(
      elevation: enabled ? 2 : 0,
      child: InkWell(
        onTap: enabled
            ? () async {
                await soundManager.play(soundEffect);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: enabled
                    ? const Color(0xFF6750A4)
                    : Colors.grey.withValues(alpha: 0.38),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? null : Colors.grey.withValues(alpha: 0.38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card for previewing haptic patterns.
class _HapticPreviewCard extends ConsumerWidget {
  final IconData icon;
  final String label;
  final HapticPattern hapticPattern;
  final bool enabled;

  const _HapticPreviewCard({
    required this.icon,
    required this.label,
    required this.hapticPattern,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hapticManager = ref.watch(hapticManagerProvider);

    return Card(
      elevation: enabled ? 2 : 0,
      child: InkWell(
        onTap: enabled
            ? () async {
                await hapticManager.trigger(hapticPattern);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: enabled
                    ? const Color(0xFF6750A4)
                    : Colors.grey.withValues(alpha: 0.38),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? null : Colors.grey.withValues(alpha: 0.38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
