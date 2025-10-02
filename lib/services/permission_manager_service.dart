import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

/// Service to handle all app permissions in a coordinated way
/// This prevents multiple simultaneous permission requests that can cause white screens
class PermissionManagerService extends GetxController {
  static PermissionManagerService get instance =>
      Get.find<PermissionManagerService>();

  bool _isInitialized = false;
  bool _hasRequestedInitialPermissions = false;

  /// Initialize permission manager - call this early in app startup
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🔐 PermissionManagerService: Initializing...');
    _isInitialized = true;
  }

  /// Request all essential permissions in sequence (not simultaneously)
  /// This prevents the white screen issue caused by multiple permission dialogs
  Future<void> requestEssentialPermissions() async {
    if (_hasRequestedInitialPermissions) {
      print('🔐 Essential permissions already requested');
      return;
    }

    try {
      print('🔐 Requesting essential permissions in sequence...');

      // Request permissions one by one to avoid conflicts
      await _requestNotificationPermission();
      await Future.delayed(const Duration(milliseconds: 500));

      await _requestLocationPermissions();
      await Future.delayed(const Duration(milliseconds: 500));

      await _requestMicrophonePermission();

      _hasRequestedInitialPermissions = true;
      print('✅ All essential permissions requested');
    } catch (e) {
      print('❌ Error requesting essential permissions: $e');
    }
  }

  /// Request notification permission
  Future<PermissionStatus> _requestNotificationPermission() async {
    try {
      print('🔔 Requesting notification permission...');
      final status = await Permission.notification.request();
      print('🔔 Notification permission: $status');
      return status;
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Request location permissions
  Future<void> _requestLocationPermissions() async {
    try {
      print('📍 Requesting location permissions...');

      // First request basic location permission
      final locationStatus = await Permission.location.request();
      print('📍 Location permission: $locationStatus');

      // If granted, request background location (for delivery tracking)
      if (locationStatus == PermissionStatus.granted) {
        final backgroundStatus = await Permission.locationAlways.request();
        print('📍 Background location permission: $backgroundStatus');
      }
    } catch (e) {
      print('❌ Error requesting location permissions: $e');
    }
  }

  /// Request microphone permission (for voice calls)
  Future<PermissionStatus> _requestMicrophonePermission() async {
    try {
      print('🎤 Requesting microphone permission...');
      final status = await Permission.microphone.request();
      print('🎤 Microphone permission: $status');
      return status;
    } catch (e) {
      print('❌ Error requesting microphone permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Check if all essential permissions are granted
  Future<bool> hasEssentialPermissions() async {
    try {
      final notification = await Permission.notification.status;
      final location = await Permission.location.status;
      final microphone = await Permission.microphone.status;

      return notification.isGranted &&
          location.isGranted &&
          microphone.isGranted;
    } catch (e) {
      print('❌ Error checking permissions: $e');
      return false;
    }
  }

  /// Open app settings if permissions are permanently denied
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
