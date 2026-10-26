import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/usecases/family/add_managed_child_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';

import '../../../mocks/mock_managed_child_repository.dart';

void main() {
  test('adds a child by trimmed name', () async {
    final repo = MockManagedChildRepository();
    final result = await AddManagedChildUseCase(repo)(
      familyId: FamilyId('fam_1'),
      name: '  Amira ',
    );
    expect(result.isRight(), isTrue);
    expect(repo.added, ['Amira']);
  });

  test('a blank name is refused before calling the server', () async {
    final repo = MockManagedChildRepository();
    final result = await AddManagedChildUseCase(repo)(
      familyId: FamilyId('fam_1'),
      name: '   ',
    );
    expect(result.isLeft(), isTrue);
    expect(repo.added, isEmpty);
  });

  test('a name over 50 characters is refused', () async {
    final repo = MockManagedChildRepository();
    final result = await AddManagedChildUseCase(repo)(
      familyId: FamilyId('fam_1'),
      name: 'A' * 51,
    );
    expect(result.isLeft(), isTrue);
  });
}
