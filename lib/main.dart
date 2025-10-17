import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';

import '../core/app_export.dart';
import '../core/utils/status_bar_utils.dart';
import '../widgets/custom_error_widget.dart';
import '../widgets/auth_wrapper.dart';
import '../widgets/permission_initializer.dart';
import '../services/auth_state_service.dart';
import '../services/app_initialization_service.dart';
import '../services/onboarding_service.dart';
import '../services/notification_service.dart';
import '../services/presence_service.dart';
import '../services/location_service.dart';
import '../services/tracking_service.dart';
import '../services/memory_management_service.dart';
import '../services/zego_call_service.dart';
import '../services/permission_manager_service.dart';
import '../controllers/app_lifecycle_controller.dart';
import '../core/config/performance_config.dart';
import '../utils/black_screen_fix.dart';

// ✅ BACKGROUND MESSAGE HANDLER - Handle notifications when app is terminated/background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background message processing
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    print('🔔 BACKGROUND MESSAGE RECEIVED!');
    print('📧 Title: ${message.notification?.title}');
    print('💬 Body: ${message.notification?.body}');
    print('📊 Data: ${message.data}');
    print('🎯 Message ID: ${message.messageId}');
    print('📱 From: ${message.from}');
    print('⏰ Sent Time: ${message.sentTime}');
  }

  // ✅ CRITICAL FIX: Don't show background notifications for your own messages!
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final messageSenderId = message.data['senderId'] ?? message.data['sender_id'];

  if (currentUserId != null && messageSenderId == currentUserId) {
    if (kDebugMode) {
      print(
          '🚫 IGNORING background notification - message is from current user ($currentUserId)');
    }
    return; // Don't show any background notification for your own messages
  }

  // Handle different types of background notifications
  final type = message.data['type'];
  switch (type) {
    case 'chat_message':
      if (kDebugMode) {
        print('💬 Background chat message from: ${message.data['senderName']}');
      }
      break;
    case 'voice_call':
      if (kDebugMode) {
        print('📞 BACKGROUND VOICE CALL from: ${message.data['callerName']}');
        print('🎤 Call ID: ${message.data['callId']}');
        print('🏠 Room ID: ${message.data['roomId']}');
      }
      // Note: Background handler cannot show UI directly
      // The notification should trigger the app to open and handle the call
      break;
    default:
      if (kDebugMode) {
        print('📮 Background notification: ${message.notification?.title}');
      }
  }
}

// ✅ INITIALIZE CHAT SYSTEM ON APP STARTUP - Ensure real-time chat is ready immediately
Future<void> _initializeChatSystemOnStartup() async {
  try {
    if (kDebugMode) {
      print('🚀 STARTUP: Chat system initialization setup complete!');
      print(
          '💡 Chat will auto-initialize when user logs in via AuthStateService');
      print('✅ Real-time messaging will be active immediately on login');
    }

    // The AuthStateService already handles ChatController initialization
    // when it detects a logged-in user in its auth state listener.
    // This ensures chat is ready immediately on app startup for existing users
    // and on login for new users.

    // No additional code needed here - the auth service handles everything!
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error during startup chat initialization: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✨ DISABLE DEBUG OVERFLOW INDICATORS TO PREVENT YELLOW/BLACK LINES
  debugPaintSizeEnabled = false;

  // Hide overflow indicators in debug mode to prevent yellow/black lines
  if (kDebugMode) {
    // Override the default overflow indicator to be transparent
    RenderErrorBox.backgroundColor = Colors.transparent;
    // Note: textStyle requires dart:ui TextStyle, so we'll just make background transparent
  }

  try {
    // Initialize Firebase with latest pattern
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // ✅ REGISTER BACKGROUND MESSAGE HANDLER - Must be called immediately after Firebase init
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    if (kDebugMode) {
      print('🔔 Background message handler registered');
    }
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // Continue with app initialization even if Firebase fails
  }

  // Initialize app resources (animations, etc.)
  final appInitService = AppInitializationService();
  await appInitService.initialize();

  // Initialize onboarding service
  final onboardingService = OnboardingService();
  await onboardingService.initialize();

  // Initialize performance optimizations
  await PerformanceConfig.initialize();

  // 🔐 Initialize permission manager FIRST to coordinate all permissions
  final permissionManager = PermissionManagerService();
  await permissionManager.initialize();
  Get.put(permissionManager);

  // Initialize notification service (without automatic permission request)
  Get.put(NotificationService());

  // Initialize location service for smart caching
  final locationService = LocationService();
  await locationService.initialize();
  Get.put(locationService); // Put in GetX for dependency injection

  // Initialize tracking service (depends on location and notification services)
  Get.put(TrackingService());

  // 🎤 Initialize voice calling service (without automatic permission request)
  final zegoCallService = ZegoCallService();
  // Don't call initializeZego() here - we'll do it after permissions
  Get.put(zegoCallService);

  // 🧹 INITIALIZE MEMORY MANAGEMENT - Prevent memory leaks and black screens
  Get.put(MemoryManagementService());

  // Initialize presence service
  Get.put(PresenceService());

  // Initialize app lifecycle controller for presence management
  Get.put(AppLifecycleController());

  // 🚨 INITIALIZE BLACK SCREEN FIX - Prevent navigation black screens
  BlackScreenFix.initialize();

  // ✅ INITIALIZE CHAT SYSTEM FOR STARTUP - Ensure chat is ready immediately
  _initializeChatSystemOnStartup();

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(
      errorDetails: details,
      onRetry: () {
        // You can implement a global retry mechanism here
        print('Global retry attempted for: ${details.exception}');
      },
      retryText: 'Refresh',
    );
  };

  // 🚨 CONDITIONAL: Device orientation lock - ONLY for mobile platforms
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // 🎨 UNIVERSAL STATUS BAR: Apply solid blue background (matching home header) with white content
    StatusBarUtils.applyUniversalStatusBar();

    // Enable edge-to-edge experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthStateService(),
      child: Sizer(builder: (context, orientation, screenType) {
        return GetMaterialApp(
          title: 'CrowdWave',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY + UNIVERSAL STATUS BAR
          builder: (context, child) {
            // Apply universal solid blue status bar globally
            StatusBarUtils.applyUniversalStatusBar();

            return UniversalStatusBarWrapper(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(1.0),
                ),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  child: child!,
                ),
              ),
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          home: PermissionInitializer(
            child: AuthWrapper(),
          ),
          routes: AppRoutes.routes,
        );
      }),
    );
  }
}
