import 'dart:developer';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_helper.dart';
import 'token_manager.dart';

/// Payment Authentication Debugger
/// Comprehensive debugging utilities for payment authentication issues
class PaymentAuthDebugger {
  /// Run comprehensive payment authentication test
  static Future<Map<String, dynamic>> runPaymentAuthTest() async {
    final results = <String, dynamic>{};

    try {
      log('🔍 Starting comprehensive payment authentication test...');

      // 1. Check basic Firebase Auth state
      results['step1_basic_auth'] = await _checkBasicAuth();

      // 2. Test token operations
      results['step2_token_test'] = await _testTokenOperations();

      // 3. Test Cloud Functions authentication
      results['step3_functions_auth'] = await _testCloudFunctionsAuth();

      // 4. Test payment-specific authentication
      results['step4_payment_auth'] = await _testPaymentAuth();

      results['overall_status'] = 'success';
      results['timestamp'] = DateTime.now().toIso8601String();

      log('✅ Payment authentication test completed successfully');
    } catch (e) {
      results['error'] = e.toString();
      results['overall_status'] = 'failed';
      results['timestamp'] = DateTime.now().toIso8601String();

      log('❌ Payment authentication test failed: $e');
    }

    return results;
  }

  /// Check basic Firebase Auth state
  static Future<Map<String, dynamic>> _checkBasicAuth() async {
    final result = <String, dynamic>{};

    try {
      final user = FirebaseAuth.instance.currentUser;

      result['user_exists'] = user != null;
      result['user_id'] = user?.uid;
      result['user_email'] = user?.email;
      result['email_verified'] = user?.emailVerified;
      result['is_anonymous'] = user?.isAnonymous;

      if (user != null) {
        result['provider_data'] = user.providerData
            .map((p) => {
                  'provider_id': p.providerId,
                  'uid': p.uid,
                  'email': p.email,
                })
            .toList();
      }

      // Test AuthHelper
      result['auth_helper_authenticated'] = AuthHelper.isUserAuthenticated();
      result['auth_helper_user_id'] = AuthHelper.getCurrentUserId();
      result['auth_helper_state_valid'] = await AuthHelper.validateAuthState();

      result['status'] = 'success';
    } catch (e) {
      result['status'] = 'error';
      result['error'] = e.toString();
    }

    return result;
  }

  /// Test token operations
  static Future<Map<String, dynamic>> _testTokenOperations() async {
    final result = <String, dynamic>{};

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        result['status'] = 'no_user';
        return result;
      }

      // Test cached token
      final cachedToken = await user.getIdToken(false);
      result['cached_token_exists'] = cachedToken != null;
      result['cached_token_length'] = cachedToken?.length ?? 0;

      // Test fresh token
      final freshToken = await user.getIdToken(true);
      result['fresh_token_exists'] = freshToken != null;
      result['fresh_token_length'] = freshToken?.length ?? 0;
      result['tokens_match'] = cachedToken == freshToken;

      // Test TokenManager
      final tokenManager = TokenManager();
      result['token_manager_info'] = tokenManager.getTokenInfo();

      final managedToken = await tokenManager.getFreshToken(forceRefresh: true);
      result['managed_token_exists'] = managedToken != null;
      result['managed_token_matches_fresh'] = managedToken == freshToken;

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
      // Test basic auth function
      try {
        final testAuth = FirebaseFunctions.instanceFor(region: 'us-central1')
            .httpsCallable('testAuth');

        final authResult = await testAuth.call();
        result['test_auth_success'] = true;
        result['test_auth_response'] = authResult.data;
      } catch (e) {
        result['test_auth_success'] = false;
        result['test_auth_error'] = e.toString();
      }

      // Test debug auth function
      try {
        final debugAuth = FirebaseFunctions.instanceFor(region: 'us-central1')
            .httpsCallable('debugPaymentAuth');

        final debugResult = await debugAuth.call();
        result['debug_auth_success'] = true;
        result['debug_auth_response'] = debugResult.data;
      } catch (e) {
        result['debug_auth_success'] = false;
        result['debug_auth_error'] = e.toString();
      }

      result['status'] = 'success';
    } catch (e) {
      result['status'] = 'error';
      result['error'] = e.toString();
    }

    return result;
  }

  /// Test payment-specific authentication
  static Future<Map<String, dynamic>> _testPaymentAuth() async {
    final result = <String, dynamic>{};

    try {
      // Test authentication preparation for payment
      result['auth_helper_prepare'] =
          await AuthHelper.prepareForSensitiveOperation();

      // Simulate the payment authentication flow
      final tokenManager = TokenManager();
      tokenManager.clearCache();

      final paymentToken = await tokenManager.getFreshToken(forceRefresh: true);
      result['payment_token_exists'] = paymentToken != null;
      result['payment_token_length'] = paymentToken?.length ?? 0;

      // Test token immediately after refresh
      await Future.delayed(Duration(milliseconds: 100));

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final verificationToken = await user.getIdToken(false);
        result['verification_token_matches'] =
            verificationToken == paymentToken;
      }

      result['token_manager_final_state'] = tokenManager.getTokenInfo();
      result['status'] = 'success';
    } catch (e) {
      result['status'] = 'error';
      result['error'] = e.toString();
    }

    return result;
  }

  /// Print detailed test results
  static void printTestResults(Map<String, dynamic> results) {
    log('📊 PAYMENT AUTHENTICATION TEST RESULTS');
    log('=' * 50);

    results.forEach((key, value) {
      log('$key: ${_formatValue(value)}');
    });

    log('=' * 50);
  }

  static String _formatValue(dynamic value) {
    if (value is Map) {
      return value.toString();
    } else if (value is List) {
      return value.toString();
    } else {
      return value.toString();
    }
  }
}
