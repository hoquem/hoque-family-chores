import 'dart:async';
import 'package:hoque_family_chores/domain/repositories/user_repository.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';

/// Mock implementation of UserRepository for testing
class MockUserRepository implements UserRepository {
  final List<User> _users = [];
  final StreamController<User?> _userStreamController = StreamController<User?>.broadcast();

  MockUserRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Create some mock users
    final mockUsers = [
      User(
        id: UserId('user_1'),
        name: 'John Doe',
        email: Email('john@example.com'),
        photoUrl: null,
        familyId: FamilyId('family_1'),
        role: UserRole.parent,
        points: Points(150),
        joinedAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: UserId('user_2'),
        name: 'Jane Smith',
        email: Email('jane@example.com'),
        photoUrl: null,
        familyId: FamilyId('family_1'),
        role: UserRole.child,
        points: Points(75),
        joinedAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: UserId('user_3'),
        name: 'Bob Johnson',
        email: Email('bob@example.com'),
        photoUrl: null,
        familyId: FamilyId('family_1'),
        role: UserRole.child,
        points: Points(120),
        joinedAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
    ];

    _users.addAll(mockUsers);
  }

  @override
  Future<User?> getUserProfile(UserId userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      return _users.where((user) => user.id == userId).firstOrNull;
    } catch (e) {
      throw ServerException('Failed to get user profile: $e', code: 'USER_FETCH_ERROR');
    }
  }

  @override
  Stream<User?> streamUserProfile(UserId userId) {
    return _userStreamController.stream
        .where((user) => user?.id == userId);
  }

  @override
  Future<void> createUserProfile(User user) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      // Check if user already exists
      final existingUser = _users.where((u) => u.id == user.id).firstOrNull;
      if (existingUser != null) {
        throw ValidationException('User already exists', code: 'USER_ALREADY_EXISTS');
      }
      
      _users.add(user);
      _userStreamController.add(user);
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to create user profile: $e', code: 'USER_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateUserProfile(User user) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user;
        _userStreamController.add(user);
      } else {
        throw NotFoundException('User not found', code: 'USER_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to update user profile: $e', code: 'USER_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteUserProfile(UserId userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final initialLength = _users.length;
      _users.removeWhere((user) => user.id == userId);
      
      if (_users.length == initialLength) {
        throw NotFoundException('User not found', code: 'USER_NOT_FOUND');
      }
      
      _userStreamController.add(null);
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to delete user profile: $e', code: 'USER_DELETE_ERROR');
    }
  }

  @override
  Future<void> updateUserPoints(UserId userId, Points points) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(
          points: points,
          updatedAt: DateTime.now(),
        );
        _userStreamController.add(_users[index]);
      } else {
        throw NotFoundException('User not found', code: 'USER_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to update user points: $e', code: 'USER_POINTS_UPDATE_ERROR');
    }
  }

  @override
  Future<void> addPoints(UserId userId, Points points) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        final currentUser = _users[index];
        final newPoints = currentUser.points.add(points);
        
        _users[index] = currentUser.copyWith(
          points: newPoints,
          updatedAt: DateTime.now(),
        );
        _userStreamController.add(_users[index]);
      } else {
        throw NotFoundException('User not found', code: 'USER_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to add points: $e', code: 'USER_ADD_POINTS_ERROR');
    }
  }

  @override
  Future<void> subtractPoints(UserId userId, Points points) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        final currentUser = _users[index];
        final newPoints = currentUser.points.subtract(points);
        
        _users[index] = currentUser.copyWith(
          points: newPoints,
          updatedAt: DateTime.now(),
        );
        _userStreamController.add(_users[index]);
      } else {
        throw NotFoundException('User not found', code: 'USER_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to subtract points: $e', code: 'USER_SUBTRACT_POINTS_ERROR');
    }
  }

  /// Dispose the stream controller
  void dispose() {
    _userStreamController.close();
  }
} 