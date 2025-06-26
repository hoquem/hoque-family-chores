// lib/services/mock_family_service.dart

import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/services/family_service_interface.dart';

class MockFamilyService implements FamilyServiceInterface {
  // A predefined list of mock family members for testing.
  final List<FamilyMember> _mockMembers = [
    FamilyMember(
      id: 'user_parent_1',
      userId: 'user_parent_1',
      familyId: 'family_hoque_1',
      name: 'Ahmed Hoque',
      photoUrl: 'https://example.com/profiles/ahmed.jpg',
      role: FamilyRole.parent,
      points: 150,
      joinedAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
    ),
    FamilyMember(
      id: 'user_parent_2',
      userId: 'user_parent_2',
      familyId: 'family_hoque_1',
      name: 'Fatima Hoque',
      photoUrl: 'https://example.com/profiles/fatima.jpg',
      role: FamilyRole.parent,
      points: 120,
      joinedAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
    ),
    FamilyMember(
      id: 'user_child_1',
      userId: 'user_child_1',
      familyId: 'family_hoque_1',
      name: 'Zahra Hoque',
      photoUrl: 'https://example.com/profiles/zahra.jpg',
      role: FamilyRole.child,
      points: 80,
      joinedAt: DateTime.now().subtract(const Duration(days: 200)),
      updatedAt: DateTime.now(),
    ),
    FamilyMember(
      id: 'user_child_2',
      userId: 'user_child_2',
      familyId: 'family_hoque_1',
      name: 'Yusuf Hoque',
      photoUrl: 'https://example.com/profiles/yusuf.jpg',
      role: FamilyRole.child,
      points: 60,
      joinedAt: DateTime.now().subtract(const Duration(days: 150)),
      updatedAt: DateTime.now(),
    ),
    FamilyMember(
      id: 'user_child_3',
      userId: 'user_child_3',
      familyId: 'family_hoque_1',
      name: 'Amina Hoque',
      photoUrl: 'https://example.com/profiles/amina.jpg',
      role: FamilyRole.child,
      points: 40,
      joinedAt: DateTime.now().subtract(const Duration(days: 100)),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<FamilyMember>> getFamilyMembers() async {
    // Simulate a network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Return a copy of the list
    return List.from(_mockMembers);
  }
}