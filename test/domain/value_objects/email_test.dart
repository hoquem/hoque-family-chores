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
      expect(() => Email('test@example'), throwsArgumentError);
      expect(() => Email('test @example.com'), throwsArgumentError);
      expect(() => Email('test@example.com extra'), throwsArgumentError);
    });

    // Real addresses people sign up with — underscore, plus and hyphen are all
    // legitimate local-part characters (RFC 5322 atoms) and must not be
    // rejected. These guard the `email_validator` package against regression.
    test('accepts the punctuation real local parts use', () {
      expect(Email('ahmed_rukes@yahoo.co.uk').value, 'ahmed_rukes@yahoo.co.uk');
      expect(Email('first.last+tag@gmail.com').value, 'first.last+tag@gmail.com');
      expect(Email('mary-jane@example.com').value, 'mary-jane@example.com');
    });

    test('accepts multi-label and hyphenated domains', () {
      expect(Email('a@yahoo.co.uk').value, 'a@yahoo.co.uk');
      expect(Email('a@mail.sub.example.org').value, 'a@mail.sub.example.org');
      expect(Email('a@my-mail.com').value, 'a@my-mail.com');
    });

    test('trims surrounding whitespace before validating', () {
      // Autofill and paste on the sign-up screen routinely add a trailing
      // space; that must not read as a malformed address.
      expect(Email('  test@example.com  ').value, 'test@example.com');
    });

    test('rejects dot-edge and repeated-dot local parts', () {
      // The old hand-rolled regex accepted these; the RFC parser must not.
      expect(() => Email('.abc@example.com'), throwsArgumentError);
      expect(() => Email('abc.@example.com'), throwsArgumentError);
      expect(() => Email('a..b@example.com'), throwsArgumentError);
    });

    test('accepts quoted and international local parts', () {
      expect(Email('"first last"@example.com').value,
          '"first last"@example.com');
      expect(Email('müller@example.com').value, 'müller@example.com');
    });

    test('rejects a trailing-dot domain and single-letter TLD', () {
      expect(() => Email('test@example.com.'), throwsArgumentError);
      expect(() => Email('a@b.c'), throwsArgumentError);
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
