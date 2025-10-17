import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Authentication Diagnostic Tool
/// Helps debug authentication issues during payment processing
class AuthDiagnostic {
  /// Run comprehensive authentication diagnostics
  static Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{};

    try {
      // 1. Check basic authentication
      results['step1_basic_auth'] = await _checkBasicAuth();

      // 2. Check token validity
      results['step2_token_validity'] = await _checkTokenValidity();

      // 3. Test token refresh
      results['step3_token_refresh'] = await _checkTokenRefresh();

      // 4. Test Cloud Functions auth
      results['step4_cloud_functions'] = await _testCloudFunctionsAuth();

      results['overall_status'] = 'success';
      results['timestamp'] = DateTime.now().toIso8601String();
    } catch (e) {
      results['error'] = e.toString();
      results['overall_status'] = 'failed';
      results['timestamp'] = DateTime.now().toIso8601String();
    }

    return results;
  }

  /// Check basic authentication state
  static Future<Map<String, dynamic>> _checkBasicAuth() async {
    final result = <String, dynamic>{};

    try {
      final user = FirebaseAuth.instance.currentUser;

      result['user_exists'] = user != null;
      result['user_id'] = user?.uid;
      result['user_email'] = user?.email;
      result['is_anonymous'] = user?.isAnonymous ?? false;
      result['email_verified'] = user?.emailVerified ?? false;

      if (user != null) {
        result['provider_data'] = user.providerData
            .map((p) => {
                  'provider_id': p.providerId,
                  'uid': p.uid,
                  'email': p.email,
                })
            .toList();
      }

      result['status'] = 'success';
    } catch (e) {
      result['status'] = 'error';
      result['error'] = e.toString();
    }

    return result;
  }

  /// Check token validity
  static Future<Map<String, dynamic>> _checkTokenValidity() async {
    final result = <String, dynamic>{};

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        result['status'] = 'no_user';
        return result;
      }

      // Get current token
      final token = await user.getIdToken(false);
      result['has_token'] = token != null;
      result['token_length'] = token?.length ?? 0;

      if (token != null) {
        // Parse token to check expiry (basic check)
        final parts = token.split('.');
        result['token_parts'] = parts.length;
        result['token_preview'] =
            token.length > 20 ? token.substring(0, 20) + '...' : token;
      }

      result['status'] = 'success';
    } catch (e) {
      result['status'] = 'error';
      result['error'] = e.toString();
    }

    return result;
  }

  /// Check token refresh capability
  static Future<Map<String, dynamic>> _checkTokenRefresh() async {
    final result = <String, dynamic>{};

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        result['status'] = 'no_user';
        return result;
      }

      // Test user reload
      await user.reload();
      final reloadedUser = FirebaseAuth.instance.currentUser;
      result['reload_successful'] = reloadedUser != null;
      result['uid_matches'] = reloadedUser?.uid == user.uid;

      // Test token refresh
      final refreshStartTime = DateTime.now();
      final refreshedToken = await user.getIdToken(true);
      final refreshDuration = DateTime.now().difference(refreshStartTime);

      result['refresh_successful'] = refreshedToken != null;
      result['refresh_duration_ms'] = refreshDuration.inMilliseconds;
      result['refreshed_token_length'] = refreshedToken?.length ?? 0;

      result['status'] = 'success';
    } catch (e) {
      result['status'] = 'error';
      result['error'] = e.toString();
    }

    return result;
  }

  /// Test Cloud Functions authentication
  static Future<Map<String, dynamic>> _testCloudFunctionsAuth() async {
    final result = <String, dynamic>{};

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        result['status'] = 'no_user';
        return result;
      }

      // Refresh token before test
      await user.getIdToken(true);

      // Test the testAuth function
      final callable = FirebaseFunctions.instance.httpsCallable('testAuth');
      final callStartTime = DateTime.now();

      final response = await callable.call();
      final callDuration = DateTime.now().difference(callStartTime);

      result['call_successful'] = true;
      result['call_duration_ms'] = callDuration.inMilliseconds;
      result['response_data'] = response.data;
      result['response_uid'] = response.data['uid'];
      result['uid_matches'] = response.data['uid'] == user.uid;

      result['status'] = 'success';
    } catch (e) {
      result['status'] = 'error';
      result['error'] = e.toString();

      if (e is FirebaseFunctionsException) {
        result['function_error_code'] = e.code;
        result['function_error_message'] = e.message;
      }
    }

    return result;
  }

  /// Print diagnostics in a readable format
  static void printDiagnostics(Map<String, dynamic> diagnostics) {
    log('🔍 AUTHENTICATION DIAGNOSTICS');
    log('==============================');

    for (final entry in diagnostics.entries) {
      if (entry.value is Map) {
        log('📋 ${entry.key.toUpperCase()}:');
        for (final subEntry in (entry.value as Map).entries) {
          log('  - ${subEntry.key}: ${subEntry.value}');
        }
      } else {
        log('📋 ${entry.key}: ${entry.value}');
      }
      log('');
    }
  }
}
