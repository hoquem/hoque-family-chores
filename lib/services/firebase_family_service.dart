// lib/services/firebase_family_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/family_member.dart'; // Use your app name
import 'package:hoque_family_chores/services/family_service_interface.dart'; // Use your app name

class FirebaseFamilyService implements FamilyServiceInterface {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users'; // Assuming your collection is named 'users'

  @override
  Future<List<FamilyMember>> getFamilyMembers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection(_usersCollection).get();

      if (querySnapshot.docs.isEmpty) {
        return []; // Return an empty list if no users are found
      }

      List<FamilyMember> members = querySnapshot.docs.map((doc) {
        // Explicitly cast data to Map<String, dynamic>
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Provide default values or handle missing fields gracefully
        return FamilyMember(
          id: doc.id, // Using Firestore document ID as the FamilyMember ID
          name: data['displayName'] as String? ?? 'Unnamed Member', // Default if null
          avatarUrl: data['photoURL'] as String?, // Nullable
          role: data['role'] as String?, // Nullable, e.g., 'Parent', 'Child'
        );
      }).toList();

      return members;

    } catch (e) {
      // Log the error or handle it more gracefully
      print("Error fetching family members from Firestore: $e");
      // Re-throw the exception or return a custom error object/empty list
      // For now, re-throwing allows FamilyListProvider to catch it.
      throw Exception("Failed to fetch family members: ${e.toString()}");
    }
  }
}