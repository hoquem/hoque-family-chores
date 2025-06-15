import 'package:hoque_family_chores/models/user_profile.dart';

abstract class UserProfileServiceInterface {
  Stream<UserProfile?> streamUserProfile({required String userId});
  Future<UserProfile?> getUserProfile({required String userId});
  Future<void> createUserProfile({required UserProfile userProfile});
  Future<void> updateUserProfile({
    required String userId,
    required UserProfile userProfile,
  });
  Future<void> deleteUserProfile({required String userId});
  Future<void> updateUserPoints({required String userId, required int points});
}
