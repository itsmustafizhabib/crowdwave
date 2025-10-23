import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import '../../services/location_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final LocationBasedNotificationService _locationService =
      LocationBasedNotificationService();

  bool _locationNotificationsEnabled = true;
  double _notificationRadius = 50.0; // Default 50km radius
  bool _newTravellerAlerts = true;
  bool _newPackageAlerts = true;
  bool _opportunityAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'settings.notification_settings'.tr(),
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Location-based notifications
          _buildSectionCard(
            title: 'settings.location_based_notifications'.tr(),
            subtitle: 'settings.location_notifications_subtitle'.tr(),
            children: [
              _buildSwitchTile(
                title: 'settings.enable_location_notifications'.tr(),
                subtitle: 'settings.enable_location_subtitle'.tr(),
                value: _locationNotificationsEnabled,
                onChanged: (value) async {
                  if (value) {
                    // Show explanation dialog first
                    final shouldEnable = await _showLocationPermissionDialog();
                    if (shouldEnable) {
                      await _enableLocationNotifications();
                    }
                  } else {
                    _disableLocationNotifications();
                  }
                },
              ),
              if (_locationNotificationsEnabled) ...[
                const Divider(height: 1),

                // Notification radius
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${'settings.notification_radius'.tr()}: ${_notificationRadius.toInt()} km',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'settings.notification_radius_description'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Slider(
                        value: _notificationRadius,
                        min: 5.0,
                        max: 100.0,
                        divisions: 19,
                        activeColor: const Color(0xFF215C5C),
                        label: '${_notificationRadius.toInt()} km',
                        onChanged: (value) {
                          setState(() {
                            _notificationRadius = value;
                          });
                          _locationService.updateNotificationRadius(value);
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Specific alert types
                _buildSwitchTile(
                  title: 'settings.new_traveller_alerts'.tr(),
                  subtitle: 'settings.new_traveller_subtitle'.tr(),
                  value: _newTravellerAlerts,
                  onChanged: (value) {
                    setState(() {
                      _newTravellerAlerts = value;
                    });
                  },
                ),

                const Divider(height: 1),

                _buildSwitchTile(
                  title: 'settings.new_package_alerts'.tr(),
                  subtitle: 'settings.new_package_subtitle'.tr(),
                  value: _newPackageAlerts,
                  onChanged: (value) {
                    setState(() {
                      _newPackageAlerts = value;
                    });
                  },
                ),

                const Divider(height: 1),

                _buildSwitchTile(
                  title: 'settings.opportunity_alerts'.tr(),
                  subtitle: 'settings.opportunity_subtitle'.tr(),
                  value: _opportunityAlerts,
                  onChanged: (value) {
                    setState(() {
                      _opportunityAlerts = value;
                    });
                  },
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Manual refresh button
          _buildSectionCard(
            title: 'settings.manual_actions'.tr(),
            subtitle: 'settings.manual_actions_subtitle'.tr(),
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF215C5C).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: Color(0xFF215C5C),
                    size: 20,
                  ),
                ),
                title: Text('common.check_nearby_opportunities'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text('post_package.manually_scan_for_trips_and_packages_in_your_area'.tr(),
                  style: TextStyle(fontSize: 14),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _checkNearbyOpportunities(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF215C5C).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF215C5C).withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF215C5C),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text('common.how_it_works'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF215C5C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'We use your current location to find nearby travel opportunities. You\'ll receive notifications when:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Someone posts a new trip starting/ending near you\n'
                  '• Someone needs a package delivered in your area\n'
                  '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 14),
      ),
      value: value,
      activeThumbColor: const Color(0xFF215C5C),
      onChanged: onChanged,
    );
  }

  void _checkNearbyOpportunities() async {
    // Show loading indicator
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF215C5C)),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      await _locationService.refreshAndCheckNearbyOpportunities();

      // Close loading dialog
      Get.back();

      // Show success message
      Get.snackbar(
        'Opportunities Checked!',
        'We\'ve scanned your area for nearby trips and packages. Check your notifications for any new opportunities.',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      // Close loading dialog
      Get.back();

      // Show error message
      Get.snackbar(
        'Error',
        'Failed to check nearby opportunities. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Show dialog explaining why location permissions are needed
  Future<bool> _showLocationPermissionDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'settings.location_permission_required'.tr(),
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'settings.location_permission_explanation'.tr(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('settings.not_now'.tr()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF215C5C),
                  foregroundColor: Colors.white,
                ),
                child: Text('settings.enable'.tr()),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Enable location notifications with proper permission handling
  Future<void> _enableLocationNotifications() async {
    try {
      // Show loading
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF215C5C)),
          ),
        ),
        barrierDismissible: false,
      );

      // Request permissions and start notifications
      await _locationService.startLocationBasedNotifications(
          requestPermissions: true);

      // Close loading
      Get.back();

      setState(() {
        _locationNotificationsEnabled = true;
      });

      Get.snackbar(
        'Location Notifications Enabled!',
        'You\'ll now receive alerts about opportunities in your area.',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
    } catch (e) {
      // Close loading
      Get.back();

      Get.snackbar(
        'Permission Required',
        'Location access is needed to find opportunities near you. Please enable it in your device settings.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Disable location notifications
  void _disableLocationNotifications() {
    _locationService.stopLocationBasedNotifications();
    setState(() {
      _locationNotificationsEnabled = false;
    });

    Get.snackbar(
      'Location Notifications Disabled',
      'You won\'t receive alerts about nearby opportunities.',
      backgroundColor: Colors.grey,
      colorText: Colors.white,
    );
  }
}
