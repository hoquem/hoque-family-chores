import 'package:hoque_family_chores/utils/logger.dart';

T? safeFromJson<T>(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson, {T? fallback}) {
  try {
    return fromJson(json);
  } catch (e, s) {
    AppLogger().e('[SafeDeserialize] Failed to parse ${T.toString()}', error: e, stackTrace: s);
    return fallback;
  }
}
