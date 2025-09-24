import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        title: const Text(
          'Notification Settings',
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Location-based notifications
          _buildSectionCard(
            title: 'Location-Based Notifications',
            subtitle: 'Get notified about opportunities in your area',
            children: [
              _buildSwitchTile(
                title: 'Enable Location Notifications',
                subtitle: 'Receive alerts for nearby trips and packages',
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
                        'Notification Radius: ${_notificationRadius.toInt()} km',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Receive notifications for opportunities within this distance',
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
                        activeColor: const Color(0xFF0046FF),
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
                  title: 'New Traveller Alerts',
                  subtitle: 'When someone posts a new trip in your area',
                  value: _newTravellerAlerts,
                  onChanged: (value) {
                    setState(() {
                      _newTravellerAlerts = value;
                    });
                  },
                ),

                const Divider(height: 1),

                _buildSwitchTile(
                  title: 'New Package Alerts',
                  subtitle:
                      'When someone needs a package delivered in your area',
                  value: _newPackageAlerts,
                  onChanged: (value) {
                    setState(() {
                      _newPackageAlerts = value;
                    });
                  },
                ),

                const Divider(height: 1),

                _buildSwitchTile(
                  title: 'Opportunity Summary',
                  subtitle: 'Daily summary of nearby opportunities',
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
            title: 'Manual Actions',
            subtitle: 'Check for opportunities manually',
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0046FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: Color(0xFF0046FF),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Check Nearby Opportunities',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                subtitle: const Text(
                  'Manually scan for trips and packages in your area',
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
              color: const Color(0xFF0046FF).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0046FF).withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF0046FF),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'How it works',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF0046FF),
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
      activeThumbColor: const Color(0xFF0046FF),
      onChanged: onChanged,
    );
  }

  void _checkNearbyOpportunities() async {
    // Show loading indicator
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0046FF)),
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
            title: const Text(
              'Location Permission Required',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            content: const Text(
              'CrowdWave needs access to your location to:\n\n'
              '• Find trips and packages near you\n'
              '• Send notifications about nearby opportunities\n'
              '• Help you discover earning opportunities in your area\n\n'
              'Your location is only used for finding relevant opportunities and is not shared with other users.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0046FF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Allow Location'),
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0046FF)),
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
