import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../presentation/tracking/package_tracking_screen.dart';
import '../presentation/tracking/tracking_status_update_screen.dart';
import '../core/models/delivery_tracking.dart';

class TrackingRouteHandler {
  /// Navigate to package tracking screen
  static void navigateToPackageTracking({
    required String trackingId,
    String? packageRequestId,
  }) {
    Get.to(
      () => PackageTrackingScreen(
        trackingId: trackingId,
        packageRequestId: packageRequestId,
      ),
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// Navigate to status update screen
  static void navigateToStatusUpdate({
    required String trackingId,
    required DeliveryTracking tracking,
  }) {
    Get.to(
      () => TrackingStatusUpdateScreen(
        trackingId: trackingId,
        tracking: tracking,
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// Navigate to tracking screen from booking completion
  static void navigateFromBookingToTracking({
    required String trackingId,
    String? packageRequestId,
  }) {
    // Replace current screen with tracking screen
    Get.off(
      () => PackageTrackingScreen(
        trackingId: trackingId,
        packageRequestId: packageRequestId,
      ),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 500),
    );
  }

  /// Show tracking quick view modal
  static void showTrackingQuickView({
    required BuildContext context,
    required String trackingId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: PackageTrackingScreen(
            trackingId: trackingId,
            packageRequestId: null,
          ),
        ),
      ),
    );
  }

  /// Generate tracking URL for sharing
  static String generateTrackingUrl(String trackingId) {
    // In production, this would be your app's deep link URL
    return 'https://crowdwave.app/tracking/$trackingId';
  }

  /// Handle tracking deep links
  static void handleTrackingDeepLink(String url) {
    // Parse tracking ID from URL and navigate
    final trackingId = url.split('/').last;
    if (trackingId.isNotEmpty) {
      navigateToPackageTracking(trackingId: trackingId);
    }
  }
}
