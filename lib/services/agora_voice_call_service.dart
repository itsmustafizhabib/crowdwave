import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'notification_service.dart';

/// 🎤 Agora Voice Call Service
/// Free tier: 10,000 minutes/month FOREVER!
class AgoraVoiceCallService {
  static final AgoraVoiceCallService _instance =
      AgoraVoiceCallService._internal();
  factory AgoraVoiceCallService() => _instance;
  AgoraVoiceCallService._internal();

  // 🔑 AGORA CONFIGURATION
  static const String appId = 'db2ca44a159b4e079483a662e32777e5';

  // 🔐 APP CERTIFICATE (Get from Agora Console > Project Management > Config)
  // ⚠️ IMPORTANT: In production, generate tokens on your backend server
  static const String appCertificate = 'e7a1b5ba363d4519bf6fa9e4853aec78';
  // Token authentication now enabled for secure calls!

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final NotificationService _notificationService = NotificationService.instance;

  RtcEngine? _engine;
  bool _isEngineInitialized = false;
  String? _currentChannelName;
  int? _currentUid;

  // Getters
  bool get isEngineInitialized => _isEngineInitialized;
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentChannelName => _currentChannelName;

  /// 🚀 Initialize Agora Engine
  Future<void> createEngine() async {
    if (_isEngineInitialized && _engine != null) {
      if (kDebugMode) {
        print('✅ Agora Engine already initialized');
      }
      return;
    }

    try {
      // Request permissions
      await _requestPermissions();

      // Create Agora engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        audioScenario: AudioScenarioType.audioScenarioDefault,
      ));

      // Set up event handlers
      _setupEventHandlers();

      // Enable audio (disable video for voice-only calls)
      await _engine!.enableAudio();
      await _engine!.disableVideo();

      // 🎵 Enable built-in audio processing for better quality
      await _engine!.setParameters('{"che.audio.enable.aec":true}');
      await _engine!.setParameters('{"che.audio.enable.agc":true}');
      await _engine!.setParameters('{"che.audio.enable.ns":true}');

      _isEngineInitialized = true;

