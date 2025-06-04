class FamilyMember {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? role;

  FamilyMember({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.role,
  });

  @override
  String toString() {
    return 'FamilyMember(id: $id, name: $name, role: $role, photoUrl: $avatarUrl)';
  } 
}