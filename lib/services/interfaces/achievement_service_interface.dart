import 'package:hoque_family_chores/models/achievement.dart';

abstract class AchievementServiceInterface {
  Stream<List<Achievement>> streamUserAchievements({required String userId});
  Future<void> grantAchievement({
    required String userId,
    required Achievement achievement,
  });
}
