import 'package:get/get.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/tracking_service.dart';
import '../services/presence_service.dart';
import '../services/geocoding_service.dart';
import '../controllers/app_lifecycle_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/smart_matching_controller.dart';
import '../services/memory_management_service.dart';
import '../services/zego_call_service.dart';

/// ServiceManager handles initialization and cleanup of core services
/// This ensures services are properly registered after login and cleaned up on logout
class ServiceManager {
  static final ServiceManager _instance = ServiceManager._internal();
  factory ServiceManager() => _instance;
  ServiceManager._internal();

  /// Initialize core services that are needed for the app to function
  /// This should be called after successful login
  static Future<void> initializeCoreServices() async {
    print('🔧 ServiceManager: Initializing core services...');

    try {
      // Only initialize if not already registered
      if (!Get.isRegistered<LocationService>()) {
        final locationService = LocationService();
        await locationService.initialize();
        Get.put(locationService);
        print('✅ LocationService initialized and registered');
      }

      if (!Get.isRegistered<NotificationService>()) {
        Get.put(NotificationService());
        print('✅ NotificationService registered');
      }

      if (!Get.isRegistered<TrackingService>()) {
        Get.put(TrackingService());
        print('✅ TrackingService registered');
      }

      if (!Get.isRegistered<PresenceService>()) {
        Get.put(PresenceService());
        print('✅ PresenceService registered');
      }

      if (!Get.isRegistered<AppLifecycleController>()) {
        Get.put(AppLifecycleController());
        print('✅ AppLifecycleController registered');
      }

      if (!Get.isRegistered<MemoryManagementService>()) {
        Get.put(MemoryManagementService());
        print('✅ MemoryManagementService registered');
      }

      if (!Get.isRegistered<ZegoCallService>()) {
        final zegoCallService = ZegoCallService();
        Get.put(zegoCallService);
        print('✅ ZegoCallService registered');
      }

      if (!Get.isRegistered<GeocodingService>()) {
        Get.put(GeocodingService());
        print('✅ GeocodingService registered');
      }

      print('✅ ServiceManager: All core services initialized successfully');
    } catch (e) {
      print('❌ ServiceManager: Error initializing core services: $e');
      rethrow;
    }
  }

  /// Check if all required services are registered
  /// Returns true if all services are available, false otherwise
  static bool areServicesAvailable() {
    try {
      final servicesChecks = [
        Get.isRegistered<LocationService>(),
        Get.isRegistered<NotificationService>(),
        Get.isRegistered<TrackingService>(),
        Get.isRegistered<PresenceService>(),
        Get.isRegistered<AppLifecycleController>(),
        Get.isRegistered<MemoryManagementService>(),
        Get.isRegistered<ZegoCallService>(),
        Get.isRegistered<GeocodingService>(),
      ];

      final allAvailable = servicesChecks.every((check) => check);

      if (!allAvailable) {
        print('⚠️ ServiceManager: Some services are missing');
      }

      return allAvailable;
    } catch (e) {
      print('⚠️ ServiceManager: Error checking services availability: $e');
      return false;
    }
  }

  /// Clean up services on logout
  /// This preserves essential services while cleaning user-specific ones
  static void cleanupUserServices() {
    print('🧹 ServiceManager: Cleaning up user-specific services...');

    try {
      // Only clean up user-specific controllers, preserve core services
      if (Get.isRegistered<ChatController>()) {
        final chatController = Get.find<ChatController>();
        chatController.cleanupOnLogout(); // Clean user data first
        Get.delete<ChatController>(force: true);
        print('✅ Cleaned up: ChatController');
      }

      if (Get.isRegistered<SmartMatchingController>()) {
        Get.delete<SmartMatchingController>(force: true);
        print('✅ Cleaned up: SmartMatchingController');
      }

      print('✅ ServiceManager: User service cleanup completed');
    } catch (e) {
      print('❌ ServiceManager: Error during cleanup: $e');
    }
  }
}
