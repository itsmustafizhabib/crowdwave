import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';
import '../models/notification_model.dart';
import '../services/auth_state_service.dart';
import '../presentation/call/incoming_call_screen.dart';

// ✅ NOTIFICATION DISPLAY MODE - Controls where notifications appear
enum NotificationDisplayMode {
  systemOnly, // Only in Android notification area (like Gmail) - NEVER in-app
  inAppOnly, // Only as in-app overlays - NEVER in system notifications
  flexible, // Can show in-app when app is visible, system when not visible
}

class NotificationService extends GetxController {
  static NotificationService get instance => Get.find<NotificationService>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final AuthStateService _authService = AuthStateService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _notificationsCollection = 'notifications';

  // 🚫 Global switch to disable ALL in-app overlays for push notifications
  // When true, foreground FCM will NOT show any in-app snackbars/overlays.
  // Only system notifications (notification tray) will be shown.
  static const bool disableInAppNotifications =
      false; // ✅ FIXED: Enable for voice calls

  // ✅ NOTIFICATION DISPLAY CONFIGURATION
  // Control which notifications appear where - just like Gmail notifications!
  static const Map<String, NotificationDisplayMode> _notificationConfig = {
    // ❌ SYSTEM-ONLY: Never show as in-app overlays, only in Android notification area
    'offer_received': NotificationDisplayMode.systemOnly,
    'offer_accepted': NotificationDisplayMode.systemOnly,
    'offer_rejected': NotificationDisplayMode.systemOnly,
    'trip_update': NotificationDisplayMode.systemOnly,
    'package_update': NotificationDisplayMode.systemOnly,
    'general': NotificationDisplayMode.systemOnly,

    // 🔕 Messages should also be system-only to prevent in-app popups
    'message': NotificationDisplayMode.systemOnly,

    // � FIXED: Enable in-app call UI so incoming calls show properly
    'voice_call': NotificationDisplayMode.inAppOnly,
  };

  // Observable notifications
  final RxList<NotificationModel> _notifications = <NotificationModel>[].obs;
  final RxInt _unreadCount = 0.obs;

  // 🔒 Prevent duplicate voice call notifications
  final Set<String> _sentCallNotifications = <String>{};

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount.value;

