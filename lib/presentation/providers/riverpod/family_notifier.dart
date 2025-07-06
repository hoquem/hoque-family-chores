import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/entities/family_member.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/usecases/family/get_family_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/family/create_family_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/family/update_family_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/family/add_member_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/family/remove_member_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/family/get_family_members_usecase.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'family_notifier.g.dart';

/// Manages family data and family members.
/// 
/// This notifier handles family operations including getting family details,
/// managing family members, and updating family information.
/// 
/// Example:
/// ```dart
/// final familyAsync = ref.watch(familyNotifierProvider(familyId));
/// final notifier = ref.read(familyNotifierProvider(familyId).notifier);
/// await notifier.addMember(email, role);
/// ```
@riverpod
class FamilyNotifier extends _$FamilyNotifier {
  final _logger = AppLogger();

  @override
  Future<FamilyEntity> build(FamilyId familyId) async {
    _logger.d('FamilyNotifier: Building for family $familyId');
    
    try {
      final getFamilyUseCase = ref.watch(getFamilyUseCaseProvider);
      final result = await getFamilyUseCase.call(familyId: familyId);
      
      return result.fold(
        (failure) => throw Exception(failure.message),
        (family) {
          _logger.d('FamilyNotifier: Loaded family ${family.name}');
          return family;
        },
      );
    } catch (e) {
      _logger.e('FamilyNotifier: Error loading family', error: e);
      throw Exception('Failed to load family: $e');
    }
  }

  /// Loads family data for the given family ID.
  Future<Family> _loadFamily(FamilyId familyId) async {
    _logger.d('FamilyNotifier: Loading family $familyId');
    
    try {
      final getFamilyUseCase = ref.watch(getFamilyUseCaseProvider);
      final result = await getFamilyUseCase.call(familyId: familyId);
      
      return result.fold(
        (failure) => throw Exception(failure.message),
        (family) {
          _logger.d('FamilyNotifier: Loaded family ${family.name}');
          return family;
        },
      );
    } catch (e) {
      _logger.e('FamilyNotifier: Error loading family', error: e);
      throw Exception('Failed to load family: $e');
    }
  }

  /// Creates a new family.
  Future<void> createFamily(String name, String description, UserId creatorId) async {
    _logger.d('FamilyNotifier: Creating family $name');
    
    try {
      final createFamilyUseCase = ref.read(createFamilyUseCaseProvider);
      final result = await createFamilyUseCase.call(
        name: name,
        description: description,
        creatorId: creatorId,
      );
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('FamilyNotifier: Family created successfully');
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('FamilyNotifier: Error creating family', error: e);
      throw Exception('Failed to create family: $e');
    }
  }

  /// Updates family information.
  Future<void> updateFamily(Family family) async {
    _logger.d('FamilyNotifier: Updating family ${family.id}');
    
    try {
      final updateFamilyUseCase = ref.read(updateFamilyUseCaseProvider);
      final result = await updateFamilyUseCase.call(family: family);
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('FamilyNotifier: Family updated successfully');
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('FamilyNotifier: Error updating family', error: e);
      throw Exception('Failed to update family: $e');
    }
  }

  /// Adds a member to the family.
  Future<void> addMember(UserId memberId, FamilyRole role) async {
    _logger.d('FamilyNotifier: Adding member $memberId to family');
    
    try {
      final addMemberUseCase = ref.read(addMemberUseCaseProvider);
      final result = await addMemberUseCase.call(
        memberId: memberId,
        role: role,
      );
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('FamilyNotifier: Member added successfully');
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('FamilyNotifier: Error adding member', error: e);
      throw Exception('Failed to add member: $e');
    }
  }

  /// Removes a member from the family.
  Future<void> removeMember(UserId memberId) async {
    _logger.d('FamilyNotifier: Removing member $memberId from family');
    
    try {
      final removeMemberUseCase = ref.read(removeMemberUseCaseProvider);
      final result = await removeMemberUseCase.call(memberId: memberId);
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('FamilyNotifier: Member removed successfully');
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('FamilyNotifier: Error removing member', error: e);
      throw Exception('Failed to remove member: $e');
    }
  }

  /// Refreshes the family data.
  Future<void> refresh() async {
    _logger.d('FamilyNotifier: Refreshing family data');
    ref.invalidateSelf();
  }

  /// Gets the current family.
  FamilyEntity? get family => state.value;

  /// Gets the current loading state.
  bool get isLoading => state.isLoading;

  /// Gets the current error message.
  String? get errorMessage => state.hasError ? state.error.toString() : null;
}

/// Manages family members list.
@riverpod
class FamilyMembersNotifier extends _$FamilyMembersNotifier {
  final _logger = AppLogger();

  @override
  Future<List<FamilyMember>> build(FamilyId familyId) async {
    _logger.d('FamilyMembersNotifier: Building for family $familyId');
    
    try {
      final getFamilyMembersUseCase = ref.watch(getFamilyMembersUseCaseProvider);
      final result = await getFamilyMembersUseCase.call(familyId: familyId);
      
      return result.fold(
        (failure) => throw Exception(failure.message),
        (members) {
          _logger.d('FamilyMembersNotifier: Loaded ${members.length} members');
          return members;
        },
      );
    } catch (e) {
      _logger.e('FamilyMembersNotifier: Error loading family members', error: e);
      throw Exception('Failed to load family members: $e');
    }
  }

  /// Refreshes the family members list.
  Future<void> refresh() async {
    _logger.d('FamilyMembersNotifier: Refreshing family members');
    ref.invalidateSelf();
  }

  /// Gets the current list of family members.
  List<FamilyMember> get members => state.value ?? [];

  /// Gets the current loading state.
  bool get isLoading => state.isLoading;

  /// Gets the current error message.
  String? get errorMessage => state.hasError ? state.error.toString() : null;

  /// Gets members filtered by role.
  List<FamilyMember> getMembersByRole(FamilyRole role) {
    return members.where((member) => member.role == role).toList();
  }

  /// Gets admin members.
  List<FamilyMember> get adminMembers => getMembersByRole(FamilyRole.parent);

  /// Gets regular members.
  List<FamilyMember> get regularMembers => getMembersByRole(FamilyRole.child);

  /// Gets members sorted by name.
  List<FamilyMember> get membersSortedByName {
    final sortedMembers = List<FamilyMember>.from(members);
    sortedMembers.sort((a, b) => a.name.compareTo(b.name));
    return sortedMembers;
  }

  /// Gets members sorted by join date (newest first).
  List<FamilyMember> get membersSortedByJoinDate {
    final sortedMembers = List<FamilyMember>.from(members);
    sortedMembers.sort((a, b) => b.joinedAt.compareTo(a.joinedAt));
    return sortedMembers;
  }
} 