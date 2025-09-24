import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../services/zego_voice_call_service.dart';
import '../../services/zego_call_service.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🎤 Voice Call Screen - Custom UI Implementation
/// Provides a professional voice call interface using ZegoExpressEngine
class VoiceCallScreen extends StatefulWidget {
  final String roomID;
  final String localUserID;
  final String localUserName;
  final String receiverName;
  final String? receiverAvatar;

  const VoiceCallScreen({
    Key? key,
    required this.roomID,
    required this.localUserID,
    required this.localUserName,
    required this.receiverName,
    this.receiverAvatar,
  }) : super(key: key);

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with TickerProviderStateMixin {
  final ZegoVoiceCallService _callService = ZegoVoiceCallService();
  final ZegoCallService _zegoCallService = ZegoCallService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Call state
  bool _isConnected = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isConnecting = true;
  bool _isRinging = true; // New: Track if we're still ringing
  bool _callAnswered = false; // New: Track if call was answered
  bool _callDeclined = false; // NEW: Track if call was declined
  bool _callEnded = false; // NEW: Track if call was ended

  // Timer for call duration
  Timer? _callTimer;
  Timer? _ringTimer; // New: Timer for ringing timeout
  int _callDuration = 0;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _connectionController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _connectionAnimation;

  // Stream subscriptions
  StreamSubscription<ZegoRoomState>? _roomStateSubscription;
  StreamSubscription<List<String>>? _streamListSubscription;
  StreamSubscription<List<ZegoUser>>? _userListSubscription;
  StreamSubscription<QuerySnapshot>?
      _callStatusSubscription; // NEW: Track call status

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupCallService();
    _joinCall();
    _startRingTimer(); // Start ring timeout
  }

  void _startRingTimer() {
    // Auto-end call if no one answers within 30 seconds
    _ringTimer = Timer(const Duration(seconds: 30), () {
      if (!_callAnswered && mounted) {
        _showError('No answer. Call ended.');
        _endCall();
      }
    });

    // Start playing outgoing call ringing tone for caller
    _playOutgoingRingtone();
  }

  void _playOutgoingRingtone() {
    // ✅ ENHANCED: Better audio feedback for caller while waiting
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);

