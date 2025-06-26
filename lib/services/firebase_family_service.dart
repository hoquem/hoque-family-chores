// lib/services/firebase_family_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/family_member.dart';
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
        final roleString = data['role'] as String?;
        final roleEnum = roleString != null ? FamilyRole.values.byName(roleString) : FamilyRole.child;
        return FamilyMember(
          id: doc.id,
          userId: data['userId'] as String? ?? doc.id,
          familyId: data['familyId'] as String? ?? 'unknown-family',
          name: data['displayName'] as String? ?? 'Unnamed Member',
          photoUrl: data['photoURL'] as String?,
          role: roleEnum,
          points: data['points'] as int? ?? 0,
          joinedAt: (data['joinedAt'] is Timestamp)
              ? (data['joinedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['joinedAt']?.toString() ?? '') ?? DateTime.now(),
          updatedAt: (data['updatedAt'] is Timestamp)
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();

      return members;
    } catch (e) {
      print("Error fetching family members from Firestore: $e");
      throw Exception("Failed to fetch family members: ${e.toString()}");
    }
  }
}