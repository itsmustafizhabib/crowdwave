import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Service for handling custom email operations via Cloud Functions
/// This service provides better email delivery through custom SMTP (Zoho)
class CustomEmailService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Send password reset email via Cloud Function
  /// This uses custom email templates and Zoho SMTP for better deliverability
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('🔐 Sending password reset email via Cloud Function...');
      debugPrint('🔐 Email: $email');

      final result = await _functions
          .httpsCallable('sendPasswordResetEmail')
          .call({'email': email});

      debugPrint('✅ Password reset email sent successfully');
      debugPrint('📧 Response: ${result.data}');

      return result.data['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Firebase Functions Exception: ${e.code} - ${e.message}');
      debugPrint('Details: ${e.details}');

      // Rethrow with user-friendly message
      throw Exception(_getFriendlyError(e));
    } catch (e) {
      debugPrint('💥 General Exception in sendPasswordResetEmail: $e');
      throw Exception('Failed to send password reset email. Please try again.');
    }
  }

  /// Send delivery update email
  /// Called when package status changes
  Future<bool> sendDeliveryUpdateEmail({
    required String recipientEmail,
    required Map<String, dynamic> packageDetails,
    required String status,
    String? trackingUrl,
  }) async {
    try {
      debugPrint('📦 Sending delivery update email...');
      debugPrint('📧 Recipient: $recipientEmail');
      debugPrint('📦 Status: $status');

      final result =
          await _functions.httpsCallable('sendDeliveryUpdateEmail').call({
        'recipientEmail': recipientEmail,
        'packageDetails': packageDetails,
        'status': status,
        'trackingUrl': trackingUrl,
      });

      debugPrint('✅ Delivery update email sent successfully');

      return result.data['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Firebase Functions Exception: ${e.code} - ${e.message}');
      debugPrint('Details: ${e.details}');

      throw Exception(_getFriendlyError(e));
    } catch (e) {
      debugPrint('💥 General Exception in sendDeliveryUpdateEmail: $e');
      throw Exception(
          'Failed to send delivery update email. Please try again.');
    }
  }

  /// Test email configuration
  /// Useful for debugging email setup
  Future<Map<String, dynamic>> testEmailConfig() async {
    try {
      debugPrint('🧪 Testing email configuration...');

      final result = await _functions.httpsCallable('testEmailConfig').call();

      debugPrint('✅ Email configuration test completed');
      debugPrint('📧 Result: ${result.data}');

      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Firebase Functions Exception: ${e.code} - ${e.message}');
      debugPrint('Details: ${e.details}');

      throw Exception(_getFriendlyError(e));
    } catch (e) {
      debugPrint('💥 General Exception in testEmailConfig: $e');
      throw Exception('Failed to test email configuration.');
    }
  }

  /// Convert Firebase Functions exceptions to user-friendly messages
  String _getFriendlyError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Please sign in to continue.';
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'not-found':
        return 'If an account exists with this email, a password reset link has been sent.';
      case 'invalid-argument':
        return 'Invalid email address. Please check and try again.';
      case 'deadline-exceeded':
        return 'Request timed out. Please check your internet connection and try again.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again in a moment.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
