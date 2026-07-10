import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';

void main() {
  test('FamilyId.empty represents a user with no family', () {
    expect(FamilyId.empty.value, isEmpty);
    expect(FamilyId.empty.isEmpty, isTrue);
  });

  test('the constructor still rejects an empty string', () {
    expect(() => FamilyId(''), throwsArgumentError);
  });

  test('a real family id is not empty', () {
    final id = FamilyId('family-123');
    expect(id.isEmpty, isFalse);
    expect(id.value, 'family-123');
  });
}
