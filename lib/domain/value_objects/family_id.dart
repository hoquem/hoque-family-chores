import 'package:equatable/equatable.dart';

/// Value object representing a family ID
class FamilyId extends Equatable {
  final String value;

  const FamilyId._(this.value);

  /// The family ID of a user who does not belong to a family yet.
  ///
  /// A freshly signed-up user has no family until they create or join one, so
  /// that state needs a representation. This is the only way to obtain an
  /// empty [FamilyId]: the [FamilyId] constructor still rejects empty strings,
  /// so an accidental empty value cannot slip through unnoticed.
  static const FamilyId empty = FamilyId._('');

  /// Whether this ID represents a user with no family.
  bool get isEmpty => value.isEmpty;

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