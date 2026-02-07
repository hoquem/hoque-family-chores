import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';

void main() {
  group('TaskId', () {
    test('creates with valid value', () {
      expect(TaskId('abc').value, 'abc');
    });

    test('trims whitespace', () {
      expect(TaskId('  abc  ').value, 'abc');
    });

    test('throws on empty', () {
      expect(() => TaskId(''), throwsArgumentError);
    });

    test('tryCreate', () {
      expect(TaskId.tryCreate(''), isNull);
      expect(TaskId.tryCreate('abc')?.value, 'abc');
    });

    test('isValid', () {
      expect(TaskId.isValid('abc'), true);
      expect(TaskId.isValid(''), false);
    });

    test('equality', () {
      expect(TaskId('abc'), equals(TaskId('abc')));
      expect(TaskId('abc'), isNot(equals(TaskId('def'))));
    });
  });

  group('UserId', () {
    test('creates with valid value', () {
      expect(UserId('user1').value, 'user1');
    });

    test('throws on empty', () {
      expect(() => UserId(''), throwsArgumentError);
    });

    test('tryCreate', () {
      expect(UserId.tryCreate(''), isNull);
      expect(UserId.tryCreate('user1')?.value, 'user1');
    });

    test('equality', () {
      expect(UserId('a'), equals(UserId('a')));
    });
  });

  group('FamilyId', () {
    test('creates with valid value', () {
      expect(FamilyId('fam1').value, 'fam1');
    });

    test('throws on empty', () {
      expect(() => FamilyId(''), throwsArgumentError);
    });

    test('tryCreate', () {
      expect(FamilyId.tryCreate(''), isNull);
      expect(FamilyId.tryCreate('fam1')?.value, 'fam1');
    });

    test('equality', () {
      expect(FamilyId('a'), equals(FamilyId('a')));
    });
  });
}
