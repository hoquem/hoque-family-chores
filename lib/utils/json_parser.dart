import 'package:hoque_family_chores/utils/logger.dart';

class JsonParser {
  static final _logger = AppLogger();

  /// Safely parse a string from JSON with error handling
  static String? parseString(Map<String, dynamic> json, String key, {String? defaultValue}) {
    try {
      final value = json[key];
      if (value == null) {
        _logger.w('JSON parsing: Key "$key" is null, using default: $defaultValue');
        return defaultValue;
      }
      if (value is String) {
        return value;
      }
      _logger.w('JSON parsing: Key "$key" is not a string (type: ${value.runtimeType}), converting to string');
      return value.toString();
    } catch (e) {
      _logger.e('JSON parsing: Failed to parse string for key "$key": $e');
      return defaultValue;
    }
  }

  /// Safely parse a required string from JSON with error handling
  static String parseRequiredString(Map<String, dynamic> json, String key) {
    final value = parseString(json, key);
    if (value == null) {
      throw FormatException('Required string field "$key" is missing or null');
    }
    return value;
  }

  /// Safely parse an integer from JSON with error handling
  static int? parseInt(Map<String, dynamic> json, String key, {int? defaultValue}) {
    try {
      final value = json[key];
      if (value == null) {
        _logger.w('JSON parsing: Key "$key" is null, using default: $defaultValue');
        return defaultValue;
      }
      if (value is int) {
        return value;
      }
      if (value is String) {
        return int.tryParse(value) ?? defaultValue;
      }
      if (value is double) {
        return value.toInt();
      }
      _logger.w('JSON parsing: Key "$key" cannot be converted to int (type: ${value.runtimeType}), using default: $defaultValue');
      return defaultValue;
    } catch (e) {
      _logger.e('JSON parsing: Failed to parse int for key "$key": $e');
      return defaultValue;
    }
  }

  /// Safely parse a required integer from JSON with error handling
  static int parseRequiredInt(Map<String, dynamic> json, String key) {
    final value = parseInt(json, key);
    if (value == null) {
      throw FormatException('Required int field "$key" is missing or null');
    }
    return value;
  }

  /// Safely parse a DateTime from JSON with error handling
  static DateTime? parseDateTime(Map<String, dynamic> json, String key, {DateTime? defaultValue}) {
    try {
      final value = json[key];
      if (value == null) {
        _logger.w('JSON parsing: Key "$key" is null, using default: $defaultValue');
        return defaultValue;
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        return DateTime.parse(value);
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      _logger.w('JSON parsing: Key "$key" cannot be converted to DateTime (type: ${value.runtimeType}), using default: $defaultValue');
      return defaultValue;
    } catch (e) {
      _logger.e('JSON parsing: Failed to parse DateTime for key "$key": $e');
      return defaultValue;
    }
  }

  /// Safely parse a required DateTime from JSON with error handling
  static DateTime parseRequiredDateTime(Map<String, dynamic> json, String key) {
    final value = parseDateTime(json, key);
    if (value == null) {
      throw FormatException('Required DateTime field "$key" is missing or null');
    }
    return value;
  }

  /// Safely parse a boolean from JSON with error handling
  static bool? parseBool(Map<String, dynamic> json, String key, {bool? defaultValue}) {
    try {
      final value = json[key];
      if (value == null) {
        _logger.w('JSON parsing: Key "$key" is null, using default: $defaultValue');
        return defaultValue;
      }
      if (value is bool) {
        return value;
      }
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      if (value is int) {
        return value != 0;
      }
      _logger.w('JSON parsing: Key "$key" cannot be converted to bool (type: ${value.runtimeType}), using default: $defaultValue');
      return defaultValue;
    } catch (e) {
      _logger.e('JSON parsing: Failed to parse bool for key "$key": $e');
      return defaultValue;
    }
  }

  /// Safely parse a required boolean from JSON with error handling
  static bool parseRequiredBool(Map<String, dynamic> json, String key) {
    final value = parseBool(json, key);
    if (value == null) {
      throw FormatException('Required bool field "$key" is missing or null');
    }
    return value;
  }

  /// Safely parse a list from JSON with error handling
  static List<T>? parseList<T>(Map<String, dynamic> json, String key, T Function(dynamic) converter, {List<T>? defaultValue}) {
    try {
      final value = json[key];
      if (value == null) {
        _logger.w('JSON parsing: Key "$key" is null, using default: $defaultValue');
        return defaultValue;
      }
      if (value is List) {
        return value.map(converter).toList();
      }
      _logger.w('JSON parsing: Key "$key" is not a list (type: ${value.runtimeType}), using default: $defaultValue');
      return defaultValue;
    } catch (e) {
      _logger.e('JSON parsing: Failed to parse list for key "$key": $e');
      return defaultValue;
    }
  }

  /// Safely parse a required list from JSON with error handling
  static List<T> parseRequiredList<T>(Map<String, dynamic> json, String key, T Function(dynamic) converter) {
    final value = parseList(json, key, converter);
    if (value == null) {
      throw FormatException('Required list field "$key" is missing or null');
    }
    return value;
  }

  /// Safely parse an enum from JSON with error handling
  static T? parseEnum<T>(Map<String, dynamic> json, String key, List<T> values, T defaultValue, {T? fallback}) {
    try {
      final value = json[key];
      if (value == null) {
        _logger.w('JSON parsing: Key "$key" is null, using default: $defaultValue');
        return defaultValue;
      }
      
      String stringValue;
      if (value is String) {
        stringValue = value;
      } else {
        stringValue = value.toString();
      }

      // Try to find the enum by name
      for (final enumValue in values) {
        if (enumValue.toString().split('.').last == stringValue) {
          return enumValue;
        }
      }

      _logger.w('JSON parsing: Key "$key" value "$stringValue" not found in enum values, using default: $defaultValue');
      return fallback ?? defaultValue;
    } catch (e) {
      _logger.e('JSON parsing: Failed to parse enum for key "$key": $e');
      return fallback ?? defaultValue;
    }
  }

  /// Safely parse a required enum from JSON with error handling
  static T parseRequiredEnum<T>(Map<String, dynamic> json, String key, List<T> values, T defaultValue) {
    final value = parseEnum(json, key, values, defaultValue);
    if (value == null) {
      throw FormatException('Required enum field "$key" is missing or null');
    }
    return value;
  }

  /// Safely parse a nested object from JSON with error handling
  static Map<String, dynamic>? parseObject(Map<String, dynamic> json, String key, {Map<String, dynamic>? defaultValue}) {
    try {
      final value = json[key];
      if (value == null) {
        _logger.w('JSON parsing: Key "$key" is null, using default: $defaultValue');
        return defaultValue;
      }
      if (value is Map<String, dynamic>) {
        return value;
      }
      _logger.w('JSON parsing: Key "$key" is not an object (type: ${value.runtimeType}), using default: $defaultValue');
      return defaultValue;
    } catch (e) {
      _logger.e('JSON parsing: Failed to parse object for key "$key": $e');
      return defaultValue;
    }
  }

  /// Safely parse a required object from JSON with error handling
  static Map<String, dynamic> parseRequiredObject(Map<String, dynamic> json, String key) {
    final value = parseObject(json, key);
    if (value == null) {
      throw FormatException('Required object field "$key" is missing or null');
    }
    return value;
  }
}

// Extension for nullable value handling
extension NullableExtension<T> on T? {
  R? let<R>(R Function(T) block) {
    if (this == null) return null;
    return block(this as T);
  }
} 