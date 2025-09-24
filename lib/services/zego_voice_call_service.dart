import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'notification_service.dart';

/// 🎤 ZegoExpressEngine Voice Call Service - Production Ready
/// Implements voice calling using ZegoExpressEngine following official documentation
class ZegoVoiceCallService {
  static final ZegoVoiceCallService _instance =
      ZegoVoiceCallService._internal();
  factory ZegoVoiceCallService() => _instance;
  ZegoVoiceCallService._internal();

  // 🔑 CONFIGURATION - Your existing Zego credentials from previous implementation
  // Get these from: https://console.zegocloud.com/project
  static const int appID = 4275795; // Your App ID
  static const String appSign =
      '6088393597dec53cd223179ed65a47e914615d3d2c3ac6323d4f40f81708c2c7'; // Your App Sign
  static const String serverSecret =
      'YOUR_SERVER_SECRET_HERE'; // For web platforms

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService.instance;

  bool _isEngineCreated = false;
  String? _currentRoomID;
  String? _publishStreamID;

  // Event stream controllers
  final StreamController<List<String>> _streamListController =
      StreamController<List<String>>.broadcast();
  final StreamController<ZegoRoomState> _roomStateController =
      StreamController<ZegoRoomState>.broadcast();
  final StreamController<List<ZegoUser>> _userListController =
      StreamController<List<ZegoUser>>.broadcast();

  // Getters
  bool get isEngineCreated => _isEngineCreated;
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentRoomID => _currentRoomID;

  // Event streams
  Stream<List<String>> get streamListStream => _streamListController.stream;
  Stream<ZegoRoomState> get roomStateStream => _roomStateController.stream;
  Stream<List<ZegoUser>> get userListStream => _userListController.stream;

  /// 🚀 Initialize ZegoExpressEngine
  Future<void> createEngine() async {
    if (_isEngineCreated) {
      if (kDebugMode) {
        print('✅ ZegoExpressEngine already created');
      }
      return;
    }

    try {
      WidgetsFlutterBinding.ensureInitialized();

      // Request permissions first
      await _requestPermissions();

      // ✅ FIX: Destroy any existing engine before creating new one
      try {
        await ZegoExpressEngine.destroyEngine();
        if (kDebugMode) {
          print('🧹 Destroyed any existing ZegoExpressEngine instance');
        }
      } catch (e) {
        // Ignore if no engine exists
        if (kDebugMode) {
          print('ℹ️ No existing engine to destroy (this is normal)');
        }
      }

      // Create engine with voice call scenario
      await ZegoExpressEngine.createEngineWithProfile(ZegoEngineProfile(
        appID,
        ZegoScenario.StandardVoiceCall,
        appSign: kIsWeb ? null : appSign,
      ));

      // Set up event handlers
      _setupEventHandlers();

      _isEngineCreated = true;

      if (kDebugMode) {
        print('✅ ZegoExpressEngine Voice Call Service Ready');
        print('🔑 AppID: $appID');
        print('🎯 User: ${_auth.currentUser?.displayName}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to create ZegoExpressEngine: $e');
      }
      _isEngineCreated = false; // Ensure flag is reset on failure
      rethrow;
    }
  }

  /// 🎯 Setup event handlers following Zego documentation
  void _setupEventHandlers() {
    // Callback for updates on the status of other users in the room
    ZegoExpressEngine.onRoomUserUpdate =
        (roomID, updateType, List<ZegoUser> userList) {
      if (kDebugMode) {
        print(
            'onRoomUserUpdate: roomID: $roomID, updateType: ${updateType.name}, userList: ${userList.map((e) => e.userID)}');
      }
      _userListController.add(userList);
    };

    // Callback for updates on the status of the streams in the room
    ZegoExpressEngine.onRoomStreamUpdate =
        (roomID, updateType, List<ZegoStream> streamList, extendedData) {
      if (kDebugMode) {
        print(
            'onRoomStreamUpdate: roomID: $roomID, updateType: $updateType, streamList: ${streamList.map((e) => e.streamID)}');
      }

      final streamIDs = streamList.map((e) => e.streamID).toList();
      _streamListController.add(streamIDs);

      if (updateType == ZegoUpdateType.Add) {
        for (final stream in streamList) {
          startPlayStream(stream.streamID);
        }
      } else {
        for (final stream in streamList) {
          stopPlayStream(stream.streamID);
        }
      }
    };

    // Callback for updates on the current user's room connection status
    ZegoExpressEngine.onRoomStateUpdate =
        (roomID, state, errorCode, extendedData) {
      if (kDebugMode) {
        print(
            'onRoomStateUpdate: roomID: $roomID, state: ${state.name}, errorCode: $errorCode');
      }
      _roomStateController.add(state);
    };

    // Callback for updates on the current user's stream publishing changes
    ZegoExpressEngine.onPublisherStateUpdate =
        (streamID, state, errorCode, extendedData) {
      if (kDebugMode) {
        print(
            'onPublisherStateUpdate: streamID: $streamID, state: ${state.name}, errorCode: $errorCode');
      }
    };
  }

