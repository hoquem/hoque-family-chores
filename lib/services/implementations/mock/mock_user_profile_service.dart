import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/services/interfaces/user_profile_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class MockUserProfileService implements UserProfileServiceInterface {
  final Map<String, UserProfile> _userProfiles = {};
  final _logger = AppLogger();

  MockUserProfileService() {
    _logger.i(
      "MockUserProfileService initialized with empty user profiles map.",
    );
  }

  @override
  Stream<UserProfile?> streamUserProfile({required String userId}) {
    return ServiceUtils.handleServiceStream(
      stream: () async* {
        await Future.delayed(const Duration(milliseconds: 300));
        yield _userProfiles[userId];
      },
      streamName: 'streamUserProfile',
      context: {'userId': userId},
    );
  }

  @override
  Future<UserProfile?> getUserProfile({required String userId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        return _userProfiles[userId];
      },
      operationName: 'getUserProfile',
      context: {'userId': userId},
    );
  }

  @override
  Future<void> createUserProfile({required UserProfile userProfile}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _userProfiles[userProfile.member.id] = userProfile;
      },
      operationName: 'createUserProfile',
      context: {'userId': userProfile.member.id},
    );
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    required UserProfile userProfile,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _userProfiles[userId] = userProfile;
      },
      operationName: 'updateUserProfile',
      context: {'userId': userId},
    );
  }

  @override
  Future<void> deleteUserProfile({required String userId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _userProfiles.remove(userId);
      },
      operationName: 'deleteUserProfile',
      context: {'userId': userId},
    );
  }

  @override
  Future<void> updateUserPoints({required String userId, required int points}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        final profile = _userProfiles[userId];
        if (profile != null) {
          _userProfiles[userId] = profile.copyWith(
            totalPoints: profile.totalPoints + points,
          );
        }
      },
      operationName: 'updateUserPoints',
      context: {'userId': userId, 'points': points},
    );
  }
}
