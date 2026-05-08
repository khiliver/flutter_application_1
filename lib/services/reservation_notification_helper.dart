import 'account_storage.dart';
import '../models/reservation.dart';
import 'notification_storage.dart';

/// Helper service to handle all reservation-related notifications.
class ReservationNotificationHelper {
  static const _defaultCollectionDriveUrl =
      'https://drive.google.com/drive/folders/1u7MoTEH_0XVlZESdZ9n45YV2k7z1_RQ3?usp=sharing';
  static const _collegeOfLawCollectionDriveUrl =
      'https://drive.google.com/file/d/10CAQeuWzPFbMXof0rim5qFH6dPgGFETq/view?usp=drive_link';
  static const _eastCampusCollectionDriveUrl =
      'https://drive.google.com/drive/u/1/folders/1Czhcf8vqpQ3yVglANVOfeEi73xqeOxic';
  static const _healthAndScienceLibraryCollectionDriveUrl =
      'https://drive.google.com/drive/folders/1uyqodWKqa7FeN7zeP0P5HaoJBnoeZYvM';
  static const _gubatCampusCollectionDriveUrl =
      'https://drive.google.com/drive/folders/1ye2ccat8TzKNcyOwFMJBdL_YXzfxCFmV?usp=drive_link';
  static const _polanguiCampusCollectionDriveUrl =
      'https://drive.google.com/drive/folders/1xezg8U_h06YWZbQ6XE8vgvw_ik7XEF0u?usp=drive_link';
  static const _guinobatanCampusCollectionDriveUrl =
      'https://drive.google.com/drive/folders/1rjJ7dKC3Tyl0MRoZQ9qZAtsrsr_ISddE?usp=drive_link';
  static const _tabacoCampusCollectionDriveUrl =
      'https://drive.google.com/drive/folders/1b0VXj7XtdG1HOwX2w7W8KYlf5-AZbFeQ?usp=drive_link';

  static String _resolveCollectionDriveUrl(String library) {
    final normalizedLibrary = library.trim().toLowerCase();
    if (normalizedLibrary == 'college of law') {
      return _collegeOfLawCollectionDriveUrl;
    }
    if (normalizedLibrary == 'east campus') {
      return _eastCampusCollectionDriveUrl;
    }
    if (normalizedLibrary == 'health and science library' ||
        normalizedLibrary == 'science and health library') {
      return _healthAndScienceLibraryCollectionDriveUrl;
    }
    if (normalizedLibrary == 'gubat campus') {
      return _gubatCampusCollectionDriveUrl;
    }
    if (normalizedLibrary == 'polangui campus') {
      return _polanguiCampusCollectionDriveUrl;
    }
    if (normalizedLibrary == 'guinobatan campus') {
      return _guinobatanCampusCollectionDriveUrl;
    }
    if (normalizedLibrary == 'tabaco campus') {
      return _tabacoCampusCollectionDriveUrl;
    }
    return _defaultCollectionDriveUrl;
  }

  static Future<void> notifyReservationCreated(
    ReservationItem reservation, {
    required String? userEmail,
    required String? userName,
  }) async {
    final requesterEmail = userEmail?.trim() ?? '';
    final displayName = (reservation.requesterName.trim().isNotEmpty)
        ? reservation.requesterName
        : (userName?.trim().isNotEmpty ?? false)
        ? userName!
        : (requesterEmail.isNotEmpty ? requesterEmail : 'A user');

    final reservationLabel = reservation.library.trim().isEmpty
        ? reservation.title
        : '${reservation.title} (${reservation.library})';

    // Notify admin(s) and librarian(s) assigned to the reservation's library.
    final library = reservation.library.trim();
    if (library.isNotEmpty) {
      final admins = await AccountStorage.instance.getAdminsForLibrary(library);
      final librarians = await AccountStorage.instance.getLibrariansForLibrary(
        library,
      );
      final notifiedEmails = <String>{};
      final normalizedRequesterEmail = requesterEmail.toLowerCase();

      for (final recipient in [...admins, ...librarians]) {
        final recipientEmail = recipient.email.trim();
        if (recipientEmail.isEmpty ||
            (normalizedRequesterEmail.isNotEmpty &&
                recipientEmail.toLowerCase() == normalizedRequesterEmail) ||
            !notifiedEmails.add(recipientEmail.toLowerCase())) {
          continue;
        }

        await NotificationStorage.instance.addNotification(
          AppNotification(
            title: displayName,
            subtitle: '$displayName reserved "$reservationLabel".',
            createdAt: DateTime.now(),
            type: AppNotificationType.reservation,
            recipientEmail: recipientEmail,
          ),
        );
      }
    }

    // Student notification (targeted)
    if (requesterEmail.isNotEmpty) {
      await NotificationStorage.instance.addNotification(
        AppNotification(
          title: displayName,
          subtitle:
              'Your reservation for "${reservation.title}" was created by ${reservation.requesterName.isNotEmpty ? reservation.requesterName : 'you'}.',
          createdAt: DateTime.now(),
          type: AppNotificationType.reservation,
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
          type: AppNotificationType.reservation,
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
          type: AppNotificationType.reservation,
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
          type: AppNotificationType.reservation,
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
          type: AppNotificationType.reservation,
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
          type: AppNotificationType.reservation,
          recipientEmail: userEmail,
        ),
      );
    }
  }

  static Future<void> notifyReservationApproved(
    ReservationItem reservation, {
    required String? userEmail,
  }) async {
    final requesterEmail = userEmail?.trim() ?? '';
    if (requesterEmail.isEmpty) return;

    final isCollectionRequest = reservation.type == ReservationType.collection;

    String subtitle =
        'Your reservation for "${reservation.title}" has been approved.';

    // Include the shared collection link for approved collection requests.
    if (isCollectionRequest) {
      final collectionDriveUrl = _resolveCollectionDriveUrl(
        reservation.library,
      );
      subtitle += '\n\nAccess the collection here: $collectionDriveUrl';
    }

    await NotificationStorage.instance.addNotification(
      AppNotification(
        title: 'Reservation Approved',
        subtitle: subtitle,
        createdAt: DateTime.now(),
        type: AppNotificationType.reservation,
        recipientEmail: requesterEmail,
      ),
    );
  }
}
