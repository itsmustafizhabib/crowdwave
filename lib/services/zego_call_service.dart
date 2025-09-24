import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../presentation/call/voice_call_screen.dart';
import 'zego_voice_call_service.dart';

/// 🚀 UPDATED ZegoCloud Call Service - Using ZegoExpressEngine
/// ✅ Now using custom implementation with ZegoExpressEngine
/// ✅ WhatsApp-quality voice calls
/// ✅ 10,000 free minutes/month
class ZegoCallService {
  static final ZegoCallService _instance = ZegoCallService._internal();
  factory ZegoCallService() => _instance;
  ZegoCallService._internal();

  final ZegoVoiceCallService _voiceCallService = ZegoVoiceCallService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getters
  bool get isInitialized => _voiceCallService.isEngineCreated;
  String? get currentUserId => _auth.currentUser?.uid;

  /// 🚀 Initialize ZegoExpressEngine
  Future<void> initializeZego() async {
    if (_voiceCallService.isEngineCreated) return;

    try {
      await _voiceCallService.createEngine();

      if (kDebugMode) {
        print('✅ ZegoCallService Ready - Using ZegoExpressEngine');
        print('🎯 User: ${_auth.currentUser?.displayName}');
        print('📱 Ready for WhatsApp-quality calls!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize ZegoCallService: $e');
      }
      rethrow;
    }
  }

  /// 🎤 Start Voice Call - Using Custom Implementation
  Future<void> startVoiceCall({
    required BuildContext context,
    required String callID,
    required String receiverId,
    required String receiverName,
    String? receiverAvatar,
  }) async {
    if (!_voiceCallService.isEngineCreated) {
      throw Exception(
          'ZegoCallService not initialized. Call initializeZego() first.');
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to make calls');
    }

    // ✅ FIX: Check if user is already in a call to prevent 1002001 error
    if (_voiceCallService.currentRoomID != null) {
      if (kDebugMode) {
        print('⚠️ User already in call: ${_voiceCallService.currentRoomID}');
      }

      // Show dialog to ask user if they want to end current call
      final shouldEndCurrentCall = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Call in Progress'),
          content: const Text(
              'You are already in a call. End current call to start a new one?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('End Current Call'),
            ),
          ],
        ),
      );

      if (shouldEndCurrentCall != true) {
        return; // User cancelled
      }

      // End current call first
      await _voiceCallService.logoutRoom();

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
        SnackBar(content: Text('Voice call failed: $e')),
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
      const SnackBar(
        content: Text('Video calls coming soon! Starting voice call...'),
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
          label: const Text('Voice Call'),
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
          label: const Text('Video Call'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
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
  Future<void> acceptCall(String notificationId) async {
    try {
      await _firestore
          .collection('call_notifications')
          .doc(notificationId)
          .update({'status': 'accepted'});
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to accept call: $e');
      }
    }
  }

  /// Decline incoming call
  Future<void> declineCall(String notificationId) async {
    try {
      await _firestore
          .collection('call_notifications')
          .doc(notificationId)
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
      // Find call notification by callID and update status
      final querySnapshot = await _firestore
          .collection('call_notifications')
          .where('callID', isEqualTo: callId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await _firestore
            .collection('call_notifications')
            .doc(docId)
            .update({'status': 'ended'});
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to end call: $e');
      }
    }
  }

  /// Cleanup
  Future<void> dispose() async {
    await _voiceCallService.destroyEngine();
  }
}
