import 'account_storage.dart';
import '../models/reservation.dart';
import 'notification_storage.dart';

/// Helper service to handle all reservation-related notifications.
class ReservationNotificationHelper {
  static Future<void> notifyReservationCreated(
    ReservationItem reservation, {
    required String? userEmail,
    required String? userName,
  }) async {
    final requesterEmail = userEmail?.trim() ?? '';
    final displayName = (userName?.trim().isNotEmpty ?? false)
        ? userName!
        : 'A user';

    final reservationLabel = reservation.library.trim().isEmpty
        ? reservation.title
        : '${reservation.title} (${reservation.library})';

    // Send manager-facing notifications by role instead of global broadcast.
    for (final managerRole in const ['Admin', 'Over All Admin']) {
      await NotificationStorage.instance.addNotification(
        AppNotification(
          title: 'New reservation',
          subtitle: '$displayName reserved "$reservationLabel".',
          createdAt: DateTime.now(),
          recipientRole: managerRole,
        ),
      );
    }

    // Notify librarian(s) assigned to the reservation's library.
    final library = reservation.library.trim();
    if (library.isNotEmpty) {
      final librarians = await AccountStorage.instance.getLibrariansForLibrary(
        library,
      );
      final notifiedEmails = <String>{};
      final normalizedRequesterEmail = requesterEmail.toLowerCase();

      for (final librarian in librarians) {
        final recipientEmail = librarian.email.trim();
        if (recipientEmail.isEmpty ||
            (normalizedRequesterEmail.isNotEmpty &&
                recipientEmail.toLowerCase() == normalizedRequesterEmail) ||
            !notifiedEmails.add(recipientEmail.toLowerCase())) {
          continue;
        }

        await NotificationStorage.instance.addNotification(
          AppNotification(
            title: 'New reservation in your library',
            subtitle: '$displayName reserved "$reservationLabel".',
            createdAt: DateTime.now(),
            recipientEmail: recipientEmail,
          ),
        );
      }
    }

    // Student notification (targeted)
    if (requesterEmail.isNotEmpty) {
      await NotificationStorage.instance.addNotification(
        AppNotification(
          title: 'Reservation created',
          subtitle: 'Your reservation for "${reservation.title}" was created.',
          createdAt: DateTime.now(),
          recipientEmail: requesterEmail,
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
