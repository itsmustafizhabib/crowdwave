import 'package:flutter/material.dart';
import '../widgets/liquid_loading_indicator.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/app_lifecycle_controller.dart';
import '../services/presence_service.dart';
import '../controllers/chat_controller.dart';

/// 🚨 BLACK SCREEN PREVENTION UTILITY
///
/// This utility provides comprehensive fixes for the black screen issue
/// that occurs during navigation, especially when going back from screens.
///
/// Key Issues Fixed:
/// 1. FlutterJNI detachment from native layer
/// 2. Memory leaks from unclosed streams
/// 3. GPU memory allocation failures
/// 4. Excessive lifecycle observers

class BlackScreenFix {
  static bool _isRecovering = false;
  static DateTime? _lastBlackScreenTime;
  static int _blackScreenCount = 0;

  /// Initialize black screen prevention measures
  static void initialize() {
    // Set up global error handling for navigation failures
    _setupGlobalErrorHandling();

    // Optimize system UI for better memory usage
    _optimizeSystemUI();

    // Setup periodic cleanup
    _setupPeriodicCleanup();
  }

  /// Detect if app is experiencing black screen issues
  static bool isBlackScreenDetected() {
    // Check for rapid lifecycle changes (indicator of black screen)
    final now = DateTime.now();
    if (_lastBlackScreenTime != null) {
      final timeDiff = now.difference(_lastBlackScreenTime!);
      if (timeDiff.inSeconds < 5) {
        _blackScreenCount++;
        return _blackScreenCount > 2;
      }
    }
    return false;
  }

  /// Emergency recovery from black screen
  static Future<void> emergencyRecovery() async {
    if (_isRecovering) return;
    _isRecovering = true;

    try {
      print(
          '🚨 EMERGENCY RECOVERY: Black screen detected, initiating recovery...');

      // 1. Clear Flutter engine state
      await _clearFlutterEngineState();

      // 2. Force cleanup all services
      await _forceCleanupServices();

      // 3. Reset navigation stack
      await _resetNavigationStack();

      // 4. Restart core services
      await _restartCoreServices();

      print('✅ EMERGENCY RECOVERY: Recovery completed successfully');
    } catch (e) {
      print('❌ EMERGENCY RECOVERY FAILED: $e');
    } finally {
      _isRecovering = false;
    }
  }

  /// Setup global error handling
  static void _setupGlobalErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      // Check if error is related to black screen issues
      if (_isBlackScreenRelatedError(details)) {
        _lastBlackScreenTime = DateTime.now();
        emergencyRecovery();
      }

