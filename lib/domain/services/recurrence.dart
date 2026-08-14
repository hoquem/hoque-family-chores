import '../entities/user.dart' show UserRole;

/// How often a repeating chore recurs. `never` is a one-off task — the
/// add-task default.
enum RepeatPreset { never, daily, weekly, monthly }

/// Maps a [preset] and the picked [dueDate] to an iCal RRULE string, or null
/// for [RepeatPreset.never]. The pattern derives from the due date: Weekly
/// recurs on that date's weekday, Monthly on its day-of-month. This is the
/// whole of the client's RRULE knowledge — the server's `rrule` lib does the
/// real computation.
String? rruleForRepeat(RepeatPreset preset, DateTime dueDate) {
  switch (preset) {
    case RepeatPreset.never:
      return null;
    case RepeatPreset.daily:
      return 'FREQ=DAILY';
    case RepeatPreset.weekly:
      const days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
      return 'FREQ=WEEKLY;BYDAY=${days[dueDate.weekday - 1]}';
    case RepeatPreset.monthly:
      return 'FREQ=MONTHLY;BYMONTHDAY=${dueDate.day}';
  }
}

/// Whether [role] may stop the recurring series a task belongs to. Only
/// parents/guardians manage rules; a null [ruleId] means the task is a one-off.
bool canStopRepeating(UserRole role, String? ruleId) =>
    ruleId != null &&
    (role == UserRole.parent || role == UserRole.guardian);
