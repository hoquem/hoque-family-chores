// The Home "Invite your family" card: shown to a parent/guardian while the
// family is solo, hidden once a second member joins or a child is looking,
// and dismissible with a 7-day snooze (shouldShowInviteCard owns the rule;
// this is the screen wiring around it).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/home_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/home/invite_family_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_auth_repository.dart';
import '../../mocks/mock_family_repository.dart';
import '../../mocks/mock_notification_repository.dart';
import '../../mocks/mock_task_repository.dart';
import '../../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';
final _me = UserId(_uid);
final _familyId = FamilyId('family_1');
const _code = 'ABCDEFGHJKMN';

User _member(String id, String name, {UserRole role = UserRole.child}) {
  return User(
    id: UserId(id),
    name: name,
    email: Email('${name.split(' ').first.toLowerCase()}@example.com'),
    photoUrl: null,
    familyId: _familyId,
    role: role,
    points: Points(0),
    joinedAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
  );
}

class _SeededFamilyRepository extends MockFamilyRepository {
  _SeededFamilyRepository(this.members);
  final List<User> members;

  @override
  Future<List<User>> getFamilyMembers(FamilyId familyId) async => members;

  @override
  Future<FamilyEntity?> getFamily(FamilyId familyId) async => FamilyEntity(
        id: _familyId,
        name: 'Test Family',
        description: '',
        creatorId: _me,
        memberIds: members.map((m) => m.id).toList(),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        inviteCode: _code,
      );
}

Future<ProviderContainer> _pumpHome(
  WidgetTester tester, {
  required UserRole role,
  List<User> extraMembers = const [],
}) async {
  tester.view.physicalSize = const Size(390, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final users = MockUserRepository();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => users),
      familyRepositoryProvider.overrideWith(
          (_) => _SeededFamilyRepository([_member(_uid, 'Ada'), ...extraMembers])),
      taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
      notificationRepositoryProvider
          .overrideWith((_) => MockNotificationRepository()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: appLightTheme, home: const HomeScreen()),
    ),
  );

  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    final profile = await users.getUserProfile(_me);
    await users.updateUserProfile(profile!.copyWith(
      name: 'Ada',
      familyId: _familyId,
      role: role,
      points: Points(0),
    ));
  });
  // One more than the other Home tests need: the invite card's own
  // SharedPreferences read only starts once the members list (itself
  // resolved on the third pump) lets _buildInviteCard run for the first
  // time, so it needs a fourth pump to resolve and show the card.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));

  return container;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('a parent in a solo family sees the invite card',
      (tester) async {
    await _pumpHome(tester, role: UserRole.parent);

    expect(find.byType(InviteFamilyCard), findsOneWidget);
  });

  testWidgets('a child never sees the invite card, even in a solo family',
      (tester) async {
    await _pumpHome(tester, role: UserRole.child);

    expect(find.byType(InviteFamilyCard), findsNothing);
  });

  testWidgets('a second family member hides the card', (tester) async {
    await _pumpHome(
      tester,
      role: UserRole.parent,
      extraMembers: [_member('kid_1', 'Zafir')],
    );

    expect(find.byType(InviteFamilyCard), findsNothing);
  });

  testWidgets('dismissing the card hides it and persists the dismissal',
      (tester) async {
    await _pumpHome(tester, role: UserRole.parent);
    expect(find.byType(InviteFamilyCard), findsOneWidget);

    await tester.tap(find.byKey(const Key('invite_family_card_dismiss')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(InviteFamilyCard), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getInt('invite_card_dismissed_at_${_familyId.value}'),
      isNotNull,
    );
  });
}
