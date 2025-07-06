import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/notification_repository.dart';
import '../../value_objects/user_id.dart';

/// Use case for getting user notifications
class GetNotificationsUseCase {
  final NotificationRepository _notificationRepository;

  GetNotificationsUseCase(this._notificationRepository);

  /// Gets all notifications for a user
  /// 
  /// [userId] - ID of the user to get notifications for
  /// 
  /// Returns [List<Notification>] on success or [Failure] on error
  Future<Either<Failure, List<Notification>>> call({
    required UserId userId,
  }) async {
    try {
      // Validate user ID
      if (userId.value.trim().isEmpty) {
        return Left(ValidationFailure('User ID cannot be empty'));
      }

      // Get the notifications
      final notifications = await _notificationRepository.getNotifications(userId);
      return Right(notifications);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to get notifications: $e'));
    }
  }
} 