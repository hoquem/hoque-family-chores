// lib/services/firebase_family_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/models/enums.dart'; // ADDED: Import for the FamilyRole enum
import 'package:hoque_family_chores/services/family_service_interface.dart';

class FirebaseFamilyService implements FamilyServiceInterface {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  @override
  Future<List<FamilyMember>> getFamilyMembers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection(_usersCollection).get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      List<FamilyMember> members = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Safely parse the role string into a FamilyRole enum
        final roleString = data['role'] as String?;
        final roleEnum = roleString != null ? FamilyRole.values.byName(roleString) : null;

        return FamilyMember(
          id: doc.id,
          name: data['displayName'] as String? ?? 'Unnamed Member',
          avatarUrl: data['photoURL'] as String?,
          // MODIFIED: Pass the converted enum to the constructor
          role: roleEnum,
        );
      }).toList();

      return members;

    } catch (e) {
      print("Error fetching family members from Firestore: $e");
      throw Exception("Failed to fetch family members: ${e.toString()}");
    }
  }
}