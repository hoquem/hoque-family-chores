import 'dart:async';
import 'package:hoque_family_chores/utils/logger.dart';

Future<T> retryWithBackoff<T>(
  Future<T> Function() fn, {
  int maxRetries = 3,
  Duration initialDelay = const Duration(milliseconds: 500),
}) async {
  final logger = AppLogger();
  for (int attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (e) {
      if (attempt == maxRetries) rethrow;
      final delay = initialDelay * (1 << attempt);
      logger.w('[Retry] Attempt ${attempt + 1} failed, retrying in ${delay.inMilliseconds}ms', error: e);
      await Future.delayed(delay);
    }
  }
  throw StateError('Unreachable');
}
