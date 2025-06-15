import 'package:hoque_family_chores/utils/logger.dart';

class ServiceUtils {
  /// Wraps a Future with standardized error handling and logging
  static Future<T> handleServiceCall<T>({
    required Future<T> Function() operation,
    required String operationName,
    Map<String, dynamic>? context,
  }) async {
    try {
      logger.d(
        '$operationName started${context != null ? ' with context: $context' : ''}',
      );
      final result = await operation();
      logger.d('$operationName completed successfully');
      return result;
    } catch (e, s) {
      logger.e('$operationName failed: $e', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Wraps a Stream with standardized error handling and logging
  static Stream<T> handleServiceStream<T>({
    required Stream<T> Function() stream,
    required String streamName,
    Map<String, dynamic>? context,
  }) {
    logger.d(
      '$streamName stream started${context != null ? ' with context: $context' : ''}',
    );
    return stream().handleError((e, s) {
      logger.e('$streamName stream error: $e', error: e, stackTrace: s);
    });
  }
}
