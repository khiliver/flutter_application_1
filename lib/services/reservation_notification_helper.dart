import '../models/reservation.dart';
import 'notification_storage.dart';

/// Helper service to handle all reservation-related notifications.
class ReservationNotificationHelper {
  static Future<void> notifyReservationCreated(
    ReservationItem reservation, {
    required String? userEmail,
    required String? userName,
  }) async {
    if (userEmail == null) return;

    final displayName = (userName?.trim().isNotEmpty ?? false)
        ? userName!
        : 'A user';

    // Admin notification (global)
    await NotificationStorage.instance.addNotification(
      AppNotification(
        title: 'New reservation',
        subtitle: '$displayName reserved "${reservation.title}".',
        createdAt: DateTime.now(),
      ),
    );

    // Student notification (targeted)
    if (userEmail.isNotEmpty) {
      await NotificationStorage.instance.addNotification(
        AppNotification(
          title: 'Reservation created',
          subtitle: 'Your reservation for "${reservation.title}" was created.',
          createdAt: DateTime.now(),
          recipientEmail: userEmail,
        ),
      );
    }
  }

  static Future<void> notifyReservationCancelled(
    ReservationItem reservation, {
    required bool isManager,
    required String userRole,
    required String? userEmail,
  }) async {
    if (isManager && reservation.requesterEmail.isNotEmpty) {
      await NotificationStorage.instance.addNotification(
        AppNotification(
          title: 'Reservation updated',
          subtitle:
              'Your reservation for "${reservation.title}" was cancelled by $userRole.',
          createdAt: DateTime.now(),
          recipientEmail: reservation.requesterEmail,
        ),
      );
    }

    if (userRole.toLowerCase() == 'user' &&
        userEmail != null &&
        userEmail.isNotEmpty) {
      await NotificationStorage.instance.addNotification(
        AppNotification(
          title: 'Reservation updated',
          subtitle:
              'Your reservation for "${reservation.title}" was cancelled.',
          createdAt: DateTime.now(),
          recipientEmail: userEmail,
        ),
      );
    }
  }

  static Future<void> notifyReservationDeleted(
    ReservationItem removed, {
    required bool isManager,
    required String userRole,
  }) async {
    if (isManager && removed.requesterEmail.isNotEmpty) {
      await NotificationStorage.instance.addNotification(
        AppNotification(
          title: 'Reservation removed',
          subtitle:
              'Your reservation for "${removed.title}" was removed by $userRole.',
          createdAt: DateTime.now(),
          recipientEmail: removed.requesterEmail,
        ),
      );
    }
  }

  static Future<void> notifyReservationUpdated(
    ReservationItem original,
    ReservationItem updated, {
    required bool isManager,
    required String userRole,
    required String? userEmail,
  }) async {
    if (isManager && original.requesterEmail.isNotEmpty) {
      await NotificationStorage.instance.addNotification(
        AppNotification(
          title: 'Reservation updated',
          subtitle:
              'Your reservation for "${updated.title}" was updated by $userRole.',
          createdAt: DateTime.now(),
          recipientEmail: original.requesterEmail,
        ),
      );
    }

    if (userRole.toLowerCase() == 'user' &&
        userEmail != null &&
        userEmail.isNotEmpty) {
      await NotificationStorage.instance.addNotification(
        AppNotification(
          title: 'Reservation updated',
          subtitle: 'Your reservation was updated to "${updated.title}".',
          createdAt: DateTime.now(),
          recipientEmail: userEmail,
        ),
      );
    }
  }
}
