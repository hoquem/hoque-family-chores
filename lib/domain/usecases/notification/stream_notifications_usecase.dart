import 'dart:async';
import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/notification_repository.dart';
import '../../value_objects/user_id.dart';

/// Use case for streaming notification updates
class StreamNotificationsUseCase {
  final NotificationRepository _notificationRepository;

  StreamNotificationsUseCase(this._notificationRepository);

  /// Streams notification updates for a user
  /// 
  /// [userId] - ID of the user to stream notifications for
  /// 
  /// Returns [Stream<List<Notification>>] on success or [Failure] on error
  Stream<Either<Failure, List<Notification>>> call({
    required UserId userId,
  }) {
    try {
      // Validate user ID
      if (userId.value.trim().isEmpty) {
        return Stream.value(Left(ValidationFailure('User ID cannot be empty')));
      }

      // Stream the notifications
      return _notificationRepository.streamNotifications(userId).map(
        (notifications) => Right<Failure, List<Notification>>(notifications),
      ).handleError(
        (error) {
          if (error is DataException) {
            return Left<Failure, List<Notification>>(ServerFailure(error.message, code: error.code));
          }
          return Left<Failure, List<Notification>>(ServerFailure('Failed to stream notifications: $error'));
        },
      );
    } catch (e) {
      return Stream.value(Left(ServerFailure('Failed to stream notifications: $e')));
    }
  }
} 