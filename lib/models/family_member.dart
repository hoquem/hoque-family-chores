// lib/models/family_member.dart
import 'package:hoque_family_chores/models/enums.dart';

class FamilyMember {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final FamilyRole? role; // MODIFIED: Changed from String? to FamilyRole?
  final String? familyId;

  String get uid => id;

  FamilyMember({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.role,
    this.familyId,
  });
}