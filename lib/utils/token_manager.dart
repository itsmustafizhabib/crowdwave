import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';

/// Token Manager - Prevents concurrent token refreshes and manages token state
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  Completer<String?>? _refreshCompleter;
  String? _lastToken;
  DateTime? _lastRefreshTime;

  /// Get a fresh token, preventing concurrent refresh operations
  Future<String?> getFreshToken({bool forceRefresh = false}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      log('❌ TokenManager: No current user');
      clearCache(); // Clear cache when no user
      return null;
    }

    // If a refresh is already in progress, wait for it
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      log('⏳ TokenManager: Waiting for existing refresh to complete...');
      try {
        return await _refreshCompleter!.future;
      } catch (e) {
        log('❌ TokenManager: Existing refresh failed: $e');
        return null;
      }
    }

    // Check if we need to refresh
    final now = DateTime.now();
    final timeSinceLastRefresh = _lastRefreshTime != null
        ? now.difference(_lastRefreshTime!)
        : Duration(hours: 1);

    // More aggressive refresh policy for payment operations
    if (!forceRefresh &&
        _lastToken != null &&
        timeSinceLastRefresh.inMinutes < 2) {
      // Reduced from 5 to 2 minutes
      log('✅ TokenManager: Using cached token (refreshed ${timeSinceLastRefresh.inSeconds}s ago)');

      // Even with cached token, verify it's still valid for critical operations
      if (forceRefresh || timeSinceLastRefresh.inMinutes > 1) {
        try {
          // Quick validation without full refresh
          final testToken = await currentUser.getIdToken(false);
          if (testToken != _lastToken) {
            log('⚠️ TokenManager: Token mismatch detected, forcing refresh');
            // Fall through to refresh
          } else {
            return _lastToken;
          }
        } catch (e) {
          log('⚠️ TokenManager: Token validation failed, forcing refresh: $e');
          // Fall through to refresh
        }
      } else {
        return _lastToken;
      }
    }

    // Start a new refresh operation
    _refreshCompleter = Completer<String?>();

    try {
      log('🔄 TokenManager: Starting token refresh (force: $forceRefresh)...');

      // First try to reload user to ensure session is still valid
      try {
        await currentUser.reload();
        final reloadedUser = FirebaseAuth.instance.currentUser;
        if (reloadedUser == null) {
          throw Exception('User session expired during reload');
        }
      } catch (reloadError) {
        log('⚠️ TokenManager: User reload failed: $reloadError');
        // Continue with refresh attempt anyway
      }

      // Force refresh the token with multiple attempts
      String? freshToken;
      int maxAttempts = 3;

      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          log('🔄 TokenManager: Refresh attempt $attempt/$maxAttempts');
          freshToken = await currentUser.getIdToken(true);

          if (freshToken != null && freshToken.isNotEmpty) {
            // Validate token structure (basic JWT check)
            final parts = freshToken.split('.');
            if (parts.length != 3) {
              throw Exception('Invalid token structure');
            }

            log('✅ TokenManager: Token refresh successful on attempt $attempt');
            break;
          } else {
            throw Exception('Received null or empty token');
          }
        } catch (attemptError) {
          log('❌ TokenManager: Refresh attempt $attempt failed: $attemptError');

          if (attempt < maxAttempts) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
          } else {
            throw attemptError;
          }
        }
      }

      if (freshToken != null && freshToken.isNotEmpty) {
        _lastToken = freshToken;
        _lastRefreshTime = now;
        log('✅ TokenManager: Token refreshed successfully');
        log('🔐 TokenManager: Token length: ${freshToken.length}');

        _refreshCompleter!.complete(freshToken);
        return freshToken;
      } else {
        log('❌ TokenManager: All refresh attempts failed');
        clearCache();
        _refreshCompleter!.complete(null);
        return null;
      }
    } catch (e) {
      log('❌ TokenManager: Token refresh failed: $e');
      clearCache();
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Clear cached token (use when authentication fails)
  void clearCache() {
    log('🧹 TokenManager: Clearing token cache');
    _lastToken = null;
    _lastRefreshTime = null;
  }

  /// Get token info for debugging
  Map<String, dynamic> getTokenInfo() {
    return {
      'has_cached_token': _lastToken != null,
      'last_refresh_time': _lastRefreshTime?.toIso8601String(),
      'time_since_refresh_minutes': _lastRefreshTime != null
          ? DateTime.now().difference(_lastRefreshTime!).inMinutes
          : null,
      'refresh_in_progress':
          _refreshCompleter != null && !_refreshCompleter!.isCompleted,
    };
  }
}
