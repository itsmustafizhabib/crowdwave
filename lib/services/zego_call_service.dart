import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../presentation/call/voice_call_screen.dart';
import 'agora_voice_call_service.dart';

/// 🚀 Agora Call Service - Free 10,000 minutes/month FOREVER!
/// ✅ Using Agora RTC Engine
/// ✅ WhatsApp-quality voice calls
/// ✅ Lifetime free tier!
class ZegoCallService {
  static final ZegoCallService _instance = ZegoCallService._internal();
  factory ZegoCallService() => _instance;
  ZegoCallService._internal();

  final AgoraVoiceCallService _voiceCallService = AgoraVoiceCallService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getters
  bool get isInitialized => _voiceCallService.isEngineInitialized;
  String? get currentUserId => _auth.currentUser?.uid;

  /// 🚀 Initialize Agora Engine
  Future<void> initializeZego() async {
    if (_voiceCallService.isEngineInitialized) return;

    try {
      await _voiceCallService.createEngine();

      if (kDebugMode) {
        print('✅ AgoraCallService Ready - Using Agora RTC Engine');
        print('🎯 User: ${_auth.currentUser?.displayName}');
        print('📱 Ready for WhatsApp-quality calls!');
        print('🆓 Free tier: 10,000 minutes/month forever!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize AgoraCallService: $e');
      }
      rethrow;
    }
  }

  /// 🎤 Start Voice Call - Using Agora
  Future<void> startVoiceCall({
    required BuildContext context,
    required String callID,
    required String receiverId,
    required String receiverName,
    String? receiverAvatar,
  }) async {
    if (!_voiceCallService.isEngineInitialized) {
      throw Exception(
          'AgoraCallService not initialized. Call initializeZego() first.');
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to make calls');
    }

    // ✅ FIX: Check if user is already in a call
    if (_voiceCallService.currentChannelName != null) {
      if (kDebugMode) {
        print(
            '⚠️ User already in call: ${_voiceCallService.currentChannelName}');
      }

      // Show dialog to ask user if they want to end current call
      final shouldEndCurrentCall = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('calls.call_in_progress'.tr()),
          content: Text(
              'common.you_are_already_in_a_call_end_current_call_to_star'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('common.cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('calls.end_current_call'.tr()),
            ),
          ],
        ),
      );

      if (shouldEndCurrentCall != true) {
        return; // User cancelled
      }

      // End current call first
      await _voiceCallService.leaveChannel();

      // Small delay to ensure logout is complete
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      // Start voice call and get room ID
      final roomID = await _voiceCallService.startVoiceCall(
        callID: callID,
        receiverId: receiverId,
        receiverName: receiverName,
      );

      // Navigate to voice call screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoiceCallScreen(
              roomID: roomID,
              localUserID: currentUser.uid,
              localUserName: currentUser.displayName ?? 'User',
              receiverName: receiverName,
              receiverAvatar: receiverAvatar,
            ),
          ),
        );
      }

      if (kDebugMode) {
        print('🎤 Voice call started: $roomID to $receiverName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Voice call error: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('calls.voice_failed'.tr(args: [e.toString()]))),
      );
    }
  }

  /// 📹 Start Video Call - Placeholder (implement if needed)
  Future<void> startVideoCall({
    required BuildContext context,
    required String callID,
    required String receiverId,
    required String receiverName,
    String? receiverAvatar,
  }) async {
    // For now, redirect to voice call
    // TODO: Implement video call functionality if needed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('calls.video_coming_soon'.tr()),
        backgroundColor: Colors.orange,
      ),
    );

    await startVoiceCall(
      context: context,
      callID: callID,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverAvatar: receiverAvatar,
    );
  }

  /// Generate random call ID
  String generateCallID() {
    return Random().nextInt(999999).toString();
  }

  /// 📱 Show Call UI Buttons
  Widget buildCallButtons({
    required String receiverId,
    required String receiverName,
    required BuildContext context,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Voice Call Button
        ElevatedButton.icon(
          onPressed: () => startVoiceCall(
            context: context,
            callID: generateCallID(),
            receiverId: receiverId,
            receiverName: receiverName,
          ),
          icon: const Icon(Icons.phone, color: Colors.white),
          label: Text('calls.voice_call'.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),

        // Video Call Button (redirects to voice for now)
        ElevatedButton.icon(
          onPressed: () => startVideoCall(
            context: context,
            callID: generateCallID(),
            receiverId: receiverId,
            receiverName: receiverName,
          ),
          icon: const Icon(Icons.videocam, color: Colors.white),
          label: Text('calls.video_call'.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF008080),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Listen for incoming calls
  Stream<QuerySnapshot> getIncomingCalls() {
    if (currentUserId == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('call_notifications')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'calling')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Accept incoming call
  Future<void> acceptCall(String callId) async {
    try {
      // Use callID as document ID directly
      await _firestore
          .collection('call_notifications')
          .doc(callId)
          .update({'status': 'accepted'});
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to accept call: $e');
      }
    }
  }

  /// Decline incoming call
  Future<void> declineCall(String callId) async {
    try {
      // Use callID as document ID directly
      await _firestore
          .collection('call_notifications')
          .doc(callId)
          .update({'status': 'declined'});
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to decline call: $e');
      }
    }
  }

  /// End ongoing call
  Future<void> endCall(String callId) async {
    try {
      // Use callID as document ID directly - no need to query
      await _firestore
          .collection('call_notifications')
          .doc(callId)
          .update({'status': 'ended'});
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to end call: $e');
      }
    }
  }

  /// Cleanup
  Future<void> dispose() async {
    await _voiceCallService.dispose();
  }
}
