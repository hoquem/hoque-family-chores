import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/services/data_service_interface.dart';
import 'package:hoque_family_chores/services/logging_service.dart';

class FamilyService {
  final DataServiceInterface _dataService;

  FamilyService(this._dataService);

  Future<List<UserProfile>> getFamilyMembers(String familyId) async {
    logger.d('Getting family members for family $familyId');
    try {
      final familyMembers = await _dataService.getFamilyMembers(
        familyId: familyId,
      );
      return familyMembers
          .map(
            (member) => UserProfile(
              id: member.id,
              member: member,
              points: member.points,
              badges: const [],
              achievements: const [],
              createdAt: member.joinedAt,
              updatedAt: member.updatedAt,
              avatarUrl: member.photoUrl,
              bio: null,
              completedTasks: const [],
              inProgressTasks: const [],
              availableTasks: const [],
              preferences: const {},
              statistics: const {},
            ),
          )
          .toList();
    } catch (e, s) {
      logger.e(
        'Error getting family members for family $familyId: $e',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
}
