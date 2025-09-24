import 'package:lottie/lottie.dart';

class AnimationPreloadService {
  static final AnimationPreloadService _instance =
      AnimationPreloadService._internal();
  factory AnimationPreloadService() => _instance;
  AnimationPreloadService._internal();

  final Map<String, LottieComposition?> _preloadedAnimations = {};
  final Set<String> _currentlyLoading = <String>{};

  // Common animation paths used throughout the app
  static const List<String> commonAnimationPaths = [
    'assets/animations/onboarding_cost_effective_delivery.json',
    'assets/animations/eran.json',
    'assets/animations/Payment.json',
    'assets/animations/trust.json',
    'assets/animations/Loading-animation.json',
    'assets/animations/coin.json',
    'assets/animations/Confetti.json',
    'assets/animations/wave.json',
  ];

  /// Get a preloaded animation, or null if not loaded
  LottieComposition? getPreloadedAnimation(String path) {
    return _preloadedAnimations[path];
  }

  /// Check if an animation is already preloaded
  bool isAnimationPreloaded(String path) {
    return _preloadedAnimations.containsKey(path);
  }

  /// Check if an animation is currently being loaded
  bool isAnimationLoading(String path) {
    return _currentlyLoading.contains(path);
  }

  /// Preload a single animation
  Future<LottieComposition?> preloadAnimation(String path) async {
    if (_preloadedAnimations.containsKey(path)) {
      return _preloadedAnimations[path];
    }

    if (_currentlyLoading.contains(path)) {
      // Wait for the existing load to complete
      while (_currentlyLoading.contains(path)) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return _preloadedAnimations[path];
    }

    _currentlyLoading.add(path);

    try {
      final composition = await AssetLottie(path).load();
      _preloadedAnimations[path] = composition;
      return composition;
    } catch (e) {
      print('Error preloading animation $path: $e');
      _preloadedAnimations[path] = null;
      return null;
    } finally {
      _currentlyLoading.remove(path);
    }
  }

  /// Preload multiple animations
  Future<Map<String, LottieComposition?>> preloadAnimations(
      List<String> paths) async {
    final Map<String, LottieComposition?> results = {};

    // Load animations in parallel
    final futures = paths.map((path) => preloadAnimation(path));
    final compositions = await Future.wait(futures);

    for (int i = 0; i < paths.length; i++) {
      results[paths[i]] = compositions[i];
    }

    return results;
  }

  /// Preload common animations used throughout the app
  Future<void> preloadCommonAnimations() async {
    await preloadAnimations(commonAnimationPaths);
  }

  /// Get all preloaded animations
  Map<String, LottieComposition?> getAllPreloadedAnimations() {
    return Map.from(_preloadedAnimations);
  }

  /// Clear all preloaded animations to free memory
  void clearPreloadedAnimations() {
    _preloadedAnimations.clear();
  }

  /// Clear specific animations to free memory
  void clearAnimation(String path) {
    _preloadedAnimations.remove(path);
  }
}
