import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../core/repositories/trip_repository.dart';
import '../../core/repositories/package_repository.dart';
import '../trip_detail/trip_detail_screen.dart';
import '../package_detail/package_detail_screen.dart';
import '../../widgets/liquid_refresh_indicator.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationService = Get.find<NotificationService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white, // Make title text white
          ),
        ),
        backgroundColor: const Color(0xFF0046FF),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Colors.white), // Make back arrow white
        actions: [
          Obx(() {
            final hasUnread = notificationService.unreadCount > 0;
            return hasUnread
                ? TextButton(
                    onPressed: () => notificationService.markAllAsRead(),
                    child: const Text(
                      'Mark All Read',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        final notifications = notificationService.notifications;

        if (notifications.isEmpty) {
          return _buildEmptyState();
        }

        return LiquidRefreshIndicator(
          onRefresh: () async {
            // Refresh notifications
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(context, notification);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF0046FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 60,
              color: Color(0xFF0046FF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'When you receive offers, updates, or messages,\nthey\'ll appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
      BuildContext context, NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: notification.isRead ? 1 : 3,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: notification.isRead
              ? BorderSide.none
              : const BorderSide(
                  color: Color(0xFF0046FF),
                  width: 1,
                ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleNotificationTap(context, notification),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: notification.isRead
                  ? Colors.white
                  : const Color(0xFF0046FF).withOpacity(0.02),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0046FF),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTimeAgo(notification.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          if (notification.type ==
                              NotificationType.offerReceived)
                            _buildActionButtons(notification),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(NotificationModel notification) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => _handleOfferAction(notification, 'reject'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
          ),
          child: const Text(
            'Decline',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _handleOfferAction(notification, 'accept'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0046FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text(
            'Accept',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.offerReceived:
        return Icons.local_offer;
      case NotificationType.offerAccepted:
        return Icons.check_circle;
      case NotificationType.offerRejected:
        return Icons.cancel;
      case NotificationType.tripUpdate:
        return Icons.flight;
      case NotificationType.packageUpdate:
        return Icons.inventory_2;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.voiceCall:
        return Icons.phone;
      case NotificationType.general:
        return Icons.location_on; // Enhanced for location-based notifications
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.offerReceived:
        return const Color(0xFF10B981);
      case NotificationType.offerAccepted:
        return const Color(0xFF0046FF);
      case NotificationType.offerRejected:
        return const Color(0xFFEF4444);
      case NotificationType.tripUpdate:
        return const Color(0xFF8B5CF6);
      case NotificationType.packageUpdate:
        return const Color(0xFFF59E0B);
      case NotificationType.message:
        return const Color(0xFF06B6D4);
      case NotificationType.voiceCall:
        return const Color(0xFF10B981); // Green for voice calls
      case NotificationType.general:
        return const Color(0xFF6B7280);
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleNotificationTap(
      BuildContext context, NotificationModel notification) async {
    // Mark as read if not already read
    if (!notification.isRead) {
      await Get.find<NotificationService>().markAsRead(notification.id);
    }

    // Handle location-based notifications
    if (notification.data != null) {
      final notificationType = notification.data!['type'];

      if (notificationType == 'new_traveller') {
        // Navigate to trip detail or place bid
        Get.snackbar(
          'New Traveller!',
          'Opening trip details to place your bid...',
          backgroundColor: const Color(0xFF0046FF),
          colorText: Colors.white,
        );
        // Navigate to trip detail page
        await _navigateToTripDetail(context, notification.data!['tripId']);
      } else if (notificationType == 'new_package') {
        // Navigate to package detail or accept delivery
        Get.snackbar(
          'New Package Request!',
          'Opening package details to accept delivery...',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
        );
        // Navigate to package detail page
        await _navigateToPackageDetail(
            context, notification.data!['packageId']);
      } else if (notificationType == 'nearby_opportunities') {
        // Navigate to opportunities screen
        Get.snackbar(
          'Checking Opportunities!',
          'Showing all nearby trips and packages...',
          backgroundColor: const Color(0xFF8B5CF6),
          colorText: Colors.white,
        );
        // Navigate to opportunities screen (explore screen)
        _navigateToOpportunities(context);
      }
    }

    // Navigate based on notification type and related entity
    if (notification.relatedEntityId != null) {
      switch (notification.type) {
        case NotificationType.offerReceived:
        case NotificationType.tripUpdate:
          // Navigate to trip detail
          // Get.toNamed('/trip-detail', arguments: notification.relatedEntityId);
          break;
        case NotificationType.packageUpdate:
          // Navigate to package detail
          // Get.toNamed('/package-detail', arguments: notification.relatedEntityId);
          break;
        case NotificationType.message:
          // Navigate to chat
          // Get.toNamed('/chat', arguments: notification.relatedEntityId);
          break;
        case NotificationType.voiceCall:
          // Navigate to incoming call screen or show call dialog
          // TODO: Implement call handling
          break;
        default:
          break;
      }
    }
  }

  void _handleOfferAction(NotificationModel notification, String action) async {
    if (action == 'accept') {
      // Handle offer acceptance
      Get.snackbar(
        'Offer Accepted',
        'You have accepted the offer. The sender will be notified.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Here you would typically call your backend to accept the offer
      // and notify the sender
      if (notification.data != null) {
        // Send notification to sender
        // await notificationService.notifyOfferAccepted(...);
      }
    } else {
      // Handle offer rejection
      Get.snackbar(
        'Offer Declined',
        'You have declined the offer. The sender will be notified.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      // Here you would typically call your backend to reject the offer
      // and notify the sender
      if (notification.data != null) {
        // Send notification to sender
        // await notificationService.notifyOfferRejected(...);
      }
    }

    // Mark the notification as read
    await NotificationService.instance.markAsRead(notification.id);
  }

  /// Navigate to trip detail page
  Future<void> _navigateToTripDetail(
      BuildContext context, String tripId) async {
    try {
      final tripRepository = TripRepository();
      final trip = await tripRepository.getTravelTrip(tripId);

      if (trip != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TripDetailScreen(trip: trip),
          ),
        );
      } else {
        Get.snackbar(
          'Error',
          'Trip not found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load trip details',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Navigate to package detail page
  Future<void> _navigateToPackageDetail(
      BuildContext context, String packageId) async {
    try {
      final packageRepository = PackageRepository();
      final package = await packageRepository.getPackageRequest(packageId);

      if (package != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PackageDetailScreen(package: package),
          ),
        );
      } else {
        Get.snackbar(
          'Error',
          'Package not found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load package details',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Navigate to opportunities screen (explore/browse)
  void _navigateToOpportunities(BuildContext context) {
    try {
      // Navigate to the main screen's explore tab
      // Assuming the app uses a bottom navigation setup
      Get.offAllNamed('/home', arguments: {'selectedIndex': 1}); // Explore tab
    } catch (e) {
      Get.snackbar(
        'Info',
        'Opportunities feature coming soon!',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    }
  }
}