      if (kDebugMode) {
        print('✅ Agora Voice Call Service Ready');
        print('🔑 App ID: $appId');
        print('🎵 Audio processing: AEC, AGC, NS enabled');
        print('📱 Free tier: 10,000 minutes/month forever!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Agora Engine: $e');
      }
      rethrow;
    }
  }

  /// 🔐 Request necessary permissions
  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
    ].request();
  }

  /// 📡 Set up event handlers
  void _setupEventHandlers() {
    if (_engine == null) return;

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onError: (ErrorCodeType err, String msg) {
          if (kDebugMode) {
            print('❌ Agora Error: $err - $msg');
          }
        },
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
          if (kDebugMode) {
            print('✅ Joined channel: ${connection.channelId}');
            print('👤 Local UID: ${connection.localUid}');
          }
          _currentUid = connection.localUid;

          // ✅ Configure audio AFTER successfully joining
          await _configureAudioSettings();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (kDebugMode) {
            print('👤 User joined: $remoteUid');
            print('🎵 Remote user should now be able to hear and speak');
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          if (kDebugMode) {
            print('👋 User left: $remoteUid, reason: $reason');
          }
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          if (kDebugMode) {
            print('👋 Left channel: ${connection.channelId}');
          }
          _currentChannelName = null;
          _currentUid = null;
        },
        onRemoteAudioStateChanged: (RtcConnection connection,
            int remoteUid,
            RemoteAudioState state,
            RemoteAudioStateReason reason,
            int elapsed) {
          if (kDebugMode) {
            print(
                '🎵 Remote audio state changed: UID=$remoteUid, State=$state, Reason=$reason');
          }

          // 🌐 Handle network issues
          if (reason ==
              RemoteAudioStateReason.remoteAudioReasonNetworkCongestion) {
            if (kDebugMode) {
              print('⚠️ Network congestion detected - adjusting quality');
            }
            // Lower bitrate for better stability
            _engine?.setParameters('{"che.audio.codec.bitrate":32000}');
          } else if (reason ==
              RemoteAudioStateReason.remoteAudioReasonNetworkRecovery) {
            if (kDebugMode) {
              print('✅ Network recovered - restoring quality');
            }
            // Restore higher bitrate
            _engine?.setParameters('{"che.audio.codec.bitrate":48000}');
          }
        },
        onLocalAudioStateChanged: (RtcConnection connection,
            LocalAudioStreamState state, LocalAudioStreamReason reason) {
          if (kDebugMode) {
            print('🎤 Local audio state changed: State=$state, Reason=$reason');
          }
        },
        onAudioPublishStateChanged: (String channel,
            StreamPublishState oldState,
            StreamPublishState newState,
            int elapseSinceLastState) {
          if (kDebugMode) {
            print(
                '📢 Audio publish state: $oldState → $newState (Channel: $channel)');
          }
        },
        onAudioSubscribeStateChanged: (String channel,
            int uid,
            StreamSubscribeState oldState,
            StreamSubscribeState newState,
            int elapseSinceLastState) {
          if (kDebugMode) {
            print(
                '🔔 Audio subscribe state: $oldState → $newState (UID: $uid)');
          }
        },
        onNetworkQuality: (RtcConnection connection, int remoteUid,
            QualityType txQuality, QualityType rxQuality) {
          // 📊 Monitor network quality
          if (txQuality.index >= 4 || rxQuality.index >= 4) {
            // Quality is poor (4 = poor, 5 = bad, 6 = very bad)
            if (kDebugMode) {
              print(
                  '⚠️ Poor network quality detected: TX=$txQuality, RX=$rxQuality');
            }
          }
        },
      ),
    );
  }

  /// 🎵 Configure audio settings after joining channel
  Future<void> _configureAudioSettings() async {
    if (_engine == null) return;

    try {
      // Wait a bit for the channel to be fully established
      await Future.delayed(const Duration(milliseconds: 500));

      if (kDebugMode) {
        print('🎵 Configuring audio settings...');
      }

      // 🎯 Use high-quality voice optimized profile
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicHighQualityStereo,
        scenario: AudioScenarioType.audioScenarioDefault,
      );

      // 🎵 Enable audio features
      await _engine!.enableAudio();
      await _engine!.muteLocalAudioStream(false);

      // 🔊 Configure audio routing
      await _engine!.setEnableSpeakerphone(true);
      await _engine!.setDefaultAudioRouteToSpeakerphone(true);

      // 📊 Optimize audio quality and bitrate
      await _engine!.adjustPlaybackSignalVolume(100);
      await _engine!.adjustRecordingSignalVolume(100);

      // 🌐 Set optimal bitrate for voice (48kbps)
      await _engine!.setParameters('{"che.audio.codec.bitrate":48000}');

      if (kDebugMode) {
        print('✅ Audio configured: High-quality voice profile enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Warning: Failed to configure audio settings: $e');
      }
      // Don't throw - call can continue even if some settings fail
    }
  }

  /// 🚪 Join voice channel
  Future<void> joinChannel({
    required String channelName,
    required String userID,
  }) async {
    if (_engine == null || !_isEngineInitialized) {
      throw Exception(
          'Agora Engine not initialized. Call createEngine() first.');
    }

    try {
      // Leave current channel if already in one
      if (_currentChannelName != null) {
        if (kDebugMode) {
          print('⚠️ Already in channel $_currentChannelName, leaving first...');
        }
        await leaveChannel();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // String? token; // Disabled - using testing mode without tokens
      int uid = 0; // 0 means Agora will assign a UID

      // ✅ FETCH TOKEN FROM CLOUD FUNCTION
      String? token;
      try {
        if (kDebugMode) {
          print('🔐 Fetching Agora token from Cloud Function...');
        }

        final result =
            await _functions.httpsCallable('generateAgoraToken').call({
          'channelName': channelName,
          'uid': uid,
          'role': 'publisher',
          'expirationTime': 3600, // 1 hour
        });

        token = result.data['token'] as String?;

        if (kDebugMode) {
          print('✅ Token fetched successfully!');
          print('📝 Token: ${token?.substring(0, 20)}...');
          print('⏰ Expires at: ${result.data['expiresAt']}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to fetch token: $e');
          print('⚠️ Attempting to join without token...');
        }
        // Continue without token (will fail if authentication is required)
      }

      if (kDebugMode) {
        print('🚪 Joining Agora channel: $channelName');
        print('👤 User ID: $userID');
        print(
            '🔐 Token: ${token != null ? "✅ Fetched from server" : "❌ Not available"}');
      }

      // Join channel (with token from Cloud Function)
      await _engine!.joinChannel(
        token: token ?? '', // Use fetched token or empty string
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          autoSubscribeVideo: false,
          publishMicrophoneTrack: true,
          publishCameraTrack: false,
          // 🎯 Enable low latency mode for real-time communication
          audienceLatencyLevel:
              AudienceLatencyLevelType.audienceLatencyLevelLowLatency,
        ),
      );

      _currentChannelName = channelName;

      if (kDebugMode) {
        print('✅ Successfully initiated channel join: $channelName');
        print('⏳ Audio will be configured after connection is established...');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to join channel: $e');
      }
      rethrow;
    }
  }

  /// 🚪 Leave voice channel
  Future<void> leaveChannel() async {
    if (_engine == null) return;

    try {
      await _engine!.leaveChannel();
      _currentChannelName = null;
      _currentUid = null;

      if (kDebugMode) {
        print('✅ Left voice channel');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to leave channel: $e');
      }
    }
  }

  /// 🔇 Mute/unmute microphone
  Future<void> muteMicrophone(bool mute) async {
    if (_engine == null) return;

    try {
      await _engine!.muteLocalAudioStream(mute);

      if (kDebugMode) {
        print('🎤 Microphone ${mute ? 'muted' : 'unmuted'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to mute/unmute microphone: $e');
      }
    }
  }

  /// 🔊 Enable/disable speaker
  Future<void> enableSpeaker(bool enable) async {
    if (_engine == null) return;

    try {
      await _engine!.setEnableSpeakerphone(enable);

      if (kDebugMode) {
        print('🔊 Speaker ${enable ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to enable/disable speaker: $e');
      }
    }
  }

  /// 🎵 Enable audio (ensure audio module is active)
  Future<void> enableAudio() async {
    if (_engine == null) return;

    try {
      // Just ensure audio is enabled - don't reconfigure everything
      await _engine!.enableAudio();

      if (kDebugMode) {
        print('🎵 Audio module enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to enable audio: $e');
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
      // Create unique channel name (alphanumeric only)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final channelName = 'voice${callID}$timestamp';

      if (kDebugMode) {
        print('🎤 Creating Agora voice call channel: $channelName');
        print('📏 Channel name length: ${channelName.length} chars');
      }

      // Send call notification to Firebase
      await _sendCallNotification(
        callType: 'voice',
        callID: channelName,
        receiverId: receiverId,
        receiverName: receiverName,
      );

      if (kDebugMode) {
        print('🎤 Voice call initiated: $channelName to $receiverName');
      }

      return channelName;
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
      // Save call notification to Firestore
      await _firestore.collection('call_notifications').doc(callID).set({
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

      // Send push notification to receiver
      await _notificationService.notifyIncomingVoiceCall(
        receiverId: receiverId,
        callerName: currentUser.displayName ?? 'Unknown User',
        callId: callID,
        roomId: callID,
        callerId: currentUser.uid,
      );

      if (kDebugMode) {
        print('✅ Call notification sent successfully!');
        print('📞 From: ${currentUser.displayName}');
        print('📱 To: $receiverName');
        print('🎤 Channel: $callID');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to send call notification: $e');
      }
    }
  }

  /// 🧹 Dispose engine
  Future<void> dispose() async {
    try {
      await leaveChannel();
      await _engine?.release();
      _engine = null;
      _isEngineInitialized = false;

      if (kDebugMode) {
        print('🧹 Agora Engine disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disposing Agora Engine: $e');
      }
    }
  }
}
