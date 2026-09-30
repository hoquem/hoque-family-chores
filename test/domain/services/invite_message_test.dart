import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/services/invite_message.dart';

void main() {
  group('inviteMessage', () {
    final message = inviteMessage('ABCDEFGHJKMN');

    test('shows the code grouped the same way as the invite dialog', () {
      expect(message, contains('ABCD EFGH JKMN'));
    });

    test('names the controls adults and kids use to join', () {
      expect(message,
          contains('under "Join a family" enter the code and tap "Join family"'));
      expect(message, contains('tap "I\'m a kid" on the sign-in screen'));
    });

    test('links the App Store through the invite campaign', () {
      expect(
        message,
        contains('https://apps.apple.com/app/id6746752194?pt=127879651&ct=invite&mt=8'),
      );
    });

    // Play production has not launched: the store listing 404s for anyone who
    // is not an opted-in tester, so Android families go through the tester
    // group and the Play opt-in page instead.
    test('sends Android families through the tester group and Play opt-in', () {
      expect(message,
          contains('https://groups.google.com/g/chores-star-testers/about'));
      expect(message,
          contains('https://play.google.com/apps/testing/com.hoque.familychores'));
      expect(message, isNot(contains('play.google.com/store/apps/details')));
    });

    test('contains no em or en dash', () {
      expect(message, isNot(contains('—')));
      expect(message, isNot(contains('–')));
    });
  });
}
