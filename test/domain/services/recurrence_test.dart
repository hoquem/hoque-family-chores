import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/services/recurrence.dart';

void main() {
  group('rruleForRepeat', () {
    test('never returns null', () {
      expect(rruleForRepeat(RepeatPreset.never, DateTime(2026, 8, 15)), isNull);
    });

    test('daily is FREQ=DAILY regardless of date', () {
      expect(rruleForRepeat(RepeatPreset.daily, DateTime(2026, 8, 15)), 'FREQ=DAILY');
    });

    test('weekly pins the weekday of the due date', () {
      // 2026-08-15 is a Saturday.
      expect(rruleForRepeat(RepeatPreset.weekly, DateTime(2026, 8, 15)),
          'FREQ=WEEKLY;BYDAY=SA');
      // 2026-08-17 is a Monday.
      expect(rruleForRepeat(RepeatPreset.weekly, DateTime(2026, 8, 17)),
          'FREQ=WEEKLY;BYDAY=MO');
      expect(rruleForRepeat(RepeatPreset.weekly, DateTime(2026, 8, 14)),
          'FREQ=WEEKLY;BYDAY=FR');
      expect(rruleForRepeat(RepeatPreset.weekly, DateTime(2026, 8, 13)),
          'FREQ=WEEKLY;BYDAY=TH');
    });

    test('monthly pins the day-of-month', () {
      expect(rruleForRepeat(RepeatPreset.monthly, DateTime(2026, 8, 31)),
          'FREQ=MONTHLY;BYMONTHDAY=31');
      expect(rruleForRepeat(RepeatPreset.monthly, DateTime(2026, 8, 1)),
          'FREQ=MONTHLY;BYMONTHDAY=1');
    });
  });

  group('canStopRepeating', () {
    test('parents and guardians can stop a repeating task', () {
      expect(canStopRepeating(UserRole.parent, 'rule-1'), isTrue);
      expect(canStopRepeating(UserRole.guardian, 'rule-1'), isTrue);
    });

    test('children and one-off tasks cannot be stopped', () {
      expect(canStopRepeating(UserRole.child, 'rule-1'), isFalse);
      expect(canStopRepeating(UserRole.parent, null), isFalse);
    });
  });
}
