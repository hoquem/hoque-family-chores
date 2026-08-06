// Starting a family.
//
// Two things make this more than a write: the creator becomes a parent and is
// bound to the new family, and a family you already belong to cannot be
// abandoned by simply making another one. Both were unpinned at 0/37 covered
// lines.
//
// The invite code's uniqueness and the order the documents are written in are
// enforced by firestore.rules rather than here — see
// test/rules/family_create.test.mjs.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/repositories/family_repository.dart';
import 'package:hoque_family_chores/domain/repositories/user_repository.dart';
import 'package:hoque_family_chores/domain/usecases/family/create_family_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockFamilyRepository extends Mock implements FamilyRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

final _creator = UserId('kid1');

User _user({String? familyId}) => User(
      id: _creator,
      name: 'Aisha',
      email: Email('aisha@example.com'),
      familyId: familyId == null ? FamilyId.empty : FamilyId(familyId),
      role: UserRole.child,
      points: Points(0),
      joinedAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FamilyId('fallback'));
    registerFallbackValue(_user());
    registerFallbackValue(FamilyEntity(
      id: FamilyId('fallback'),
      name: 'x',
      description: '',
      creatorId: _creator,
      memberIds: const [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      inviteCode: 'ABCDEF',
    ));
  });

  late _MockFamilyRepository families;
  late _MockUserRepository users;
  late CreateFamilyUseCase create;

  setUp(() {
    families = _MockFamilyRepository();
    users = _MockUserRepository();
    create = CreateFamilyUseCase(families, users);
    when(() => users.getUserProfile(_creator))
        .thenAnswer((_) async => _user());
    when(() => families.createFamily(any())).thenAnswer((_) async {});
    when(() => users.updateUserProfile(any())).thenAnswer((_) async {});
  });

  group('creating a family', () {
    test('makes the creator its first member', () async {
      final result = await create(name: 'The Hoques', creatorId: _creator);

      final family = result.fold((_) => null, (f) => f);
      expect(family, isNotNull);
      expect(family!.memberIds, [_creator]);
      expect(family.creatorId, _creator);
    });

    // Whoever starts the family runs it. A child who creates one and stays a
    // child could not approve anyone's chores, including their own family's.
    test('promotes the creator to parent and binds them to it', () async {
      final result = await create(name: 'The Hoques', creatorId: _creator);
      final family = result.fold((_) => null, (f) => f)!;

      final saved = verify(() => users.updateUserProfile(captureAny()))
          .captured
          .single as User;
      expect(saved.role, UserRole.parent);
      expect(saved.familyId, family.id);
    });

    test('mints a six-character invite code', () async {
      final result = await create(name: 'The Hoques', creatorId: _creator);
      final family = result.fold((_) => null, (f) => f)!;

      expect(family.inviteCode.length, 6);
      // Ambiguous glyphs are excluded on purpose: these codes get read aloud
      // and typed by children.
      expect(family.inviteCode, matches(RegExp(r'^[A-HJ-NP-Z2-9]{6}$')));
      expect(family.inviteCode, isNot(contains('O')));
      expect(family.inviteCode, isNot(contains('I')));
      expect(family.inviteCode, isNot(contains('0')));
      expect(family.inviteCode, isNot(contains('1')));
    });

    test('trims the name', () async {
      final result = await create(name: '  The Hoques  ', creatorId: _creator);
      expect(result.fold((_) => null, (f) => f)!.name, 'The Hoques');
    });
  });

  group('refusing to create one', () {
    // The guard that stops a member walking out of a family by making a new
    // one. Leaving is its own action, with its own consequences.
    test('someone already in a family cannot start another', () async {
      when(() => users.getUserProfile(_creator))
          .thenAnswer((_) async => _user(familyId: 'existing-family'));

      final result = await create(name: 'The Hoques', creatorId: _creator);

      expect(result.fold((f) => f, (_) => null), isA<BusinessFailure>());
      verifyNever(() => families.createFamily(any()));
    });

    test('a missing user profile is a NotFoundFailure', () async {
      when(() => users.getUserProfile(_creator)).thenAnswer((_) async => null);

      final result = await create(name: 'The Hoques', creatorId: _creator);

      expect(result.fold((f) => f, (_) => null), isA<NotFoundFailure>());
      verifyNever(() => families.createFamily(any()));
    });

    test('an empty name is refused', () async {
      final result = await create(name: '   ', creatorId: _creator);

      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
      verifyNever(() => families.createFamily(any()));
    });

    test('a name over 100 characters is refused', () async {
      final result = await create(name: 'x' * 101, creatorId: _creator);
      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    });

    test('a description over 500 characters is refused', () async {
      final result = await create(
          name: 'The Hoques', description: 'x' * 501, creatorId: _creator);
      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    });
  });

  group('when a write fails', () {
    test('a failed family write is reported, not swallowed', () async {
      when(() => families.createFamily(any()))
          .thenThrow(const ServerException('offline', code: 'NETWORK'));

      final result = await create(name: 'The Hoques', creatorId: _creator);

      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
      verifyNever(() => users.updateUserProfile(any()));
    });

    // KNOWN GAP, pinned as it behaves today. The family document is written
    // before the creator's profile is linked to it, and the two are not
    // atomic. If the profile write fails the family exists with the creator in
    // memberIds, while their profile still has no familyId — so they are shown
    // an error and can create a second family, orphaning the first.
    //
    // Not fixed here: the repair is a transaction or a Cloud Function, which
    // is a change to how families are created, not a test.
    test('KNOWN GAP: a failed profile link leaves the family behind',
        () async {
      when(() => users.updateUserProfile(any()))
          .thenThrow(const ServerException('offline', code: 'NETWORK'));

      final result = await create(name: 'The Hoques', creatorId: _creator);

      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
      verify(() => families.createFamily(any())).called(1);
    });
  });
}
