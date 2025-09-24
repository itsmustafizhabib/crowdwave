import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'firebase_auth_service.dart';
import '../core/error_handler.dart';
import '../controllers/chat_controller.dart';
import '../controllers/smart_matching_controller.dart';

class AuthStateService extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  User? _currentUser;
  bool _isLoading = true;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isEmailVerified => _currentUser?.emailVerified ?? false;

  // Stream subscription
  StreamSubscription<User?>? _authStateSubscription;

  AuthStateService() {
    _initializeAuthState();
  }

  void _initializeAuthState() {
    _authStateSubscription = _authService.authStateChanges.listen(
      (User? user) async {
        _currentUser = user;
        _isLoading = false;
        _error = null;

        // ✅ AUTO-INITIALIZE CHAT FOR EXISTING LOGGED-IN USERS (APP STARTUP)
        if (user != null) {
          await _initializeChatSystem();
        } else {
          // User logged out - cleanup will be handled by signOut method
        }

        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user =
          await _authService.signInWithEmailAndPassword(email, password);

      if (user != null) {
        // ✅ AUTO-INITIALIZE CHAT SYSTEM ON SUCCESSFUL LOGIN
        await _initializeChatSystem();
      }

      return user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register with email and password
  Future<bool> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user =
          await _authService.registerWithEmailAndPassword(email, password);

      if (user != null) {
        // ✅ AUTO-INITIALIZE CHAT SYSTEM ON SUCCESSFUL REGISTRATION
        await _initializeChatSystem();
      }

      return user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await _authService.signInWithGoogle();

      if (user != null) {
        // ✅ AUTO-INITIALIZE CHAT SYSTEM ON SUCCESSFUL GOOGLE LOGIN
        await _initializeChatSystem();
      }

      return user != null;
    } catch (e) {
      _error = ErrorHandler.getReadableError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      _currentUser = null;
      _error = null;

      // Clean up GetX controllers to prevent data leakage between users
      _cleanupControllers();
    } catch (e) {
      _error = ErrorHandler.getReadableError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ INITIALIZE CHAT SYSTEM ON SUCCESSFUL LOGIN
  Future<void> _initializeChatSystem() async {
    try {
      if (kDebugMode) {
        print('🚀 INITIALIZING CHAT SYSTEM ON LOGIN...');
      }

      // Create ChatController if it doesn't exist (permanent to survive navigation)
      if (!Get.isRegistered<ChatController>()) {
        Get.put(ChatController(), permanent: true);

        if (kDebugMode) {
          print('✅ ChatController created and initialized!');
        }

        // Small delay to ensure proper initialization
        await Future.delayed(const Duration(milliseconds: 500));

        if (kDebugMode) {
          print('✅ Chat system ready for real-time messaging!');
        }
      } else {
        if (kDebugMode) {
          print('✅ ChatController already exists - chat system active!');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing chat system: $e');
      }
      // Don't throw error - continue with login even if chat fails
    }
  }

  // Clean up GetX controllers when user signs out
  void _cleanupControllers() {
    try {
      // ✅ PROPER CHAT CLEANUP ON LOGOUT
      if (Get.isRegistered<ChatController>()) {
        final chatController = Get.find<ChatController>();
        chatController.cleanupOnLogout(); // Clean user data first
        Get.delete<ChatController>(); // Then dispose controller

        if (kDebugMode) {
          print('✅ ChatController properly cleaned up on logout');
        }
      }

      // Remove SmartMatchingController if it exists
      if (Get.isRegistered<SmartMatchingController>()) {
        Get.delete<SmartMatchingController>();
      }

      // Force cleanup of any other controllers that might be registered
      // This prevents stale user data from persisting after logout
      try {
        // Reset any potential cached data in GetX controllers
        Get.reset(clearRouteBindings: true);

        if (kDebugMode) {
          print('✅ Performed GetX reset to clear all cached controllers');
        }
      } catch (e) {
        print('Error during GetX reset: $e');
      }
    } catch (e) {
      // Ignore errors during cleanup
      print('Error cleaning up controllers: $e');
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _error = ErrorHandler.getReadableError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(
      {String? displayName, String? photoURL}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.updateUserProfile(
          displayName: displayName, photoURL: photoURL);
      return true;
    } catch (e) {
      _error = ErrorHandler.getReadableError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.sendEmailVerification();
      return true;
    } catch (e) {
      _error = ErrorHandler.getReadableError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh auth state
  void refreshAuthState() {
    _currentUser = _authService.currentUser;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
