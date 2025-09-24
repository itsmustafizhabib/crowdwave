import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'animation_preload_service.dart';

class AppInitializationService {
  static final AppInitializationService _instance =
      AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  bool _isInitialized = false;
  final AnimationPreloadService _animationService = AnimationPreloadService();

  bool get isInitialized => _isInitialized;

  /// Initialize the app - preload critical resources
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set system UI overlay style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      // Preload critical animations that might be used frequently
      await _animationService.preloadAnimations([
        'assets/animations/Loading-animation.json', // Used in loading widgets
        'assets/animations/wave.json', // Used in various screens
      ]);

      _isInitialized = true;
    } catch (e) {
      print('Error during app initialization: $e');
      _isInitialized = true; // Don't block the app if initialization fails
    }
  }

  /// Preload additional resources in the background
  Future<void> preloadAdditionalResources() async {
    // This can be called after the app is loaded to preload less critical animations
    await _animationService.preloadAnimations([
      'assets/animations/coin.json',
      'assets/animations/Confetti.json',
    ]);
  }

  /// Clear all preloaded resources to free memory
  void clearResources() {
    _animationService.clearPreloadedAnimations();
    _isInitialized = false;
  }
}
