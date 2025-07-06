import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/notification_repository.dart';
import '../../value_objects/user_id.dart';

/// Use case for creating notifications
class CreateNotificationUseCase {
  final NotificationRepository _notificationRepository;

  CreateNotificationUseCase(this._notificationRepository);

  /// Creates a new notification
  /// 
  /// [userId] - ID of the user to create notification for
  /// [notification] - The notification to create
  /// 
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({
    required UserId userId,
    required Notification notification,
  }) async {
    try {
      // Validate user ID
      if (userId.value.trim().isEmpty) {
        return Left(ValidationFailure('User ID cannot be empty'));
      }

      // Validate notification data
      if (notification.title.trim().isEmpty) {
        return Left(ValidationFailure('Notification title cannot be empty'));
      }

      if (notification.message.trim().isEmpty) {
        return Left(ValidationFailure('Notification message cannot be empty'));
      }

      // Create the notification
      await _notificationRepository.createNotification(userId, notification);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to create notification: $e'));
    }
  }
} 