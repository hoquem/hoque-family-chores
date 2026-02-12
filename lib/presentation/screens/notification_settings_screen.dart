import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_settings/app_settings.dart';
import '../../domain/entities/push_notification.dart';
import '../../data/services/notification_preferences_service.dart';
import '../../utils/logger.dart';

/// Notification settings screen
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  final _logger = AppLogger();
  final _preferencesService = NotificationPreferencesService();
  
  NotificationPreferences? _preferences;
  bool _permissionsGranted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _loading = true);
    try {
      final prefs = await _preferencesService.getPreferences();
      // TODO: Get actual notification repository from provider
      // final enabled = await ref.read(pushNotificationRepositoryProvider).areNotificationsEnabled();
      const enabled = true; // Placeholder
      
      setState(() {
        _preferences = prefs;
        _permissionsGranted = enabled;
        _loading = false;
      });
    } catch (e, stackTrace) {
      _logger.e('Failed to load preferences', error: e, stackTrace: stackTrace);
      setState(() => _loading = false);
    }
  }

  Future<void> _setTypeEnabled(PushNotificationType type, bool enabled) async {
    try {
      await _preferencesService.setTypeEnabled(type, enabled);
      await _loadPreferences();
    } catch (e, stackTrace) {
      _logger.e('Failed to set type enabled', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _setMorningTime(TimeOfDay time) async {
    try {
      final now = DateTime.now();
      final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      await _preferencesService.setMorningReminderTime(dateTime);
      await _loadPreferences();
    } catch (e, stackTrace) {
      _logger.e('Failed to set morning time', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _setQuietHoursEnabled(bool enabled) async {
    try {
      await _preferencesService.setQuietHoursEnabled(enabled);
      await _loadPreferences();
    } catch (e, stackTrace) {
      _logger.e('Failed to set quiet hours', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _setQuietHoursStart(TimeOfDay time) async {
    try {
      final now = DateTime.now();
      final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      await _preferencesService.setQuietHoursStart(dateTime);
      await _loadPreferences();
    } catch (e, stackTrace) {
      _logger.e('Failed to set quiet hours start', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _setQuietHoursEnd(TimeOfDay time) async {
    try {
      final now = DateTime.now();
      final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      await _preferencesService.setQuietHoursEnd(dateTime);
      await _loadPreferences();
    } catch (e, stackTrace) {
      _logger.e('Failed to set quiet hours end', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      // TODO: Get from provider
      // await ref.read(pushNotificationRepositoryProvider).sendTestNotification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test notification sent')),
        );
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to send test notification', error: e, stackTrace: stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send test notification')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_preferences == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Failed to load preferences')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          // Permission warning banner
          if (!_permissionsGranted) _buildPermissionBanner(),

          // Daily Reminders
          _buildSectionHeader('DAILY REMINDERS'),
          _buildNotificationToggle(
            emoji: '🌅',
            title: 'Morning digest',
            subtitle: 'Daily summary of your quests',
            value: _preferences!.morningRemindersEnabled,
            onChanged: (value) =>
                _setTypeEnabled(PushNotificationType.morningReminder, value),
          ),
          if (_preferences!.morningRemindersEnabled)
            _buildTimePicker(
              icon: Icons.schedule,
              title: 'Time: ${_formatTime(_preferences!.morningReminderTime)}',
              enabled: _preferences!.morningRemindersEnabled,
              onTap: () => _pickMorningTime(),
            ),

          // Quest Notifications
          _buildSectionHeader('QUEST NOTIFICATIONS'),
          _buildNotificationToggle(
            emoji: '📋',
            title: 'New assignments',
            subtitle: 'When a quest is assigned',
            value: _preferences!.questAssignmentsEnabled,
            onChanged: (value) =>
                _setTypeEnabled(PushNotificationType.questAssignment, value),
          ),
          _buildNotificationToggle(
            emoji: '⏱️',
            title: 'Deadline reminders',
            subtitle: '1 hour before quest is due',
            value: _preferences!.deadlineRemindersEnabled,
            onChanged: (value) =>
                _setTypeEnabled(PushNotificationType.questReminder, value),
          ),
          _buildNotificationToggle(
            emoji: '⏰',
            title: 'Overdue alerts',
            subtitle: 'When you miss a deadline',
            value: _preferences!.overdueAlertsEnabled,
            onChanged: (value) =>
                _setTypeEnabled(PushNotificationType.questOverdue, value),
          ),

          // Approvals & Results
          _buildSectionHeader('APPROVALS & RESULTS'),
          _buildNotificationToggle(
            emoji: '✋',
            title: 'Approval requests',
            subtitle: 'When quests need review',
            value: _preferences!.approvalRequestsEnabled,
            onChanged: (value) =>
                _setTypeEnabled(PushNotificationType.approvalRequest, value),
          ),
          _buildNotificationToggle(
            emoji: '✅',
            title: 'Approval results',
            subtitle: 'When your quests are reviewed',
            value: _preferences!.approvalResultsEnabled,
            onChanged: (value) =>
                _setTypeEnabled(PushNotificationType.approvalResult, value),
          ),

          // Achievements
          _buildSectionHeader('ACHIEVEMENTS'),
          _buildNotificationToggle(
            emoji: '⭐',
            title: 'Level ups',
            subtitle: 'When you reach a new level',
            value: _preferences!.levelUpsEnabled,
            onChanged: (value) =>
                _setTypeEnabled(PushNotificationType.levelUp, value),
          ),
          _buildNotificationToggle(
            emoji: '🔥',
            title: 'Streak milestones',
            subtitle: '7, 14, 30+ day streaks',
            value: _preferences!.streakMilestonesEnabled,
            onChanged: (value) =>
                _setTypeEnabled(PushNotificationType.streakMilestone, value),
          ),

          // Family Activity
          _buildSectionHeader('FAMILY ACTIVITY'),
          _buildNotificationToggle(
            emoji: '👥',
            title: 'Family updates',
            subtitle: 'When others complete milestones (max 3/day)',
            value: _preferences!.familyActivityEnabled,
            onChanged: (value) =>
                _setTypeEnabled(PushNotificationType.familyActivity, value),
          ),

          // Quiet Hours
          _buildSectionHeader('QUIET HOURS'),
          _buildQuietHoursCard(),

          // Test Notification
          const SizedBox(height: 16),
          _buildTestButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      color: const Color(0xFFFFF3CD),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.notifications_off, color: Color(0xFFFFA000)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Notifications are disabled. Enable them to stay updated.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => AppSettings.openAppSettings(),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String emoji,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: SwitchListTile(
        title: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        value: value,
        onChanged: (newValue) {
          if (!_permissionsGranted && newValue) {
            AppSettings.openAppSettings();
          } else {
            onChanged(newValue);
          }
        },
        activeTrackColor: const Color(0xFF6750A4),
      ),
    );
  }

  Widget _buildTimePicker({
    required IconData icon,
    required String title,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: enabled ? const Color(0xFF6750A4) : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? Colors.black : Colors.grey,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: enabled ? Colors.black : Colors.grey,
      ),
      enabled: enabled,
      onTap: enabled ? onTap : null,
    );
  }

  Widget _buildQuietHoursCard() {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SwitchListTile(
            title: const Row(
              children: [
                Text('🌙', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('Do Not Disturb'),
              ],
            ),
            subtitle: const Text('Mute non-urgent notifications'),
            value: _preferences!.quietHoursEnabled,
            onChanged: _setQuietHoursEnabled,
            activeTrackColor: const Color(0xFF6750A4),
          ),
          if (_preferences!.quietHoursEnabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.bedtime, size: 20),
              title: Text('From: ${_formatTime(_preferences!.quietHoursStart)}'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              dense: true,
              onTap: _pickQuietStart,
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny, size: 20),
              title: Text('To: ${_formatTime(_preferences!.quietHoursEnd)}'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              dense: true,
              onTap: _pickQuietEnd,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'High-priority notifications (approvals, urgent) will still arrive',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton(
        onPressed: _sendTestNotification,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF6750A4),
          side: const BorderSide(color: Color(0xFF6750A4)),
          minimumSize: const Size(double.infinity, 48),
        ),
        child: const Text('Send Test Notification'),
      ),
    );
  }

  Future<void> _pickMorningTime() async {
    final time = TimeOfDay.fromDateTime(_preferences!.morningReminderTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF6750A4)),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      await _setMorningTime(picked);
    }
  }

  Future<void> _pickQuietStart() async {
    final time = TimeOfDay.fromDateTime(_preferences!.quietHoursStart);
    final picked = await showTimePicker(
      context: context,
      initialTime: time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF6750A4)),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      await _setQuietHoursStart(picked);
    }
  }

  Future<void> _pickQuietEnd() async {
    final time = TimeOfDay.fromDateTime(_preferences!.quietHoursEnd);
    final picked = await showTimePicker(
      context: context,
      initialTime: time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF6750A4)),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      await _setQuietHoursEnd(picked);
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
