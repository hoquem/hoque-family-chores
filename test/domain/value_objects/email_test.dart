import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';

void main() {
  group('Email', () {
    test('creates with valid email', () {
      final email = Email('test@example.com');
      expect(email.value, 'test@example.com');
    });

    test('normalizes to lowercase', () {
      final email = Email('Test@Example.COM');
      expect(email.value, 'test@example.com');
    });

    test('throws on empty string', () {
      expect(() => Email(''), throwsArgumentError);
    });

    test('throws on invalid format', () {
      expect(() => Email('notanemail'), throwsArgumentError);
      expect(() => Email('@example.com'), throwsArgumentError);
    });

    test('localPart returns part before @', () {
      expect(Email('test@example.com').localPart, 'test');
    });

    test('domain returns part after @', () {
      expect(Email('test@example.com').domain, 'example.com');
    });

    test('tryCreate returns null for invalid', () {
      expect(Email.tryCreate('invalid'), isNull);
      expect(Email.tryCreate('test@example.com')?.value, 'test@example.com');
    });

    test('equality', () {
      expect(Email('test@example.com'), equals(Email('test@example.com')));
      expect(Email('a@b.com'), isNot(equals(Email('c@d.com'))));
    });

    test('toString', () {
      expect(Email('test@example.com').toString(), 'test@example.com');
    });
  });
}
