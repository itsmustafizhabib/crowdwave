import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/auth_state_service.dart';
import '../../core/repositories/trip_repository.dart';
import '../../core/repositories/package_repository.dart';
import '../trip_detail/trip_detail_screen.dart';
import '../package_detail/package_detail_screen.dart';
import '../chat/individual_chat_screen.dart';
import '../../widgets/liquid_refresh_indicator.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationService = Get.find<NotificationService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('notifications.title'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white, // Make title text white
          ),
        ),
        backgroundColor: const Color(0xFF215C5C),
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
                    child: Text('common.mark_all_read'.tr(),
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
              color: const Color(0xFF215C5C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 60,
              color: Color(0xFF215C5C),
            ),
          ),
          const SizedBox(height: 24),
          Text('notifications.no_notifications'.tr(),
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
                  color: Color(0xFF215C5C),
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
                  : const Color(0xFF215C5C).withOpacity(0.02),
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
                                color: Color(0xFF215C5C),
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
                          // Removed action buttons - tap notification to open chat
                          if (notification.type ==
                              NotificationType.offerReceived)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF215C5C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('common.tap_to_view_offer'.tr(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF215C5C),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
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
        return const Color(0xFF215C5C);
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
          backgroundColor: const Color(0xFF215C5C),
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
        case NotificationType.offerAccepted:
        case NotificationType.offerRejected:
          // Navigate to chat where the offer is located
          await _navigateToOfferChat(context, notification);
          break;
        case NotificationType.tripUpdate:
          // Navigate to trip detail
          await _navigateToTripDetail(context, notification.relatedEntityId!);
          break;
        case NotificationType.packageUpdate:
          // Navigate to package detail
          await _navigateToPackageDetail(
              context, notification.relatedEntityId!);
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

  /// Navigate to chat screen where the offer can be accepted/rejected
  Future<void> _navigateToOfferChat(
      BuildContext context, NotificationModel notification) async {
    try {
      final authService = AuthStateService();
      final currentUserId = authService.currentUser?.uid;

      if (currentUserId == null) {
        Get.snackbar(
          'Error',
          'Please log in to view offers',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Get data from notification
      final packageId = notification.data?['packageId'];
      final dealId = notification.data?['dealId'];

      if (packageId == null) {
        Get.snackbar(
          'Error',
          'Package information not found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Get package data to find conversation
      final packageDoc = await FirebaseFirestore.instance
          .collection('packageRequests')
          .doc(packageId)
          .get();

      if (!packageDoc.exists) {
        Get.snackbar(
          'Error',
          'Package not found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final packageData = packageDoc.data()!;
      final senderId = packageData['senderId'];

      // Get deal to find the traveler and conversation
      if (dealId != null) {
        final dealDoc = await FirebaseFirestore.instance
            .collection('deals')
            .doc(dealId)
            .get();

        if (dealDoc.exists) {
          final dealData = dealDoc.data()!;
          final conversationId = dealData['conversationId'];
          final travelerId = dealData['travelerId'];

          // Determine the other user (who to chat with)
          final otherUserId = currentUserId == senderId ? travelerId : senderId;

          // Get other user's data
          final otherUserDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .get();

          final otherUserName = otherUserDoc.exists
              ? (otherUserDoc.data()?['displayName'] ?? 'User')
              : 'User';
          final otherUserAvatar = otherUserDoc.data()?['photoURL'] as String?;

          // Navigate to chat
          Get.to(() => IndividualChatScreen(
                conversationId: conversationId,
                otherUserName: otherUserName,
                otherUserId: otherUserId,
                otherUserAvatar: otherUserAvatar,
              ));

          // Show guidance snackbar
          Future.delayed(const Duration(milliseconds: 500), () {
            Get.snackbar(
              'Offer in Chat',
              'You can accept or decline the offer in the chat conversation',
              backgroundColor: const Color(0xFF215C5C),
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          });
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open chat: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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
        backgroundColor: Color(0xFF008080),
        colorText: Colors.white,
      );
    }
  }
}
