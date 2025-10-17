import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'token_manager.dart';

/// Authentication Helper Utilities
/// Provides utility methods for authentication validation and token refresh
class AuthHelper {
  /// Check if user is currently authenticated
  static bool isUserAuthenticated() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null;
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser?.uid;
  }

  /// Refresh user authentication token with retry mechanism
  static Future<bool> refreshAuthToken({int maxRetries = 3}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      log('❌ No user authenticated - cannot refresh token');
      return false;
    }

    try {
      // Use TokenManager to prevent concurrent refreshes
      final tokenManager = TokenManager();
      final freshToken = await tokenManager.getFreshToken(forceRefresh: true);

      if (freshToken != null && freshToken.isNotEmpty) {
        log('✅ Authentication token refreshed successfully via TokenManager');
        return true;
      } else {
        log('❌ Failed to get fresh token via TokenManager');
        tokenManager.clearCache();
        return false;
      }
    } catch (e) {
      log('❌ Failed to refresh token: $e');
      TokenManager().clearCache();
      return false;
    }
  }

  /// Validate user authentication state
  static Future<bool> validateAuthState() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        log('❌ No user authenticated');
        return false;
      }

      // Try to reload user to verify session is still valid
      await currentUser.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null) {
        log('❌ User session expired after reload');
        return false;
      }

      log('✅ User authentication state validated: ${refreshedUser.uid}');
      return true;
    } catch (e) {
      log('❌ Authentication state validation failed: $e');
      return false;
    }
  }

  /// Prepare for sensitive operation by ensuring fresh authentication
  static Future<bool> prepareForSensitiveOperation() async {
    try {
      log('🔧 Preparing for sensitive operation...');

      // Check authentication state
      if (!await validateAuthState()) {
        log('❌ Cannot prepare for sensitive operation - invalid auth state');
        return false;
      }

      // Refresh token
      if (!await refreshAuthToken()) {
        log('❌ Cannot prepare for sensitive operation - token refresh failed');
        return false;
      }

      // Additional verification: Try to get a fresh token to ensure it's valid
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          final freshToken = await currentUser.getIdToken(true);
          if (freshToken == null || freshToken.isEmpty) {
            log('❌ Fresh token is null or empty');
            return false;
          }

          // Parse token to check expiry (basic JWT structure check)
          final tokenParts = freshToken.split('.');
          if (tokenParts.length != 3) {
            log('⚠️ Token does not have expected JWT structure');
            return false;
          }

          log('✅ Fresh token obtained and validated');
          log('🔐 Token preview: ${freshToken.substring(0, 20)}...');
        } catch (tokenError) {
          log('❌ Failed to get fresh token for verification: $tokenError');
          return false;
        }
      }

      log('✅ Ready for sensitive operation');
      return true;
    } catch (e) {
      log('❌ Error preparing for sensitive operation: $e');
      return false;
    }
  }
}
