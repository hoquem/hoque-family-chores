// lib/services/mock_family_service.dart
import '../models/family_member.dart';       // Import your FamilyMember model
import './family_service_interface.dart'; // Import the interface

class MockFamilyService implements FamilyServiceInterface {
  // A private list of mock family members.
  // In a real application, this data would be fetched from a database or an API.
  final List<FamilyMember> _mockMembers = [
    FamilyMember(
      id: 'fm_001',
      name: 'Eleanor Vance',
      role: 'Parent',
      avatarUrl: 'https://i.pravatar.cc/150?u=eleanor@example.com', // Pravatar for unique placeholder images
    ),
    FamilyMember(
      id: 'fm_002',
      name: 'Marcus Holloway',
      role: 'Parent',
      avatarUrl: 'https://i.pravatar.cc/150?u=marcus@example.com',
    ),
    FamilyMember(
      id: 'fm_003',
      name: 'Lena Oxton',
      role: 'Child',
      avatarUrl: 'https://i.pravatar.cc/150?u=lena@example.com',
    ),
    FamilyMember(
      id: 'fm_004',
      name: 'Arthur Morgan',
      role: 'Uncle', // Example of a different role
      // No avatarUrl, will use placeholder in UI
    ),
    FamilyMember(
      id: 'fm_005',
      name: 'Biscuit (The Dog)',
      role: 'Pet',
      avatarUrl: 'https://i.pravatar.cc/150?u=biscuit_dog@example.com',
    ),
  ];

  // This flag allows us to easily test how the UI handles errors.
  // Set this to `true` in code to simulate an error condition.
  bool _simulateError = false;

  void setSimulateError(bool shouldSimulate) {
    _simulateError = shouldSimulate;
  }

  @override
  Future<List<FamilyMember>> getFamilyMembers() async {
    // Simulate a network delay, as if fetching from a real server.
    // This helps ensure loading indicators in the UI are tested.
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

    if (_simulateError) {
      // Simulate a failure scenario.
      throw Exception("Simulated network error: Could not fetch family members.");
    }

    // Return a *copy* of the list to prevent the original list from being
    // modified by external code, which is a good practice for state integrity.
    return List<FamilyMember>.from(_mockMembers);
  }

  // --- Optional: Methods for testing or dynamic mock data manipulation ---
  // These are not part of the FamilyServiceInterface but can be useful
  // for more complex testing scenarios if you were directly testing this mock service.

  /// Adds a member to the mock list (for testing purposes).
  void addMockMemberForTesting(FamilyMember member) {
    _mockMembers.add(member);
  }

  /// Clears all mock members (for testing purposes).
  void clearMockMembersForTesting() {
    _mockMembers.clear();
  }
}