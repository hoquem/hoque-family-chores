import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/data/services/invite_sharer.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/services/invite_message.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/family_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';
const _code = 'ABCDEFGHJKMN';
final _familyId = FamilyId('fam_1');

class _FamilyWithCode extends MockFamilyRepository {
  @override
  Future<FamilyEntity?> getFamily(FamilyId familyId) async => FamilyEntity(
        id: _familyId,
        name: 'Test Family',
        description: '',
        creatorId: UserId(_uid),
        memberIds: [UserId(_uid)],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        inviteCode: _code,
      );
}

class _FakeSharer implements InviteSharer {
  final shared = <String>[];
  Object? throwOnShare;

  @override
  Future<void> share(String text, {Rect? origin}) async {
    if (throwOnShare != null) throw throwOnShare!;
    shared.add(text);
  }
}

void main() {
  late _FakeSharer sharer;
  late FakeFirebaseFirestore firestore;

  Future<void> openInviteDialog(WidgetTester tester) async {
    final users = MockUserRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
        userRepositoryProvider.overrideWith((_) => users),
        familyRepositoryProvider.overrideWith((_) => _FamilyWithCode()),
        inviteSharerProvider.overrideWith((_) => sharer),
        analyticsProvider.overrideWith((_) => Analytics(firestore)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: appLightTheme, home: const FamilyScreen()),
      ),
    );
    await tester.runAsync(() async {
      await container.read(authNotifierProvider.notifier).signInWithGoogle();
      final profile = await users.getUserProfile(UserId(_uid));
      await users.updateUserProfile(profile!.copyWith(familyId: _familyId));
    });
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byTooltip('Invite someone'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  setUp(() {
    sharer = _FakeSharer();
    firestore = FakeFirebaseFirestore();
  });

  testWidgets('Share invite sends the invite message through the share sheet',
      (tester) async {
    await openInviteDialog(tester);

    await tester.tap(find.text('Share invite'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(sharer.shared, [inviteMessage(_code)]);
    final events =
        await tester.runAsync(() => firestore.collection('analyticsEvents').get());
    final docs = events!.docs.where((d) => d['name'] == 'inviteShared');
    expect(docs, hasLength(1));
    expect(docs.first['params']['source'], 'dialog');
    expect(find.byType(AlertDialog), findsNothing,
        reason: 'the dialog closes once sharing starts');
  });

  testWidgets('a failed share tells the user to copy the code instead',
      (tester) async {
    sharer.throwOnShare = StateError('no share sheet');
    await openInviteDialog(tester);

    await tester.tap(find.text('Share invite'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text("Couldn't open sharing. Use Copy instead."), findsOneWidget);
  });
}
