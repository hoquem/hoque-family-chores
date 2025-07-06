import 'package:equatable/equatable.dart';

/// Value object representing a family ID
class FamilyId extends Equatable {
  final String value;

  const FamilyId._(this.value);

  /// Factory constructor that validates the family ID
  factory FamilyId(String familyId) {
    if (familyId.isEmpty) {
      throw ArgumentError('Family ID cannot be empty');
    }
    return FamilyId._(familyId.trim());
  }

  /// Creates a family ID from a string, returns null if invalid
  static FamilyId? tryCreate(String familyId) {
    try {
      return FamilyId(familyId);
    } catch (e) {
      return null;
    }
  }

  /// Check if the family ID is valid
  static bool isValid(String familyId) {
    return familyId.isNotEmpty;
  }

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
} 