  /// 🔐 Request necessary permissions
  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.phone, // For call interruption handling
    ].request();
  }

  /// 🏠 Login to voice call room with automatic logout from previous room
  Future<ZegoRoomLoginResult> loginRoom({
    required String roomID,
    required String userID,
    required String userName,
  }) async {
    if (!_isEngineCreated) {
      throw Exception(
          'ZegoExpressEngine not created. Call createEngine() first.');
    }

    try {
      // ✅ FIX: Logout from current room first to prevent 1002001 error
      if (_currentRoomID != null) {
        if (kDebugMode) {
          print('⚠️ Already in room $_currentRoomID, logging out first...');
        }
        await logoutRoom();

        // Small delay to ensure logout is complete
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final user = ZegoUser(userID, userName);

      // Enable user status notifications
      ZegoRoomConfig roomConfig = ZegoRoomConfig.defaultConfig()
        ..isUserStatusNotify = true;

      // For web platforms, generate token
      if (kIsWeb) {
        // Note: In production, tokens should be generated server-side
        // For now, skip token generation - implement server-side token generation
        // roomConfig.token = 'YOUR_TOKEN_FROM_SERVER';
        if (kDebugMode) {
          print(
              '⚠️ Web platform: Token generation should be implemented server-side');
        }
      }

      if (kDebugMode) {
        print('🚪 Attempting to login to room: $roomID');
        print('👤 User: $userID ($userName)');
      }

      // Login to room
      final loginResult = await ZegoExpressEngine.instance
          .loginRoom(roomID, user, config: roomConfig);

      if (kDebugMode) {
        print(
            'loginRoom: errorCode:${loginResult.errorCode}, extendedData:${loginResult.extendedData}');
      }

      if (loginResult.errorCode == 0) {
        _currentRoomID = roomID;
        if (kDebugMode) {
          print('✅ Successfully joined room: $roomID');
        }
        // Start publishing audio stream
        await startPublish(userID);
      } else {
        if (kDebugMode) {
          print('❌ Failed to join room: Error ${loginResult.errorCode}');
          if (loginResult.errorCode == 1002001) {
            print('💡 Error 1002001: Multiple room login attempted');
            print('💡 This usually means user is already in another room');
          }
        }
      }

      return loginResult;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Login room error: $e');
      }
      rethrow;
    }
  }

  /// 🚪 Logout from room
  Future<ZegoRoomLogoutResult> logoutRoom() async {
    if (_currentRoomID == null) return ZegoRoomLogoutResult(0, {});

    try {
      await stopPublish();
      final result =
          await ZegoExpressEngine.instance.logoutRoom(_currentRoomID!);
      _currentRoomID = null;
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Logout room error: $e');
      }
      rethrow;
    }
  }

  /// 📤 Start publishing audio stream
  Future<void> startPublish(String userID) async {
    if (_currentRoomID == null) return;

    try {
      // Create unique stream ID
      _publishStreamID = '${_currentRoomID}_${userID}_voice';

      // Disable camera for voice-only call
      await ZegoExpressEngine.instance.enableCamera(false);

      // Start publishing stream
      await ZegoExpressEngine.instance.startPublishingStream(_publishStreamID!);

      if (kDebugMode) {
        print('✅ Started publishing voice stream: $_publishStreamID');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Start publish error: $e');
      }
      rethrow;
    }
  }

  /// 📤 Stop publishing stream
  Future<void> stopPublish() async {
    try {
      await ZegoExpressEngine.instance.stopPublishingStream();
      _publishStreamID = null;

      if (kDebugMode) {
        print('🛑 Stopped publishing stream');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Stop publish error: $e');
      }
    }
  }

  /// 📥 Start playing remote stream
  Future<void> startPlayStream(String streamID) async {
    try {
      await ZegoExpressEngine.instance.startPlayingStream(streamID);

      if (kDebugMode) {
        print('▶️ Started playing stream: $streamID');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Start play stream error: $e');
      }
    }
  }

  /// 📥 Stop playing remote stream
  Future<void> stopPlayStream(String streamID) async {
    try {
      await ZegoExpressEngine.instance.stopPlayingStream(streamID);

      if (kDebugMode) {
        print('⏹️ Stopped playing stream: $streamID');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Stop play stream error: $e');
      }
    }
  }

  /// 🔇 Mute/unmute microphone
  Future<void> muteMicrophone(bool mute) async {
    try {
      await ZegoExpressEngine.instance.muteMicrophone(mute);

      if (kDebugMode) {
        print('🎤 Microphone ${mute ? 'muted' : 'unmuted'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mute microphone error: $e');
      }
    }
  }

  /// 🔊 Enable/disable speaker
  Future<void> enableSpeaker(bool enable) async {
    try {
      await ZegoExpressEngine.instance.setAudioRouteToSpeaker(enable);

      if (kDebugMode) {
        print('🔊 Speaker ${enable ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Enable speaker error: $e');
      }
    }
  }

  /// 📱 Start voice call
  Future<String> startVoiceCall({
    required String callID,
    required String receiverId,
    required String receiverName,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to make calls');
    }

    try {
      // Create unique room ID
      final roomID = 'voice_${callID}_${DateTime.now().millisecondsSinceEpoch}';

      // Send call notification to Firebase
      await _sendCallNotification(
        callType: 'voice',
        callID: roomID,
        receiverId: receiverId,
        receiverName: receiverName,
      );

      if (kDebugMode) {
        print('🎤 Voice call initiated: $roomID to $receiverName');
      }

      return roomID;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Voice call error: $e');
      }
      rethrow;
    }
  }

  /// 📧 Send call notification via Firebase
  Future<void> _sendCallNotification({
    required String callType,
    required String callID,
    required String receiverId,
    required String receiverName,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Save call notification to Firestore (for call history/logs)
      await _firestore.collection('call_notifications').add({
        'callType': callType,
        'callID': callID,
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Unknown',
        'receiverId': receiverId,
        'receiverName': receiverName,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'calling',
        'message': '${currentUser.displayName} is calling you...',
      });

      // 🔔 Send actual push notification to receiver's device
      await _notificationService.notifyIncomingVoiceCall(
        receiverId: receiverId,
        callerName: currentUser.displayName ?? 'Unknown User',
        callId: callID,
        roomId: callID, // Room ID is same as call ID
        callerId: currentUser.uid,
      );

      if (kDebugMode) {
        print('✅ Call notification sent successfully!');
        print('📞 From: ${currentUser.displayName}');
        print('📱 To: $receiverName');
        print('🎤 Room: $callID');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to send call notification: $e');
      }
    }
  }

  /// 🧹 Cleanup event handlers
  void stopListenEvent() {
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRoomStateUpdate = null;
    ZegoExpressEngine.onPublisherStateUpdate = null;
  }

  /// 🔥 Destroy engine and cleanup
  Future<void> destroyEngine() async {
    if (!_isEngineCreated) return;

    try {
      // ✅ FIX: Ensure we logout from any room before destroying engine
      if (_currentRoomID != null) {
        if (kDebugMode) {
          print(
              '🚪 Logging out from room before destroying engine: $_currentRoomID');
        }
        await logoutRoom();
      }

      stopListenEvent();
      await _streamListController.close();
      await _roomStateController.close();
      await _userListController.close();

      await ZegoExpressEngine.destroyEngine();
      _isEngineCreated = false;
      _currentRoomID = null;
      _publishStreamID = null;

      if (kDebugMode) {
        print('🔥 ZegoExpressEngine destroyed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Destroy engine error: $e');
      }
      // Force reset flags even on error
      _isEngineCreated = false;
      _currentRoomID = null;
      _publishStreamID = null;
    }
  }

  /// 🧹 Force cleanup room state (emergency use)
  Future<void> forceCleanupRoomState() async {
    try {
      if (kDebugMode) {
        print('🚨 Force cleanup: Resetting room state');
      }

      _currentRoomID = null;
      _publishStreamID = null;

      if (_isEngineCreated) {
        // Try to logout from any room
        try {
          await ZegoExpressEngine.instance.logoutRoom();
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Force cleanup logout error (ignored): $e');
          }
        }
      }

      if (kDebugMode) {
        print('✅ Force cleanup completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Force cleanup error: $e');
      }
    }
  }
}
