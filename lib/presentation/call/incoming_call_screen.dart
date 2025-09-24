import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../services/zego_call_service.dart';
import 'voice_call_screen.dart';

/// 📞 Incoming Call Screen - WhatsApp-like interface
/// Shows when receiving a voice call with accept/decline options
class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String roomId;
  final String callerName;
  final String callerId;
  final String? callerAvatar;
  final String notificationId;

  const IncomingCallScreen({
    Key? key,
    required this.callId,
    required this.roomId,
    required this.callerName,
    required this.callerId,
    required this.notificationId,
    this.callerAvatar,
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  final ZegoCallService _callService = ZegoCallService();

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  // Call timeout timer
  Timer? _timeoutTimer;
  bool _callEnded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupCallTimeout();
    _playRingtone();
  }

  void _initializeAnimations() {
    // Pulse animation for avatar
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);

    // Slide animation for buttons
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  void _setupCallTimeout() {
    // Auto-decline call after 30 seconds
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && !_callEnded) {
        _declineCall();
      }
    });
  }

  void _playRingtone() {
    if (kDebugMode) {
      print('🔊 Starting ringtone for incoming call');
    }

    // Simple but effective ringing pattern
    _playSimpleRing();

    // Continue ringing every 2 seconds until call ends
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || _callEnded) {
        timer.cancel();
        if (kDebugMode) {
          print('🔇 Stopping ringtone - call ended or screen disposed');
        }
        return;
      }
      _playSimpleRing();
    });
  }

  void _playSimpleRing() {
    if (!mounted || _callEnded) return;

    try {
      // Play alert sound with haptic feedback
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();

      if (kDebugMode) {
        print('🔊 Ring! Playing alert sound');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error playing ringtone: $e');
      }
    }
  }

  Future<void> _acceptCall() async {
    if (_callEnded) return;

    setState(() {
      _callEnded = true;
    });

    try {
      // Stop animations and timers
      _pulseController.stop();
      _timeoutTimer?.cancel();

      // Accept call in Firestore
      await _callService.acceptCall(widget.notificationId);

      // Initialize Zego if needed
      if (!_callService.isInitialized) {
        await _callService.initializeZego();
      }

      // Navigate to voice call screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VoiceCallScreen(
              roomID: widget.roomId,
              localUserID: _callService.currentUserId ?? 'unknown',
              localUserName: 'You', // Will be fetched from Firebase Auth
              receiverName: widget.callerName,
              receiverAvatar: widget.callerAvatar,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error accepting call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept call: $e')),
        );
      }
    }
  }

  Future<void> _declineCall() async {
    if (_callEnded) return;

    setState(() {
      _callEnded = true;
    });

    // Play call decline beep
    _playCallDeclineBeep();

    try {
      // Stop animations and timers
      _pulseController.stop();
      _timeoutTimer?.cancel();

      // Decline call in Firestore - this will notify the caller
      await _callService.declineCall(widget.notificationId);

      // Close screen
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Error declining call: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _playCallDeclineBeep() {
    // Play call decline beep sound
    try {
      // Two quick beeps for decline
      SystemSound.play(SystemSoundType.click);

      Timer(const Duration(milliseconds: 150), () {
        SystemSound.play(SystemSoundType.click);
      });

      // Heavy haptic feedback for call decline
      HapticFeedback.heavyImpact();
    } catch (e) {
      print('Error playing call decline beep: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button - user must accept or decline
        return false;
      },
      child: Scaffold(
        backgroundColor:
            const Color(0xFF1a1a1a), // Dark background like WhatsApp
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2a2a2a),
                Color(0xFF1a1a1a),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top section with caller info
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Incoming call',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Caller avatar with pulse animation
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0046FF)
                                        .withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 80,
                                backgroundColor: const Color(0xFF0046FF),
                                backgroundImage: (widget.callerAvatar != null &&
                                        widget.callerAvatar!.isNotEmpty &&
                                        widget.callerAvatar!.startsWith('http'))
                                    ? NetworkImage(widget.callerAvatar!)
                                    : null,
                                child: (widget.callerAvatar == null ||
                                        widget.callerAvatar!.isEmpty ||
                                        !widget.callerAvatar!
                                            .startsWith('http'))
                                    ? Text(
                                        widget.callerName.isNotEmpty
                                            ? widget.callerName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // Caller name
                      Text(
                        widget.callerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Call type
                      const Text(
                        'Voice call',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom section with action buttons
                Expanded(
                  flex: 1,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Decline button
                          GestureDetector(
                            onTap: _declineCall,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red,
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.call_end,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),

                          // Accept button
                          GestureDetector(
                            onTap: _acceptCall,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green,
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.call,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
