import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage onboarding completion state
class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  static const String _onboardingCompleteKey = 'has_completed_onboarding';
  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    if (!_initialized) await initialize();
    return _prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  /// Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    if (!_initialized) await initialize();
    await _prefs.setBool(_onboardingCompleteKey, true);
  }

  /// Reset onboarding state (for testing or first-time users)
  Future<void> resetOnboardingState() async {
    if (!_initialized) await initialize();
    await _prefs.remove(_onboardingCompleteKey);
  }
}