    // ✅ CONTINUOUS CALLER FEEDBACK: Ring every 2 seconds until answered
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || _callAnswered || _callEnded || _callDeclined) {
        timer.cancel();
        return;
      }

      // ✅ REALISTIC CALLER EXPERIENCE: Double beep pattern
      _playCallerRingTone();
    });

    if (kDebugMode) {
      print('📞 CALLER RINGING: Starting outgoing call audio feedback');
    }
  }

  void _playCallerRingTone() {
    if (!mounted || _callAnswered || _callEnded || _callDeclined) return;

    try {
      // ✅ CALLER HEARS RINGING: Gentle feedback while waiting
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);

      // ✅ DOUBLE BEEP: More realistic caller experience
      Timer(const Duration(milliseconds: 500), () {
        if (!mounted || _callAnswered || _callEnded || _callDeclined) return;
        HapticFeedback.selectionClick();
        SystemSound.play(SystemSoundType.click);
      });

      if (kDebugMode) {
        print('🔊 CALLER FEEDBACK: Playing ring tone for caller');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error playing caller ring tone: $e');
      }
    }
  }

  void _initializeAnimations() {
    // Pulse animation for avatar
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);

    // Connection animation
    _connectionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _connectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _connectionController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _setupCallService() async {
    try {
      // Create engine if not already created
      if (!_callService.isEngineCreated) {
        await _callService.createEngine();
      }

      // Setup event listeners
      _roomStateSubscription = _callService.roomStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isConnected = state == ZegoRoomState.Connected;
            _isConnecting = state == ZegoRoomState.Connecting;
          });

          // DON'T start timer just because WE connected to room
          // Only when someone else joins
          if (state == ZegoRoomState.Disconnected) {
            _onCallDisconnected();
          }
        }
      });

      _streamListSubscription = _callService.streamListStream.listen((streams) {
        if (mounted && streams.isNotEmpty) {
          // Remote user joined and is streaming - NOW the call is answered!
          setState(() {
            _isConnected = true;
            _isConnecting = false;
          });
          _onCallConnected(); // Start timer only when remote user joins
        }
      });

      _userListSubscription = _callService.userListStream.listen((users) {
        if (mounted) {
          // Check if there's more than just us in the room
          final otherUsers =
              users.where((user) => user.userID != widget.localUserID).toList();

          if (otherUsers.isNotEmpty && !_callAnswered) {
            // Someone else joined - call answered!
            _onCallConnected();
          } else if (otherUsers.isEmpty && _callAnswered && !_callEnded) {
            // Other user left - end the call
            setState(() {
              _callEnded = true;
            });
            _stopCallTimer(); // ✅ FIXED: Stop timer when other user leaves
            _playCallEndBeep();
            _showError('Other party left the call');

            // ✅ FIXED: Automatically close screen when other user disconnects
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
          }

          print('👥 Users in room: ${users.map((u) => u.userName).join(', ')}');
        }
      });

      // NEW: Monitor call status changes (accept/decline/end)
      _callStatusSubscription = _firestore
          .collection('call_notifications')
          .where('callID', isEqualTo: widget.roomID)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        if (mounted && snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final status = doc.data()['status'] as String?;

          if (status == 'declined' && !_callDeclined) {
            setState(() {
              _callDeclined = true;
              _isRinging = false;
              _isConnecting = false;
            });
            _showError('Call declined');
            _endCall();
          } else if (status == 'ended' && !_callEnded) {
            // Someone ended the call - notify and close
            setState(() {
              _callEnded = true;
            });
            _stopCallTimer(); // ✅ FIXED: Stop timer when call ends
            _playCallEndBeep();
            _showError('Call ended by other party');

            // ✅ FIXED: Immediately dispose screen when other party ends call
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
          } else if (status == 'accepted' && !_callAnswered) {
            setState(() {
              _isRinging = false;
            });
            // Wait for user to actually join the room
          }
        }
      });
    } catch (e) {
      if (mounted) {
        _showError('Failed to setup call service: $e');
      }
    }
  }

  Future<void> _joinCall() async {
    try {
      final result = await _callService.loginRoom(
        roomID: widget.roomID,
        userID: widget.localUserID,
        userName: widget.localUserName,
      );

      if (result.errorCode != 0) {
        if (mounted) {
          String errorMessage;
          if (result.errorCode == 1002001) {
            errorMessage =
                'You are already in another call. Please end it first.';
          } else {
            errorMessage = 'Failed to join call: Error ${result.errorCode}';
          }
          _showError(errorMessage);

          // Auto-close the screen if failed to join
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      } else {
        // ✅ AUDIO FIX: Ensure proper audio setup after joining
        await _setupAudioSettings();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        if (e.toString().contains('1002001')) {
          errorMessage =
              'You are already in another call. Please end it first.';
        } else {
          errorMessage = 'Failed to join call: $e';
        }
        _showError(errorMessage);

        // Auto-close the screen if failed to join
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    }
  }

  // ✅ NEW: Setup proper audio settings for both caller and receiver
  Future<void> _setupAudioSettings() async {
    try {
      // Enable microphone (ensure it's not muted by default)
      await _callService.muteMicrophone(false);

      // Set speaker on by default for better audio quality
      await _callService.enableSpeaker(true);

      if (mounted) {
        setState(() {
          _isMuted = false;
          _isSpeakerOn = true;
        });
      }

      print('✅ Audio settings configured: Mic ON, Speaker ON');
    } catch (e) {
      print('⚠️ Warning: Failed to setup audio settings: $e');
    }
  }

  void _onCallConnected() {
    // Only start timer when another user actually joins (call answered)
    if (!_callAnswered) {
      setState(() {
        _callAnswered = true;
        _isRinging = false;
        _isConnecting = false;
      });

      _ringTimer?.cancel(); // Stop ring timer - call answered!
      _connectionController.forward();
      _startCallTimer(); // NOW start timer - when call is actually answered

      // Stop pulse animation when connected
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _onCallDisconnected() {
    _connectionController.reverse();
    _stopCallTimer();
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  String _formatCallDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    // Ensure call is properly ended when screen is disposed
    if (!_callEnded) {
      _playCallEndBeep();
      _zegoCallService.endCall(widget.roomID);
    }

    _pulseController.dispose();
    _connectionController.dispose();
    _stopCallTimer();
    _ringTimer?.cancel(); // Cancel ring timer
    _roomStateSubscription?.cancel();
    _streamListSubscription?.cancel();
    _userListSubscription?.cancel();
    _callStatusSubscription?.cancel(); // Cancel call status subscription

    // Leave room when screen is disposed (ensure cleanup)
    _callService.logoutRoom().then((_) {
      // Success - room logout completed
    }).catchError((e) {
      print('Error during room logout in dispose: $e');
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildCallInterface()),
            _buildCallControls(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down,
                color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Text(
            _isConnecting
                ? 'Connecting...'
                : (_isConnected ? 'Voice Call' : 'Call Ended'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildCallInterface() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Avatar and name
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: (_isRinging || _isConnecting) && !_callAnswered
                  ? _pulseAnimation.value
                  : 1.0,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0046FF).withOpacity(0.3),
                      const Color(0xFF00D4FF).withOpacity(0.3),
                    ],
                  ),
                  border: Border.all(
                    color: _isConnected ? Colors.green : Colors.grey,
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 75,
                  backgroundColor: const Color(0xFF2C2C2E),
                  backgroundImage: (widget.receiverAvatar != null &&
                          widget.receiverAvatar!.isNotEmpty &&
                          widget.receiverAvatar!.startsWith('http'))
                      ? NetworkImage(widget.receiverAvatar!)
                      : null,
                  child: (widget.receiverAvatar == null ||
                          widget.receiverAvatar!.isEmpty ||
                          !widget.receiverAvatar!.startsWith('http'))
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey[400],
                        )
                      : null,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 30),

        // Receiver name
        Text(
          widget.receiverName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        // Call status
        AnimatedBuilder(
          animation: _connectionAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _connectionAnimation.value,
              child: Text(
                _callAnswered
                    ? _formatCallDuration(
                        _callDuration) // Show timer only when answered
                    : _isRinging
                        ? 'Ringing...'
                        : _isConnecting
                            ? 'Connecting...'
                            : 'Call ended',
                style: TextStyle(
                  color: _callAnswered ? Colors.green : Colors.grey[400],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),

        if (_isRinging || (_isConnecting && !_callAnswered)) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCallControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            backgroundColor: _isMuted ? Colors.red : const Color(0xFF2C2C2E),
            onPressed: _toggleMute,
          ),

          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            backgroundColor: Colors.red,
            onPressed: _endCall,
            size: 70,
          ),

          // Speaker button
          _buildControlButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            backgroundColor: _isSpeakerOn
                ? const Color(0xFF0046FF)
                : const Color(0xFF2C2C2E),
            onPressed: _toggleSpeaker,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.4,
        ),
      ),
    );
  }

  void _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });

    try {
      await _callService.muteMicrophone(_isMuted);
    } catch (e) {
      _showError('Failed to ${_isMuted ? 'mute' : 'unmute'} microphone');
    }
  }

  void _toggleSpeaker() async {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });

    try {
      await _callService.enableSpeaker(_isSpeakerOn);
    } catch (e) {
      _showError('Failed to ${_isSpeakerOn ? 'enable' : 'disable'} speaker');
    }
  }

  void _endCall() async {
    if (_callEnded) return; // Prevent multiple calls

    setState(() {
      _callEnded = true;
    });

    // Play call end beep sound
    _playCallEndBeep();

    try {
      // Notify other party that call is ending
      await _zegoCallService.endCall(widget.roomID);

      // Leave the room
      await _callService.logoutRoom();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Failed to end call');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _playCallEndBeep() {
    // Play call termination beep sound
    try {
      // Play three quick beeps to indicate call ended
      SystemSound.play(SystemSoundType.click);

      Timer(const Duration(milliseconds: 200), () {
        SystemSound.play(SystemSoundType.click);
      });

      Timer(const Duration(milliseconds: 400), () {
        SystemSound.play(SystemSoundType.click);
      });

      // Heavy haptic feedback for call end
      HapticFeedback.heavyImpact();
    } catch (e) {
      print('Error playing call end beep: $e');
    }
  }
}