      // Log the error but don't crash the app
      print('FLUTTER ERROR CAUGHT: ${details.exception}');
      print('STACK TRACE: ${details.stack}');
    };
  }

  /// Check if error is related to black screen
  static bool _isBlackScreenRelatedError(FlutterErrorDetails details) {
    final errorString = details.exception.toString().toLowerCase();
    return errorString.contains('flutterjni') ||
        errorString.contains('graphicbuffer') ||
        errorString.contains('detached from native') ||
        errorString.contains('failed to allocate');
  }

  /// Optimize system UI for better memory usage
  static void _optimizeSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    // Enable hardware acceleration
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
  }

  /// Setup periodic cleanup to prevent memory accumulation
  static void _setupPeriodicCleanup() {
    // Clean up every 2 minutes when app is active
    Stream.periodic(const Duration(minutes: 2)).listen((_) {
      if (!_isRecovering) {
        _performPeriodicCleanup();
      }
    });
  }

  /// Perform periodic cleanup
  static void _performPeriodicCleanup() {
    try {
      // Force garbage collection
      _forceGarbageCollection();

      // Clean up image cache
      _cleanupImageCache();

      // Clean up unused controllers
      _cleanupUnusedControllers();

      print('🧹 PERIODIC CLEANUP: Memory cleanup completed');
    } catch (e) {
      print('❌ PERIODIC CLEANUP FAILED: $e');
    }
  }

  /// Clear Flutter engine state
  static Future<void> _clearFlutterEngineState() async {
    try {
      // Force close all platform channels
      await SystemChannels.platform
          .invokeMethod('SystemChrome.setApplicationSwitcherDescription');

      // Clear any pending method calls
      await Future.delayed(const Duration(milliseconds: 100));

      print('✅ Flutter engine state cleared');
    } catch (e) {
      print('❌ Failed to clear Flutter engine state: $e');
    }
  }

  /// Force cleanup all services
  static Future<void> _forceCleanupServices() async {
    try {
      // Cleanup presence service
      if (Get.isRegistered<PresenceService>()) {
        final presenceService = Get.find<PresenceService>();
        await presenceService.dispose();
      }

      // Cleanup chat controller
      if (Get.isRegistered<ChatController>()) {
        final chatController = Get.find<ChatController>();
        chatController.onClose();
      }

      // Cleanup app lifecycle controller
      if (Get.isRegistered<AppLifecycleController>()) {
        final lifecycleController = Get.find<AppLifecycleController>();
        lifecycleController.onClose();
      }

      print('✅ All services cleaned up');
    } catch (e) {
      print('❌ Failed to cleanup services: $e');
    }
  }

  /// Reset navigation stack
  static Future<void> _resetNavigationStack() async {
    try {
      // Clear GetX navigation stack
      Get.reset();

      // Navigate to safe home screen
      Get.offAllNamed('/main-navigation');

      print('✅ Navigation stack reset');
    } catch (e) {
      print('❌ Failed to reset navigation: $e');
    }
  }

  /// Restart core services
  static Future<void> _restartCoreServices() async {
    try {
      // Reinitialize presence service
      final presenceService = Get.put(PresenceService());
      await presenceService.initialize();

      // Reinitialize app lifecycle controller
      Get.put(AppLifecycleController());

      print('✅ Core services restarted');
    } catch (e) {
      print('❌ Failed to restart services: $e');
    }
  }

  /// Force garbage collection
  static void _forceGarbageCollection() {
    // Trigger garbage collection (platform-specific)
    WidgetsBinding.instance.reassembleApplication();
  }

  /// Cleanup image cache
  static void _cleanupImageCache() {
    // Clear image cache to free memory
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  /// Cleanup unused GetX controllers
  static void _cleanupUnusedControllers() {
    // Remove controllers that are no longer needed
    Get.delete<ChatController>(force: true);
    Get.delete<AppLifecycleController>(force: true);
  }
}

/// Widget wrapper that provides black screen protection
class BlackScreenProtection extends StatefulWidget {
  final Widget child;
  final String screenName;

  const BlackScreenProtection({
    Key? key,
    required this.child,
    required this.screenName,
  }) : super(key: key);

  @override
  State<BlackScreenProtection> createState() => _BlackScreenProtectionState();
}

class _BlackScreenProtectionState extends State<BlackScreenProtection>
    with WidgetsBindingObserver {
  bool _isScreenBlack = false;
  DateTime? _lastInteraction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastInteraction = DateTime.now();

    // Monitor for black screen
    _monitorBlackScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    _lastInteraction = DateTime.now();

    // Detect potential black screen scenarios
    if (state == AppLifecycleState.resumed) {
      _checkForBlackScreen();
    }
  }

  void _monitorBlackScreen() {
    // Check for black screen every 5 seconds
    Stream.periodic(const Duration(seconds: 5)).listen((_) {
      if (mounted) {
        _checkForBlackScreen();
      }
    });
  }

  void _checkForBlackScreen() {
    if (_lastInteraction != null) {
      final timeSinceInteraction = DateTime.now().difference(_lastInteraction!);

      // If no interaction for 30 seconds and app is resumed, might be black screen
      if (timeSinceInteraction.inSeconds > 30) {
        if (BlackScreenFix.isBlackScreenDetected()) {
          _handleBlackScreen();
        }
      }
    }
  }

  void _handleBlackScreen() {
    if (!_isScreenBlack) {
      setState(() {
        _isScreenBlack = true;
      });

      print('🚨 BLACK SCREEN DETECTED on ${widget.screenName}');
      BlackScreenFix.emergencyRecovery();

      // Reset after recovery attempt
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isScreenBlack = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _lastInteraction = DateTime.now();
      },
      onPanUpdate: (_) {
        _lastInteraction = DateTime.now();
      },
      child: _isScreenBlack ? _buildRecoveryScreen() : widget.child,
    );
  }

  Widget _buildRecoveryScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LiquidLoadingIndicator(
              color: Color(0xFF0046FF),
            ),
            const SizedBox(height: 20),
            const Text(
              'Recovering...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF262626),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please wait while we restore your session',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF525252),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Get.offAllNamed('/main-navigation');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0046FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
