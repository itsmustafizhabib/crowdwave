import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../utils/toast_utils.dart';

class TestNotificationWidget extends StatelessWidget {
  const TestNotificationWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showTestNotificationDialog(context),
      backgroundColor: const Color(0xFF0046FF),
      foregroundColor: Colors.white,
      label: const Text('Test Notifications'),
      icon: const Icon(Icons.notifications_active),
    );
  }

  void _showTestNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Notifications'),
        content:
            const Text('Which type of notification would you like to test?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendTestTravellerNotification();
            },
            child: const Text('New Traveller'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendTestPackageNotification();
            },
            child: const Text('New Package'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendTestOpportunityNotification();
            },
            child: const Text('Opportunities'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _sendTestTravellerNotification() {
    final notificationService = Get.find<NotificationService>();

    notificationService.createNotification(
      userId: 'current_user_id', // You'd get this from auth service
      title: 'Dubai to Islamabad: New Traveller Alert!',
      body:
          'Send/Receive your packages now with our new traveller from Dubai to Islamabad. Place your bid now',
      type: NotificationType.general,
      data: {
        'type': 'new_traveller',
        'tripId': 'test_trip_123',
        'route': 'Dubai to Islamabad',
      },
    );

    ToastUtils.show(
      'Check your notifications to see the new traveller alert',
      title: 'Test Notification Sent!',
    );
  }

  void _sendTestPackageNotification() {
    final notificationService = Get.find<NotificationService>();

    notificationService.createNotification(
      userId: 'current_user_id', // You'd get this from auth service
      title: 'New Package Request in Your Area!',
      body:
          'Someone needs to send a package from Karachi to Lahore. Accept this delivery request now!',
      type: NotificationType.general,
      data: {
        'type': 'new_package',
        'packageId': 'test_package_456',
        'route': 'Karachi to Lahore',
      },
    );

    ToastUtils.show(
      'Check your notifications to see the new package request',
      title: 'Test Notification Sent!',
    );
  }

  void _sendTestOpportunityNotification() {
    final notificationService = Get.find<NotificationService>();

    notificationService.createNotification(
      userId: 'current_user_id', // You'd get this from auth service
      title: 'Opportunities in Your Area!',
      body:
          'Found 3 travellers and 2 package requests near you. Check them out!',
      type: NotificationType.general,
      data: {
        'type': 'nearby_opportunities',
        'nearbyTrips': 3,
        'nearbyPackages': 2,
      },
    );

    ToastUtils.show(
      'Check your notifications to see the opportunities summary',
      title: 'Test Notification Sent!',
    );
  }
}
