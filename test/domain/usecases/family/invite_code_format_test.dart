// The two halves of living with a twelve-character invite code (TASK-495):
// it is shown in groups so it can be read aloud, and it is normalised on the
// way back in so however the reader wrote those groups down still works.
//
// They have to be inverses. A display format the joiner cannot type back is
// worse than no formatting at all.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/usecases/family/join_family_usecase.dart';

void main() {
  group('formatInviteCode', () {
    test('breaks twelve characters into three groups of four', () {
      expect(formatInviteCode('ABCDEFGHJKMN'), 'ABCD EFGH JKMN');
    });

    test('leaves a short legacy code alone', () {
      // Families created before TASK-495 still hold six-character codes.
      expect(formatInviteCode('ABC234'), 'ABC2 34');
    });

    test('an empty code formats to nothing rather than throwing', () {
      expect(formatInviteCode(''), '');
    });
  });

  group('normaliseInviteCode', () {
    test('accepts what formatInviteCode produced', () {
      const code = 'ABCDEFGHJKMN';
      expect(normaliseInviteCode(formatInviteCode(code)), code);
    });

    test('accepts dashes, tabs and mixed case', () {
      expect(normaliseInviteCode('abcd-efgh\tjkmn'), 'ABCDEFGHJKMN');
    });

    test('a code of only separators normalises to empty', () {
      expect(normaliseInviteCode('  --  '), '');
    });
  });
}
