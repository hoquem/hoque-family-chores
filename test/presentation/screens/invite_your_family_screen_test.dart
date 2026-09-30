// The step shown right after "Create a family" succeeds: never a dead end
// (always skippable), and a completed share is not logged as a skip.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/data/services/invite_sharer.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/just_created_family_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/invite_your_family_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

const _code = 'ABCDEFGHJKMN';
final _family = FamilyEntity(
  id: FamilyId('fam_1'),
  name: 'The Hoques',
  description: '',
  creatorId: UserId('adult_uid'),
  memberIds: [UserId('adult_uid')],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  inviteCode: _code,
);

class _FakeSharer implements InviteSharer {
  final shared = <String>[];
  Object? throwOnShare;

  @override
  Future<void> share(String text, {Rect? origin}) async {
    if (throwOnShare != null) throw throwOnShare!;
    shared.add(text);
  }
}

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

User _adult() => User(
      id: UserId('adult_uid'),
      name: 'Ada',
      email: Email('ada@example.com'),
      familyId: FamilyId('fam_1'),
      role: UserRole.parent,
      points: Points(0),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  late _FakeSharer sharer;
  late FakeFirebaseFirestore firestore;
  late ProviderContainer container;

  setUp(() {
    sharer = _FakeSharer();
    firestore = FakeFirebaseFirestore();
    container = ProviderContainer(
      overrides: [
        authNotifierProvider
            .overrideWith(() => _FixedAuthNotifier(AuthState(user: _adult()))),
        inviteSharerProvider.overrideWith((_) => sharer),
        analyticsProvider.overrideWith((_) => Analytics(firestore)),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: appLightTheme,
          home: InviteYourFamilyScreen(family: _family),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the grouped invite code and logs inviteStepShown',
      (tester) async {
    await pump(tester);

    expect(find.text('ABCD EFGH JKMN'), findsOneWidget);

    final events =
        await tester.runAsync(() => firestore.collection('analyticsEvents').get());
    expect(events!.docs.map((d) => d['name']), contains('inviteStepShown'));
  });

  testWidgets('Maybe later clears the signal and logs inviteStepSkipped',
      (tester) async {
    await pump(tester);

    expect(find.text('Maybe later'), findsOneWidget);
    await tester.tap(find.text('Maybe later'));
    await tester.pump();

    expect(container.read(justCreatedFamilyProvider), isNull);
    final events =
        await tester.runAsync(() => firestore.collection('analyticsEvents').get());
    expect(events!.docs.map((d) => d['name']), contains('inviteStepSkipped'));
  });

  testWidgets(
      'sharing relabels the exit to Done and does not count as a skip',
      (tester) async {
    await pump(tester);

    await tester.tap(find.text('Share invite'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(sharer.shared, hasLength(1));
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Maybe later'), findsNothing);

    await tester.tap(find.text('Done'));
    await tester.pump();

    expect(container.read(justCreatedFamilyProvider), isNull);
    final events =
        await tester.runAsync(() => firestore.collection('analyticsEvents').get());
    expect(
      events!.docs.map((d) => d['name']),
      isNot(contains('inviteStepSkipped')),
    );
  });

  testWidgets('never a dead end: Copy is always reachable', (tester) async {
    await pump(tester);

    expect(find.text('Copy'), findsOneWidget);
  });
}
