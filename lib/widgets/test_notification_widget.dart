import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../utils/toast_utils.dart';

class TestNotificationWidget extends StatelessWidget {
  const TestNotificationWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showTestNotificationDialog(context),
      backgroundColor: const Color(0xFF215C5C),
      foregroundColor: Colors.white,
      label: Text('debug.test_notifications'.tr()),
      icon: const Icon(Icons.notifications_active),
    );
  }

  void _showTestNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('debug.test_notifications'.tr()),
        content: Text('debug.test_notification_prompt'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendTestTravellerNotification();
            },
            child: Text('debug.new_traveller'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendTestPackageNotification();
            },
            child: Text('debug.new_package'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendTestOpportunityNotification();
            },
            child: Text('debug.opportunities'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _sendTestTravellerNotification() {
    final notificationService = Get.find<NotificationService>();

    notificationService.createNotification(
      userId: 'current_user_id', // You'd get this from auth service
      title: 'debug.test_traveller_title'.tr(),
      body: 'debug.test_traveller_body'.tr(),
      type: NotificationType.general,
      data: {
        'type': 'new_traveller',
        'tripId': 'test_trip_123',
        'route': 'Dubai to Islamabad',
      },
    );

    ToastUtils.show(
      'debug.test_notification_check'.tr(),
      title: 'debug.test_notification_sent'.tr(),
    );
  }

  void _sendTestPackageNotification() {
    final notificationService = Get.find<NotificationService>();

    notificationService.createNotification(
      userId: 'current_user_id', // You'd get this from auth service
      title: 'debug.test_package_title'.tr(),
      body: 'debug.test_package_body'.tr(),
      type: NotificationType.general,
      data: {
        'type': 'new_package',
        'packageId': 'test_package_456',
        'route': 'Karachi to Lahore',
      },
    );

    ToastUtils.show(
      'debug.test_package_check'.tr(),
      title: 'debug.test_notification_sent'.tr(),
    );
  }

  void _sendTestOpportunityNotification() {
    final notificationService = Get.find<NotificationService>();

    notificationService.createNotification(
      userId: 'current_user_id', // You'd get this from auth service
      title: 'debug.test_opportunity_title'.tr(),
      body: 'debug.test_opportunity_body'.tr(),
      type: NotificationType.general,
      data: {
        'type': 'nearby_opportunities',
        'nearbyTrips': 3,
        'nearbyPackages': 2,
      },
    );

    ToastUtils.show(
      'debug.test_opportunity_check'.tr(),
      title: 'debug.test_notification_sent'.tr(),
    );
  }
}