  // 🐛 DEBUG FUNCTION - Call this to test FCM setup
  Future<void> debugFCMSetup() async {
    if (kDebugMode) {
      print('🐛 DEBUG FCM SETUP START');

      // Check FCM token
      final token = await _messaging.getToken();
      print('🔑 FCM Token: ${token?.substring(0, 20)}...');

      // Check user authentication
      final userId = _authService.currentUser?.uid;
      print('👤 User ID: $userId');

      // Check notification permissions
      final settings = await _messaging.getNotificationSettings();
      print('🔔 Notification Permission: ${settings.authorizationStatus}');

      // Check if token is saved in Firestore
      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final savedToken = userDoc.data()?['fcmToken'];
        print('💾 Saved Token: ${savedToken?.toString().substring(0, 20)}...');
        print('✅ Token Match: ${token == savedToken}');
      }

      print('🐛 DEBUG FCM SETUP END');
    }
  }

  // 🧪 DEBUG FUNCTION - Test notification display modes
  Future<void> debugNotificationDisplayModes() async {
    if (kDebugMode) {
      print('🧪 DEBUG NOTIFICATION DISPLAY MODES');
      print('📋 Current configuration:');

      _notificationConfig.forEach((type, mode) {
        final icon = mode == NotificationDisplayMode.systemOnly
            ? '🔔'
            : mode == NotificationDisplayMode.inAppOnly
                ? '📱'
                : '🔄';
        print('  $icon $type: $mode');
      });

      print('✅ System-only notifications (like Gmail):');
      _notificationConfig.forEach((type, mode) {
        if (mode == NotificationDisplayMode.systemOnly) {
          print('  🔔 $type - Will ONLY appear in Android notification area');
        }
      });

      print('📱 In-app eligible notifications:');
      _notificationConfig.forEach((type, mode) {
        if (mode == NotificationDisplayMode.flexible) {
          print('  🔄 $type - Can show in-app when visible, system when not');
        }
      });

      print('🎤 In-app only notifications:');
      _notificationConfig.forEach((type, mode) {
        if (mode == NotificationDisplayMode.inAppOnly) {
          print('  📱 $type - Only shows in-app (like voice calls)');
        }
      });

      print('🧪 DEBUG NOTIFICATION DISPLAY MODES END');
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _initializeLocalNotifications();
    // Don't automatically request permissions here - let PermissionManagerService handle it
    // await _requestNotificationPermissions();
    await _updateFCMToken();
    _listenToNotifications();
    _setupForegroundMessageHandler();
    _setupNotificationHandlers();
  }

  // ✅ INITIALIZE LOCAL NOTIFICATIONS - For system-level notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      if (kDebugMode) {
        print('🔔 Initializing local notifications...');
      }

      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Initialize the plugin
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (kDebugMode) {
        print('✅ Local notifications initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing local notifications: $e');
      }
    }
  }

  // ✅ HANDLE NOTIFICATION TAP - When user taps system notification
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    try {
      final payload = notificationResponse.payload;
      if (payload != null && payload.isNotEmpty) {
        // Parse payload as JSON and handle navigation
        final data = Map<String, dynamic>.from(
          Uri.splitQueryString(payload),
        );
        _handleNotificationTap(data);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling notification tap: $e');
      }
    }
  }

  Future<void> _requestNotificationPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print(
          'User granted notification permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> _updateFCMToken() async {
    try {
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) {
        if (kDebugMode) {
          print('❌ Cannot update FCM token - No authenticated user');
        }
        return;
      }

      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(currentUserId).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (kDebugMode) {
          print('✅ FCM token updated successfully!');
          print('👤 User ID: $currentUserId');
          print('🔑 Token: ${token.substring(0, 20)}...');
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to get FCM token - token is null');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating FCM token: $e');
      }
    }
  }

  void _listenToNotifications() {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      _notifications.value = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();

      _unreadCount.value = _notifications.where((n) => !n.isRead).length;
    });
  }

  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('🔔 FOREGROUND MESSAGE RECEIVED!');
        print('📧 Title: ${message.notification?.title}');
        print('💬 Body: ${message.notification?.body}');
        print('📊 Data: ${message.data}');
        print('🎯 Message ID: ${message.messageId}');
        print('📱 From: ${message.from}');
        print('⏰ Sent Time: ${message.sentTime}');

        // ✅ DEBUG: Print all data keys and values
        print('🔍 DEBUG: Checking notification data keys...');
        message.data.forEach((key, value) {
          print('  🔑 $key: $value (type: ${value.runtimeType})');
        });

        final notificationType = message.data['type'] ?? '';
        final displayMode = _notificationConfig[notificationType] ??
            NotificationDisplayMode.flexible;
        print('🔔 Notification type: "$notificationType"');
        print('📋 Display mode determined: $displayMode');
        print(
            '❌ Should be system-only: ${_isSystemOnlyNotification(notificationType)}');
      }

      // ✅ CRITICAL FIX: Don't show notifications for your own messages!
      final currentUserId = _authService.currentUser?.uid;
      final messageSenderId = message.data['senderId'] ??
          message.data['sender_id'] ??
          message.data['callerId'];

      if (kDebugMode) {
        print('🔍 SELF-NOTIFICATION CHECK:');
        print('  - Current user: $currentUserId');
        print('  - Message sender: $messageSenderId');
        print('  - Message type: ${message.data['type']}');
        print('  - Message content: ${message.data['body']}');
        print(
            '  - Is self-message: ${currentUserId != null && messageSenderId == currentUserId}');
      }

      if (currentUserId != null && messageSenderId == currentUserId) {
        if (kDebugMode) {
          print(
              '🚫 IGNORING notification - message is from current user ($currentUserId)');
        }
        return; // Don't show any notification for your own messages
      }

      // ✅ HANDLE BASED ON GLOBAL FLAG AND TYPE
      final isVoiceCall = message.data['type'] == 'voice_call';

      if (disableInAppNotifications) {
        // Always show as system notification in foreground
        if (kDebugMode) {
          print('🚫 In-app overlays disabled. Showing system notification.');
        }
        _showSystemNotification(message);
        return;
      }

      // If in-app notifications are enabled, handle voice calls specially
      if (isVoiceCall) {
        if (kDebugMode) {
          print('📞 VOICE CALL DETECTED - Processing immediately!');
        }
        _handleIncomingCallNotification(message);
        return;
      }

      // ✅ CHECK APP STATE AND SHOW APPROPRIATE NOTIFICATION
      _handleNotificationBasedOnAppState(message);
    });

    if (kDebugMode) {
      print('✅ Foreground message handler setup complete');
    }
  }

  // ✅ SHOW NOTIFICATION BASED ON APP STATE AND NOTIFICATION TYPE
  void _handleNotificationBasedOnAppState(RemoteMessage message) {
    // Global override: never show in-app overlays for push notifications
    if (disableInAppNotifications) {
      if (kDebugMode) {
        print(
            '🚫 In-app overlays disabled (global). Forcing system notification.');
      }
      _showSystemNotification(message);
      return;
    }

    // Check if app is in foreground and visible
    final appLifecycleState = WidgetsBinding.instance.lifecycleState;
    final isAppVisible = appLifecycleState == AppLifecycleState.resumed;

    // Get notification type from message data
    final notificationType = message.data['type'] ?? '';
    final displayMode = _notificationConfig[notificationType] ??
        NotificationDisplayMode.flexible;

    if (kDebugMode) {
      print('📱 App lifecycle state: $appLifecycleState');
      print('👀 Is app visible: $isAppVisible');
      print('🔔 Notification type: $notificationType');
      print('📋 Display mode: $displayMode');
    }

    // ✅ SYSTEM-ONLY NOTIFICATIONS - Always show in Android notification area, never in-app
    if (_isSystemOnlyNotification(notificationType)) {
      if (kDebugMode) {
        print(
            '🔔 SYSTEM-ONLY notification - Showing in Android notification area only (like Gmail)');
        print('❌ Will NEVER show as in-app overlay!');
      }
      _showSystemNotification(message);
      return;
    }

    // ✅ IN-APP ELIGIBLE NOTIFICATIONS - Can show in-app when app is visible
    if (isAppVisible) {
      // App is visible - show in-app notification banner for eligible types
      if (kDebugMode) {
        print(
            '🎨 Showing in-app notification (app is visible, type allows in-app display)');
      }
      _showInAppNotification(message);
    } else {
      // App is not visible - show system notification
      if (kDebugMode) {
        print('🔔 Showing system notification (app not visible)');
      }
      _showSystemNotification(message);
    }
  }

  // ✅ DETERMINE IF NOTIFICATION SHOULD ONLY SHOW IN SYSTEM NOTIFICATION AREA
  bool _isSystemOnlyNotification(String notificationType) {
    // Check configuration to see if this notification type should only appear
    // in Android notification area (like Gmail notifications) and NEVER as in-app overlays
    final displayMode = _notificationConfig[notificationType] ??
        NotificationDisplayMode.flexible;
    return displayMode == NotificationDisplayMode.systemOnly;
  }

  // ✅ SETUP NOTIFICATION HANDLERS - Handle app state transitions
  void _setupNotificationHandlers() {
    // Handle notification tap when app is terminated/background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('🎯 APP OPENED FROM NOTIFICATION TAP!');
        print('📊 Data: ${message.data}');
      }

      // ✅ CRITICAL FIX: Don't handle taps on your own message notifications
      final currentUserId = _authService.currentUser?.uid;
      final messageSenderId =
          message.data['senderId'] ?? message.data['sender_id'];

      if (kDebugMode) {
        print('🔍 NOTIFICATION TAP SELF-CHECK:');
        print('  - Current user: $currentUserId');
        print('  - Message sender: $messageSenderId');
        print('  - Message type: ${message.data['type']}');
        print('  - Message content: ${message.data['body']}');
        print(
            '  - Is self-message: ${currentUserId != null && messageSenderId == currentUserId}');
      }

      if (currentUserId != null && messageSenderId == currentUserId) {
        if (kDebugMode) {
          print(
              '🚫 IGNORING notification tap - message is from current user ($currentUserId)');
        }
        return; // Don't handle tap for your own messages
      }

      _handleNotificationTap(message.data);
    });

    // Handle notification tap when app is launched from terminated state
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('🚀 APP LAUNCHED FROM NOTIFICATION!');
          print('📊 Data: ${message.data}');
        }
        // Delay handling to ensure app is fully initialized
        Future.delayed(const Duration(seconds: 2), () {
          _handleNotificationTap(message.data);
        });
      }
    });

    if (kDebugMode) {
      print('✅ Notification handlers setup complete');
    }
  }

  // ✅ SHOW IN-APP NOTIFICATION BANNER - Like WhatsApp
  void _showInAppNotification(RemoteMessage message) {
    try {
      final notification = message.notification;
      if (notification == null) return;

      final title = notification.title ?? '';
      final body = notification.body ?? '';
      final data = message.data;

      if (kDebugMode) {
        print('🎨 SHOWING MINIMAL IN-APP TOAST...');
      }

      // Minimal, bottom-positioned, transparent toast-like snackbar
      final context = Get.context;
      final isDark =
          context != null && Theme.of(context).brightness == Brightness.dark;
      final textColor = isDark ? Colors.white : Colors.black87;
      Get.rawSnackbar(
        // No title, just minimal text
        messageText: Text(
          title.isNotEmpty ? '$title — $body' : body,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            shadows: const [
              Shadow(
                  offset: Offset(0, 0.5),
                  blurRadius: 0.5,
                  color: Colors.black26),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        borderRadius: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        isDismissible: true,
        dismissDirection: DismissDirection.down,
        forwardAnimationCurve: Curves.easeOutCubic,
        reverseAnimationCurve: Curves.easeInCubic,
        onTap: (_) {
          _handleNotificationTap(data);
        },
      );

      if (kDebugMode) {
        print('✅ Minimal in-app toast shown!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing in-app notification: $e');
      }
    }
  }

  // ✅ SHOW SYSTEM NOTIFICATION - For background/terminated app states
  Future<void> _showSystemNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      final title = notification.title ?? 'New Message';
      final body = notification.body ?? '';
      final data = message.data;
      final notificationType = data['type'] ?? '';

      if (kDebugMode) {
        print('🔔 SHOWING SYSTEM NOTIFICATION...');
        print('Title: $title');
        print('Body: $body');
        print('Type: $notificationType');
        print('📱 This will appear in Android notification area (like Gmail)');
      }

      // Create notification payload for navigation
      final payload = Uri(queryParameters: data).query;

      // ✅ SELECT APPROPRIATE NOTIFICATION CHANNEL BASED ON TYPE
      String channelId;
      String channelName;
      String channelDescription;

      switch (notificationType) {
        case 'offer_received':
        case 'offer_accepted':
        case 'offer_rejected':
          channelId = 'offers';
          channelName = 'Offers & Deals';
          channelDescription =
              'Notifications for price offers and deal updates';
          break;
        case 'trip_update':
        case 'package_update':
          channelId = 'trip_updates';
          channelName = 'Trip Updates';
          channelDescription = 'Updates about your trips and packages';
          break;
        case 'message':
          channelId = 'chat_messages';
          channelName = 'Chat Messages';
          channelDescription = 'New messages from other users';
          break;
        default:
          channelId = 'general';
          channelName = 'General Notifications';
          channelDescription = 'General app notifications';
          break;
      }

      // Android notification details
      final androidNotificationDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF215C5C), // Electric blue
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300, 100, 300]),
      );

      // iOS notification details
      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      // Combined notification details
      final notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      // Show the system notification
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      if (kDebugMode) {
        print(
            '✅ System notification shown successfully in Android notification area!');
        print('📱 Channel: $channelName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing system notification: $e');
      }
    }
  }

  // ✅ HANDLE INCOMING CALL NOTIFICATION IMMEDIATELY
  void _handleIncomingCallNotification(RemoteMessage message) {
    try {
      final data = message.data;
      final callId = data['callId'];
      final roomId = data['roomId'];
      final callerName = data['callerName'];
      final callerId = data['callerId'];
      final callerAvatar = data['callerAvatar'];

      if (callId != null && roomId != null && callerName != null) {
        if (kDebugMode) {
          print('📞 INCOMING CALL - Immediately showing call screen');
          print('🎤 Caller: $callerName');
          print('🆔 Call ID: $callId');
        }

        // Navigate directly to incoming call screen
        Get.to(
          () => IncomingCallScreen(
            callId: callId,
            roomId: roomId,
            callerName: callerName,
            callerId: callerId ?? 'unknown',
            callerAvatar: callerAvatar,
            notificationId: callId,
          ),
          fullscreenDialog: true,
          transition: Transition.downToUp,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling incoming call notification: $e');
      }
    }
  }

  // ✅ HANDLE NOTIFICATION TAP - Navigate to relevant screen
  void _handleNotificationTap(Map<String, dynamic> data) {
    try {
      final type = data['type'];

      if (kDebugMode) {
        print('🎯 NOTIFICATION TAPPED - Type: $type');
        print('📊 Data: $data');
      }

      switch (type) {
        case 'chat_message':
          final conversationId = data['conversationId'];
          final senderName = data['senderName'];
          final senderId = data['senderId'];

          if (conversationId != null) {
            // Navigate to individual chat screen
            Get.toNamed('/individual-chat', arguments: {
              'conversationId': conversationId,
              'otherUserName': senderName ?? 'User',
              'otherUserId': senderId ?? '',
            });
          }
          break;

        case 'deal_accepted':
          // Navigate to the specific chat conversation for this deal
          final conversationId = data['conversationId'];
          final dealId = data['dealId'];

          if (conversationId != null) {
            if (kDebugMode) {
              print('🎉 Deal accepted - navigating to chat: $conversationId');
            }
            Get.toNamed('/individual-chat', arguments: {
              'conversationId': conversationId,
              'dealId': dealId, // Include deal context
              'shouldRefresh': true, // Ensure chat refreshes
            });
          } else {
            // Fallback to notifications
            Get.toNamed('/notifications');
          }
          break;

        case 'offer_received':
        case 'offer_accepted':
        case 'offer_rejected':
          // Navigate to notifications screen to see offer details
          final packageId = data['packageId'];
          final tripId = data['tripId'];

          if (packageId != null) {
            // Navigate to package details with offers tab
            Get.toNamed('/package-details', arguments: {
              'packageId': packageId,
              'initialTab': 'offers',
            });
          } else if (tripId != null) {
            // Navigate to trip details
            Get.toNamed('/trip-details', arguments: {
              'tripId': tripId,
              'initialTab': 'offers',
            });
          } else {
            Get.toNamed('/notifications');
          }
          break;

        case 'voice_call':
          final callId = data['callId'];
          final roomId = data['roomId'];
          final callerName = data['callerName'];
          final callerId = data['callerId'];
          final callerAvatar = data['callerAvatar'];

          if (callId != null && roomId != null && callerName != null) {
            // Navigate to incoming call screen
            if (kDebugMode) {
              print('🎤 Incoming voice call: $callId from $callerName');
              print('🚀 Navigating to IncomingCallScreen...');
            }

            // Navigate to incoming call screen
            Get.to(
              () => IncomingCallScreen(
                callId: callId,
                roomId: roomId,
                callerName: callerName,
                callerId: callerId ?? 'unknown',
                callerAvatar: callerAvatar,
                notificationId: callId, // Use callId as notification ID
              ),
              fullscreenDialog: true,
              transition: Transition.downToUp,
            );
          }
          break;

        case 'trip_update':
        case 'package_update':
          // Navigate to tracking or package details
          final packageId = data['packageId'];
          final tripId = data['tripId'];

          if (packageId != null) {
            Get.toNamed('/package-details', arguments: {
              'packageId': packageId,
              'initialTab': 'tracking',
            });
          } else if (tripId != null) {
            Get.toNamed('/trip-details', arguments: {
              'tripId': tripId,
              'initialTab': 'tracking',
            });
          } else {
            Get.toNamed('/tracking');
          }
          break;

        default:
          // Navigate to general notifications screen
          Get.toNamed('/notifications');
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling notification tap: $e');
      }
      // Fallback - just navigate to notifications screen
      Get.toNamed('/notifications');
    }
  }

  // Create a new notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedEntityId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationId =
          _firestore.collection(_notificationsCollection).doc().id;

      final notification = NotificationModel(
        id: notificationId,
        userId: userId,
        title: title,
        body: body,
        type: type,
        relatedEntityId: relatedEntityId,
        data: data,
        createdAt: DateTime.now(),
      );

      if (kDebugMode) {
        print('💾 SAVING NOTIFICATION TO FIRESTORE:');
        print('  📄 Collection: $_notificationsCollection');
        print('  🆔 Document ID: $notificationId');
        print('  👤 User ID: $userId');
        print('  📧 Title: $title');
        print('  📝 Body: $body');
        print('  🏷️ Type: ${type.name}');
        print('  🔗 Related Entity: $relatedEntityId');
      }

      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .set(notification.toMap());

      if (kDebugMode) {
        print('✅ Notification saved to Firestore successfully!');
        print('🔔 Path: notifications/$notificationId');
      }

      // Send push notification
      await _sendPushNotification(
        userId: userId,
        title: title,
        body: body,
        data: data ?? {},
      );

      if (kDebugMode) {
        print('📱 Push notification sent to user $userId');
        print('🎯 Notification complete: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating notification: $e');
        print('Stack trace: ${StackTrace.current}');
      }
    }
  }

  // Send push notification
  Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken == null) {
        // Token not found - skip notification
        return;
      }

      // Send push notification via Firebase Functions
      await _sendPushNotificationViaBackend(fcmToken, title, body, data);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending push notification: $e');
      }
    }
  }

  /// Send push notification via Firebase Functions backend
  Future<void> _sendPushNotificationViaBackend(
    String fcmToken,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      // We could use Firebase Functions here, but for now let's use direct FCM
      // This would normally be done via a secure backend to protect FCM server key

      // For development/testing, we'll use Firebase Messaging directly
      // In production, this should go through your secure backend
      await _sendDirectFCMNotification(fcmToken, title, body, data);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending push notification via backend: $e');
      }
      rethrow;
    }
  }

  /// Send FCM notification using Firebase HTTP v1 API (modern, recommended)
  Future<void> _sendDirectFCMNotification(
    String fcmToken,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      if (kDebugMode) {
        print('🚀 Sending FCM notification via Cloud Functions...');
        print('📱 Token: ${fcmToken.substring(0, 20)}...');
        print('📝 Title: $title');
        print('📝 Body: $body');
        print('📦 Data: $data');
      }

      // ✅ ADD UNIQUE NOTIFICATION ID to prevent duplicates
      final notificationId = data['notificationId'] ??
          '${data['type'] ?? 'general'}_${data['conversationId'] ?? data['dealId'] ?? data['packageId'] ?? 'none'}_${DateTime.now().millisecondsSinceEpoch}';

      final enhancedData = Map<String, dynamic>.from(data);
      enhancedData['notificationId'] = notificationId;
      enhancedData['clickAction'] = 'FLUTTER_NOTIFICATION_CLICK';

      // Use Firebase Cloud Functions for reliable FCM sending
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendFCMNotification');

      final result = await callable.call({
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'data': enhancedData,
      });

      if (kDebugMode) {
        print('✅ FCM notification sent successfully via Cloud Functions!');
        print('📊 Result: ${result.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to send FCM notification via Cloud Functions: $e');
        print('🔍 Error details: ${e.toString()}');
        print('🔍 Error type: ${e.runtimeType}');
      }

      // 🚨 FALLBACK: Try alternative notification method
      if (kDebugMode) {
        print('🔄 Attempting fallback notification method...');
      }

      try {
        // Create Firestore notification as backup
        await createNotification(
          userId: data['callerId'] ?? 'unknown',
          title: title,
          body: body,
          type: NotificationType.general,
          data: data,
        );

        if (kDebugMode) {
          print('✅ Fallback Firestore notification created successfully');
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          print('❌ Fallback notification also failed: $fallbackError');
        }
      }

      rethrow;
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) return;

      final unreadNotifications = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
    }
  }

  // Notification for offer received
  Future<void> notifyOfferReceived({
    required String travelerId,
    required String senderName,
    required String tripTitle,
    required String tripId,
    required double offerAmount,
  }) async {
    await createNotification(
      userId: travelerId,
      title: 'notifications.new_offer'.tr(),
      body:
          '$senderName made an offer of \$${offerAmount.toStringAsFixed(2)} for your trip to $tripTitle',
      type: NotificationType.offerReceived,
      relatedEntityId: tripId,
      data: {
        'tripId': tripId,
        'senderName': senderName,
        'offerAmount': offerAmount,
        'type': 'offer_received',
      },
    );
  }

  // Notification for offer accepted
  Future<void> notifyOfferAccepted({
    required String senderId,
    required String travelerName,
    required String tripTitle,
    required String tripId,
  }) async {
    await createNotification(
      userId: senderId,
      title: 'Offer Accepted! 🎉',
      body: '$travelerName accepted your offer for the trip to $tripTitle',
      type: NotificationType.offerAccepted,
      relatedEntityId: tripId,
      data: {
        'tripId': tripId,
        'travelerName': travelerName,
        'type': 'offer_accepted',
      },
    );
  }

  // Notification for offer rejected
  Future<void> notifyOfferRejected({
    required String senderId,
    required String travelerName,
    required String tripTitle,
    required String tripId,
  }) async {
    await createNotification(
      userId: senderId,
      title: 'notifications.offer_update'.tr(),
      body: '$travelerName declined your offer for the trip to $tripTitle',
      type: NotificationType.offerRejected,
      relatedEntityId: tripId,
      data: {
        'tripId': tripId,
        'travelerName': travelerName,
        'type': 'offer_rejected',
      },
    );
  }

  // 🎤 Notification for incoming voice call - ENHANCED with direct FCM
  Future<void> notifyIncomingVoiceCall({
    required String receiverId,
    required String callerName,
    required String callId,
    required String roomId,
    String? callerId,
    String? callerAvatar,
  }) async {
    // 🔒 Prevent duplicate notifications for the same call
    final notificationKey = '${callId}_${receiverId}';
    if (_sentCallNotifications.contains(notificationKey)) {
      if (kDebugMode) {
        print('🚫 Duplicate call notification prevented: $callId');
      }
      return;
    }

    // Mark this notification as sent
    _sentCallNotifications.add(notificationKey);

    // Clean up old notifications after 5 minutes to prevent memory leaks
    Future.delayed(Duration(minutes: 5), () {
      _sentCallNotifications.remove(notificationKey);
    });

    try {
      if (kDebugMode) {
        print('🎤 SENDING VOICE CALL NOTIFICATION...');
        print('📞 Caller: $callerName');
        print('🆔 Call ID: $callId');
        print('👤 Receiver: $receiverId');
      }

      // 📱 Get receiver's FCM token directly (same as chat service)
      final userDoc =
          await _firestore.collection('users').doc(receiverId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken == null || fcmToken.isEmpty) {
        if (kDebugMode) {
          print('❌ No FCM token found for user: $receiverId');
          print('💡 User might not have push notifications enabled');
        }
      } else {
        if (kDebugMode) {
          print(
              '✅ FCM token found for receiver: ${fcmToken.substring(0, 20)}...');
        }

        // 🚀 Send FCM notification directly (EXACTLY like chat service)
        await _sendDirectFCMNotification(
          fcmToken,
          '📞 Incoming Call',
          '$callerName is calling you...',
          {
            'callId': callId,
            'roomId': roomId,
            'callerName': callerName,
            'callerId': callerId ?? 'unknown',
            'callerAvatar': callerAvatar,
            'type': 'voice_call',
            'action': 'incoming_call',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        );
      }

      // 📝 Also create Firestore notification for history (but skip FCM since we already sent it)
      final notificationId =
          _firestore.collection(_notificationsCollection).doc().id;
      final notification = NotificationModel(
        id: notificationId,
        userId: receiverId,
        title: 'notifications.incoming_call'.tr(),
        body: '$callerName is calling you...',
        type: NotificationType.voiceCall,
        relatedEntityId: callId,
        data: {
          'callId': callId,
          'roomId': roomId,
          'callerName': callerName,
          'callerId': callerId ?? 'unknown',
          'callerAvatar': callerAvatar,
          'type': 'voice_call',
          'action': 'incoming_call',
        },
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .set(notification.toMap());

      if (kDebugMode) {
        print('✅ Voice call notification sent successfully: $callId');
        print('🎯 Both FCM push and Firestore notification created!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending voice call notification: $e');
      }
    }
  }
}
