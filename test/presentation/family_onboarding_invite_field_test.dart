// Shared invites tell adults to type a grouped 12-character code. Autocorrect
// rewrites a group as the space after it is typed ("ABCD" -> "ABCs"), and the
// hint should show the real code shape, not the retired 6-character one.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/screens/family_onboarding_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_user_repository.dart';

void main() {
  testWidgets('the adult invite code field does not autocorrect the code',
      (tester) async {
    final user = await tester
        .runAsync(() => MockUserRepository().getUserProfile(UserId('user_1')));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: appLightTheme,
          home: FamilyOnboardingScreen(currentUser: user!),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byKey(const Key('invite_code_field')));
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);
    expect(field.decoration!.hintText, 'e.g. ABCD EFGH JKMN');
  });
}
