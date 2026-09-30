// InviteCardDismissalService owns the SharedPreferences key(s) behind the
// Home invite card's dismissal. The dismissal is per family, not global, so
// dismissing it in one family must never hide it in another.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/services/invite_card_dismissal_service.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late InviteCardDismissalService service;

  setUp(() {
    service = InviteCardDismissalService();
  });

  test('a family never dismissed reports null', () async {
    SharedPreferences.setMockInitialValues({});

    final dismissedAt = await service.dismissedAt(FamilyId('fam_1'));

    expect(dismissedAt, isNull);
  });

  test('dismiss records the time, readable back by the same family',
      () async {
    SharedPreferences.setMockInitialValues({});
    final at = DateTime(2026, 6, 1);

    await service.dismiss(FamilyId('fam_1'), at);

    expect(await service.dismissedAt(FamilyId('fam_1')), at);
  });

  test('dismissing one family never dismisses another', () async {
    SharedPreferences.setMockInitialValues({});
    await service.dismiss(FamilyId('fam_1'), DateTime(2026, 6, 1));

    expect(await service.dismissedAt(FamilyId('fam_2')), isNull);
  });
}
