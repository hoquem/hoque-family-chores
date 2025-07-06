import 'dart:async';
import '../entities/user.dart';
import '../value_objects/user_id.dart';
import '../value_objects/points.dart';
import '../../core/error/failures.dart';

/// Abstract interface for user data operations
abstract class UserRepository {
  /// Get a user profile by ID
  Future<User?> getUserProfile(UserId userId);

  /// Stream user profile changes
  Stream<User?> streamUserProfile(UserId userId);

  /// Create a new user profile
  Future<void> createUserProfile(User user);

  /// Update an existing user profile
  Future<void> updateUserProfile(User user);

  /// Delete a user profile
  Future<void> deleteUserProfile(UserId userId);

  /// Update user points
  Future<void> updateUserPoints(UserId userId, Points points);

  /// Add points to user
  Future<void> addPoints(UserId userId, Points points);

  /// Subtract points from user
  Future<void> subtractPoints(UserId userId, Points points);
} 