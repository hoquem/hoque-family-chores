// lib/utils/enum_helpers.dart

/// A generic and case-insensitive function to parse a string into an enum value.
///
/// [value]: The string to parse.
/// [enumValues]: The list of all possible values for the enum (e.g., `FamilyRole.values`).
/// [defaultValue]: A safe default to return if the string doesn't match any enum name.
T enumFromString<T extends Enum>(
  String? value,
  List<T> enumValues, {
  required T defaultValue,
}) {
  if (value == null || value.isEmpty) {
    return defaultValue;
  }
  try {
    // Find the enum value whose name matches the string, ignoring case.
    return enumValues.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase().trim(),
    );
  } catch (e) {
    // If no match is found, return the safe default.
    return defaultValue;
  }
}