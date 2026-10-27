import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/add_managed_child_sheet.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_managed_child_repository.dart';

class _SlowRepo extends MockManagedChildRepository {
  final gate = Completer<void>();

  @override
  Future<UserId> addManagedChild(FamilyId familyId, String name) async {
    await gate.future;
    return super.addManagedChild(familyId, name);
  }
}

void main() {
  testWidgets('submitting twice before the call returns adds one child',
      (tester) async {
    final repo = _SlowRepo();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        managedChildRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      ],
      child: MaterialApp(
        theme: appLightTheme,
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: TextButton(
              onPressed: () => showAddManagedChildSheet(context, ref,
                  familyId: FamilyId('family_1'), source: 'family_tab'),
              child: const Text('add'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('managed_child_name_field')), 'Amira');
    // Call onSubmitted directly: the first Done unfocuses the field, so a
    // second simulated keyboard action would never reach it.
    final submit = tester.widget<TextField>(find.byType(TextField)).onSubmitted!;
    submit('Amira');
    await tester.pump();
    submit('Amira');
    await tester.pump();
    repo.gate.complete();
    await tester.pumpAndSettle();

    expect(repo.added, ['Amira']);
  });

  testWidgets('adding a name calls the server and closes the sheet', (tester) async {
    final repo = MockManagedChildRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        managedChildRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      ],
      child: MaterialApp(
        theme: appLightTheme,
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: TextButton(
              onPressed: () => showAddManagedChildSheet(context, ref,
                  familyId: FamilyId('family_1'), source: 'family_tab'),
              child: const Text('add'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('managed_child_name_field')), 'Amira');
    await tester.tap(find.byKey(const Key('managed_child_add_button')));
    await tester.pumpAndSettle();

    expect(repo.added, ['Amira']);
    expect(find.byKey(const Key('managed_child_name_field')), findsNothing);
  });

  testWidgets('a blank name shows the error and keeps the sheet open', (tester) async {
    final repo = MockManagedChildRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        managedChildRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      ],
      child: MaterialApp(
        theme: appLightTheme,
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: TextButton(
              onPressed: () => showAddManagedChildSheet(context, ref,
                  familyId: FamilyId('family_1'), source: 'family_tab'),
              child: const Text('add'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('managed_child_add_button')));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a name.'), findsOneWidget);
    expect(repo.added, isEmpty);
  });
}
