// lib/services/mock_family_service.dart
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/services/family_service_interface.dart';

class MockFamilyService implements FamilyServiceInterface {
  // --- UPDATED MOCK DATA ---
  // A private list of mock family members using the names and roles you provided.
  // Avatars are generated using the fun DiceBear API (https://www.dicebear.com/).
  final List<FamilyMember> _mockMembers = [
    FamilyMember(
      id: 'fm_001',
      name: 'Mahmudul Hoque',
      role: 'Parent',
      avatarUrl: 'https://api.dicebear.com/8.x/adventurer/svg?seed=Mahmudul',
    ),
    FamilyMember(
      id: 'fm_002',
      name: 'Alima Begum',
      role: 'Parent',
      avatarUrl: 'https://api.dicebear.com/8.x/adventurer/svg?seed=Alima',
    ),
    FamilyMember(
      id: 'fm_003',
      name: 'Roshina Hoque',
      role: 'Admin',
      avatarUrl: 'https://api.dicebear.com/8.x/bottts/svg?seed=Roshina', // A cool robot avatar
    ),
    FamilyMember(
      id: 'fm_004',
      name: 'Ubaid Hoque',
      role: 'Child',
      avatarUrl: 'https://api.dicebear.com/8.x/pixel-art/svg?seed=Ubaid', // Pixel art style
    ),
    FamilyMember(
      id: 'fm_005',
      name: 'Tazim Hoque',
      role: 'Child',
      avatarUrl: 'https://api.dicebear.com/8.x/miniavs/svg?seed=Tazim', // Minimalist avatar
    ),
    FamilyMember(
      id: 'fm_006',
      name: 'Ehsaan Hoque',
      role: 'Child',
      avatarUrl: 'https://api.dicebear.com/8.x/bottts/svg?seed=Ehsaan', // Another robot
    ),
    FamilyMember(
      id: 'fm_007',
      name: 'Yamin Hoque',
      role: 'Child',
      avatarUrl: 'https://api.dicebear.com/8.x/pixel-art/svg?seed=Yamin', // Another pixel art
    ),
  ];

  // This flag allows us to easily test how the UI handles errors.
  bool _simulateError = false;

  void setSimulateError(bool shouldSimulate) {
    _simulateError = shouldSimulate;
  }

  @override
  Future<List<FamilyMember>> getFamilyMembers() async {
    // Simulate a network delay, as if fetching from a real server.
    await Future.delayed(const Duration(seconds: 1));

    if (_simulateError) {
      // Simulate a failure scenario.
      throw Exception("Simulated network error: Could not fetch family members.");
    }

    // Return a copy of the list.
    return List<FamilyMember>.from(_mockMembers);
  }

  // --- Optional helper methods for testing ---
  void addMockMemberForTesting(FamilyMember member) {
    _mockMembers.add(member);
  }

  void clearMockMembersForTesting() {
    _mockMembers.clear();
  }
}