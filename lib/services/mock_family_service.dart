// lib/services/mock_family_service.dart

import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/services/family_service_interface.dart';

class MockFamilyService implements FamilyServiceInterface {
  // A predefined list of mock family members for testing.
  final List<FamilyMember> _mockMembers = [
    FamilyMember(
      id: 'user_parent_1',
      name: 'Ahmed Hoque',
      email: 'ahmed@example.com',
      avatarUrl: 'https://example.com/profiles/ahmed.jpg',
      // MODIFIED: Used the FamilyRole enum instead of a String
      role: FamilyRole.parent, 
      familyId: 'family_hoque_1',
    ),
    FamilyMember(
      id: 'user_parent_2',
      name: 'Fatima Hoque',
      email: 'fatima@example.com',
      avatarUrl: 'https://example.com/profiles/fatima.jpg',
      // MODIFIED: Used the FamilyRole enum instead of a String
      role: FamilyRole.parent,
      familyId: 'family_hoque_1',
    ),
    FamilyMember(
      id: 'user_child_1',
      name: 'Zahra Hoque',
      email: 'zahra@example.com',
      avatarUrl: 'https://example.com/profiles/zahra.jpg',
      // MODIFIED: Used the FamilyRole enum instead of a String
      role: FamilyRole.child,
      familyId: 'family_hoque_1',
    ),
    FamilyMember(
      id: 'user_child_2',
      name: 'Yusuf Hoque',
      email: 'yusuf@example.com',
      avatarUrl: 'https://example.com/profiles/yusuf.jpg',
      // MODIFIED: Used the FamilyRole enum instead of a String
      role: FamilyRole.child,
      familyId: 'family_hoque_1',
    ),
    FamilyMember(
      id: 'user_child_3',
      name: 'Amina Hoque',
      email: 'amina@example.com',
      avatarUrl: 'https://example.com/profiles/amina.jpg',
      // MODIFIED: Used the FamilyRole enum instead of a String
      role: FamilyRole.child,
      familyId: 'family_hoque_1',
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