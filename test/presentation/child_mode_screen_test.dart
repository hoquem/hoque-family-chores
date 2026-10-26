import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/child_mode_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_user_repository.dart';
import '../utils/task_factory.dart';

final _familyId = FamilyId('family_1');

User _kid({bool managed = true}) => User(
      id: UserId('kid'),
      name: 'Amira',
      familyId: _familyId,
      role: UserRole.child,
      points: Points(12),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isManaged: managed,
    );

Future<void> _pump(
  WidgetTester tester, {
  required Stream<User?> kid,
  required List<Task> tasks,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      // ChildModeScreen reads the signed-in parent for analytics, which
      // builds AuthNotifier; keep it off real Firebase.
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => MockUserRepository()),
      memberProfileProvider(UserId('kid')).overrideWith((_) => kid),
      taskListStreamProvider(_familyId).overrideWith((_) => Stream.value(tasks)),
    ],
    child: MaterialApp(
      theme: appLightTheme,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChildModeScreen(childId: UserId('kid'), parentName: 'Mum'),
            )),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows only the child\'s chores and the up-for-grabs ones', (tester) async {
    await _pump(tester, kid: Stream.value(_kid()), tasks: [
      testTask(id: 'a', title: 'Tidy room', status: TaskStatus.assigned, assignedTo: 'kid'),
      testTask(id: 'b', title: 'Mum chore', status: TaskStatus.assigned, assignedTo: 'mum'),
      testTask(id: 'c', title: 'Feed cat', status: TaskStatus.available),
    ]);

    expect(find.text('Amira'), findsOneWidget);
    expect(find.text('Tidy room'), findsOneWidget);
    expect(find.text('Feed cat'), findsOneWidget);
    expect(find.text('Mum chore'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Take'), findsOneWidget);
  });

  testWidgets('Back returns to the parent', (tester) async {
    await _pump(tester, kid: Stream.value(_kid()), tasks: const []);
    await tester.tap(find.text('Back to Mum'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('closes itself once the child is linked to their own phone', (tester) async {
    await _pump(
      tester,
      kid: Stream.fromIterable([_kid(), _kid(managed: false)]),
      tasks: const [],
    );
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
}
