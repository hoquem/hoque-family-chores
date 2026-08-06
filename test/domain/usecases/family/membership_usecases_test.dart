// Adding and removing family members.
//
// Both sat at zero coverage. Neither decides *who* may do this — the rules and
// the join-request flow do — so what is pinned here is the part they do own:
// refusing a duplicate member, refusing empty ids, and turning repository
// failures into Failures rather than exceptions.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/repositories/family_repository.dart';
import 'package:hoque_family_chores/domain/usecases/family/add_member_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/family/remove_member_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockFamilyRepository extends Mock implements FamilyRepository {}

final _familyId = FamilyId('fam1');
final _existing = UserId('kid1');
final _newcomer = UserId('kid2');

FamilyEntity _family({List<UserId>? members}) => FamilyEntity(
      id: _familyId,
      name: 'The Hoques',
      description: '',
      creatorId: _existing,
      memberIds: members ?? [_existing],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      inviteCode: 'ABCDEF',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FamilyId('fallback'));
    registerFallbackValue(UserId('fallback'));
  });

  late _MockFamilyRepository families;

  setUp(() {
    families = _MockFamilyRepository();
    when(() => families.addUserToFamily(any(), any())).thenAnswer((_) async {});
    when(() => families.removeUserFromFamily(any(), any()))
        .thenAnswer((_) async {});
  });

  group('adding a member', () {
    late AddMemberUseCase add;
    setUp(() => add = AddMemberUseCase(families));

    test('adds the newcomer and returns the family containing them', () async {
      var reads = 0;
      when(() => families.getFamily(_familyId)).thenAnswer((_) async {
        reads += 1;
        return reads == 1
            ? _family() // before the add
            : _family(members: [_existing, _newcomer]); // after
      });

      final result = await add(familyId: _familyId, userId: _newcomer);

      final family = result.fold((_) => null, (f) => f);
      expect(family, isNotNull);
      expect(family!.memberIds, contains(_newcomer));
      verify(() => families.addUserToFamily(_familyId, _newcomer)).called(1);
    });

    test('refuses to add someone twice', () async {
      when(() => families.getFamily(_familyId))
          .thenAnswer((_) async => _family(members: [_existing, _newcomer]));

      final result = await add(familyId: _familyId, userId: _newcomer);

      expect(result.fold((f) => f, (_) => null), isA<BusinessFailure>());
      verifyNever(() => families.addUserToFamily(any(), any()));
    });

    test('a missing family is a NotFoundFailure', () async {
      when(() => families.getFamily(_familyId)).thenAnswer((_) async => null);

      final result = await add(familyId: _familyId, userId: _newcomer);

      expect(result.fold((f) => f, (_) => null), isA<NotFoundFailure>());
      verifyNever(() => families.addUserToFamily(any(), any()));
    });

    test('a repository failure is reported, not thrown', () async {
      when(() => families.getFamily(_familyId))
          .thenAnswer((_) async => _family());
      when(() => families.addUserToFamily(any(), any()))
          .thenThrow(const ServerException('offline', code: 'NETWORK'));

      final result = await add(familyId: _familyId, userId: _newcomer);

      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });
  });

  group('removing a member', () {
    late RemoveMemberUseCase remove;
    setUp(() => remove = RemoveMemberUseCase(families));

    test('removes them from the family', () async {
      final result = await remove(familyId: _familyId, userId: _newcomer);

      expect(result.isRight(), isTrue);
      verify(() => families.removeUserFromFamily(_familyId, _newcomer))
          .called(1);
    });

    test('an empty family id is refused before any write', () async {
      final result =
          await remove(familyId: FamilyId.empty, userId: _newcomer);

      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
      verifyNever(() => families.removeUserFromFamily(any(), any()));
    });

    test('a repository failure is reported, not thrown', () async {
      when(() => families.removeUserFromFamily(any(), any()))
          .thenThrow(const ServerException('offline', code: 'NETWORK'));

      final result = await remove(familyId: _familyId, userId: _newcomer);

      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });

    // KNOWN GAP, pinned as it behaves. Nothing here stops the creator — or the
    // last remaining member — being removed, which would leave a family with
    // tasks, rewards and history that nobody can reach. Whether that should be
    // refused, or should delete the family, is a product decision, not a test.
    test('KNOWN GAP: the creator can be removed, orphaning the family',
        () async {
      final result = await remove(familyId: _familyId, userId: _existing);

      expect(result.isRight(), isTrue);
      verify(() => families.removeUserFromFamily(_familyId, _existing))
          .called(1);
    });
  });
}
