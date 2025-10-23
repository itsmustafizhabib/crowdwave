import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'firebase_auth_service.dart';
import '../core/error_handler.dart';
import '../controllers/chat_controller.dart';
import '../controllers/smart_matching_controller.dart';
import 'service_manager.dart';
import 'wallet_service.dart';

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

  // Flags to prevent redundant initialization
  bool _isChatInitInProgress = false;
  bool _chatSystemInitialized = false;

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

          // ✅ ENSURE WALLET EXISTS FOR LOGGED-IN USER
          await _ensureWalletExists(user);
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

  // Helper method to ensure wallet exists for user
  // Add a flag to prevent multiple concurrent calls
  bool _isWalletCheckInProgress = false;

  Future<void> _ensureWalletExists(User user) async {
    // Prevent concurrent wallet creation attempts
    if (_isWalletCheckInProgress) {
      if (kDebugMode) {
        print('⏳ Wallet check already in progress, skipping...');
      }
      return;
    }

    _isWalletCheckInProgress = true;

    try {
      final walletService = Get.find<WalletService>();
      final wallet = await walletService.getWallet(user.uid);

      if (wallet == null) {
        await walletService.createWallet(
          user.uid,
          currency: 'EUR', // Default to EUR
        );
        if (kDebugMode) {
          print('✅ Wallet created for user on app launch: ${user.uid}');
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ Wallet already exists for user: ${user.uid}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to create/check wallet on app launch: $e');
      }
      // Don't fail auth flow if wallet operations fail
    } finally {
      _isWalletCheckInProgress = false;
    }
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

  // ✅ INITIALIZE CHAT SYSTEM AND CORE SERVICES ON SUCCESSFUL LOGIN
  Future<void> _initializeChatSystem() async {
    // Prevent multiple concurrent initializations
    if (_isChatInitInProgress) {
      if (kDebugMode) {
        print('⏳ Chat initialization already in progress, skipping...');
      }
      return;
    }

    // Skip if already initialized
    if (_chatSystemInitialized && Get.isRegistered<ChatController>()) {
      if (kDebugMode) {
        print('✅ Chat system already initialized - skipping redundant call');
      }
      return;
    }

    _isChatInitInProgress = true;

    try {
      if (kDebugMode) {
        print('🚀 INITIALIZING SYSTEMS ON LOGIN...');
      }

      // ✅ ENSURE CORE SERVICES ARE AVAILABLE FIRST
      if (!ServiceManager.areServicesAvailable()) {
        if (kDebugMode) {
          print('🔧 Re-initializing core services...');
        }
        await ServiceManager.initializeCoreServices();
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

        _chatSystemInitialized = true;
      } else {
        if (kDebugMode) {
          print('✅ ChatController already exists - chat system active!');
        }
        _chatSystemInitialized = true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing systems: $e');
      }
      // Don't throw error - continue with login even if initialization fails
    } finally {
      _isChatInitInProgress = false;
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

      // Reset initialization flags so chat can be re-initialized on next login
      _chatSystemInitialized = false;
      _isChatInitInProgress = false;
      _isWalletCheckInProgress = false;

      // Remove SmartMatchingController if it exists
      if (Get.isRegistered<SmartMatchingController>()) {
        Get.delete<SmartMatchingController>();
      }

      // ✅ IMPROVED CLEANUP - Use ServiceManager for selective cleanup
      // Clean up user-specific services but preserve core services
      ServiceManager.cleanupUserServices();

      if (kDebugMode) {
        print('✅ Performed selective service cleanup preserving core services');
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
