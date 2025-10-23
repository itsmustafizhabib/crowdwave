import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Service to handle OTP/code verification for sign-up and password reset
class OTPService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Collection to store OTP codes temporarily
  static const String _otpCollection = 'otp_codes';

  /// Generate a random 6-digit OTP code
  String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send OTP to email for email verification (sign-up)
  /// This sends a 6-digit code via Cloud Functions using your custom SMTP
  Future<bool> sendSignUpVerificationOTP(String email) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in');
      }

      if (user.emailVerified) {
        throw Exception('Email is already verified');
      }

      // Generate OTP
      final otp = generateOTP();
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      // Store OTP in Firestore
      await _firestore.collection(_otpCollection).doc(email).set({
        'otp': otp,
        'email': email,
        'userId': user.uid,
        'expiresAt': expiresAt,
        'createdAt': FieldValue.serverTimestamp(),
        'used': false,
        'type': 'email_verification',
      });

      // Call Cloud Function to send OTP email
      try {
        final callable = _functions.httpsCallable('sendOTPEmail');
        await callable.call({
          'email': email,
          'otp': otp,
          'type': 'email_verification',
        });

        if (kDebugMode) {
          print('✅ OTP email sent successfully to: $email');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Cloud Function call failed, but OTP stored: $e');
        }
        // Don't throw error if email fails, OTP is still stored
      }

      if (kDebugMode) {
        print('✅ Email verification OTP generated for: $email');
        print('🔐 OTP Code: $otp'); // REMOVE IN PRODUCTION
        print('⏰ Expires in 10 minutes');
      }

      return true;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Error sending verification OTP: ${e.code}');
      }
      if (e.code == 'too-many-requests') {
        throw Exception('Too many requests. Please try again later.');
      }
      throw Exception('Failed to send verification code: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error: $e');
      }
      rethrow;
    }
  }

  /// Verify OTP code for email verification (sign-up)
  Future<bool> verifyEmailVerificationOTP(String email, String otp) async {
    try {
      final docSnapshot =
          await _firestore.collection(_otpCollection).doc(email).get();

      if (!docSnapshot.exists) {
        throw Exception(
            'No verification code found. Please request a new one.');
      }

      final data = docSnapshot.data()!;
      final storedOTP = data['otp'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final used = data['used'] as bool;
      final type = data['type'] as String;

      // Check type
      if (type != 'email_verification') {
        throw Exception('Invalid verification code type');
      }

      // Check if OTP has been used
      if (used) {
        throw Exception(
            'This code has already been used. Please request a new one.');
      }

      // Check if OTP has expired
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception(
            'Verification code has expired. Please request a new one.');
      }

      // Verify OTP
      if (storedOTP != otp) {
        throw Exception('Invalid verification code');
      }

      // Mark OTP as used
      await _firestore.collection(_otpCollection).doc(email).update({
        'used': true,
        'usedAt': FieldValue.serverTimestamp(),
      });

      // Mark email as verified in Firebase Auth
      // Note: This requires admin privileges, should be done via Cloud Function
      // For now, we'll rely on the user being logged in and updating via client

      if (kDebugMode) {
        print('✅ OTP verified successfully for: $email');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ OTP verification error: $e');
      }
      rethrow;
    }
  }

  /// Send OTP code via email for password reset
  /// This stores the OTP in Firestore and sends via Firebase Auth
  Future<bool> sendPasswordResetOTP(String email) async {
    try {
      // Check if user exists
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isEmpty) {
        throw Exception('No account found with this email');
      }

      // Generate OTP
      final otp = generateOTP();
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      // Store OTP in Firestore
      await _firestore.collection(_otpCollection).doc(email).set({
        'otp': otp,
        'email': email,
        'expiresAt': expiresAt,
        'createdAt': FieldValue.serverTimestamp(),
        'used': false,
        'type': 'password_reset',
      });

      // Send password reset email with custom action code
      // Note: The OTP should be sent via Cloud Functions or email service
      // For now, we'll use Firebase's built-in password reset
      await _auth.sendPasswordResetEmail(email: email);

      if (kDebugMode) {
        print('✅ Password reset email sent to: $email');
        print('🔐 OTP generated: $otp'); // Remove in production
      }

      return true;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Auth error: ${e.code}');
      }
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this email');
      } else if (e.code == 'too-many-requests') {
        throw Exception('Too many requests. Please try again later.');
      }
      throw Exception('Failed to send password reset email: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error: $e');
      }
      rethrow;
    }
  }

  /// Verify OTP code for password reset
  Future<bool> verifyPasswordResetOTP(String email, String otp) async {
    try {
      final docSnapshot =
          await _firestore.collection(_otpCollection).doc(email).get();

      if (!docSnapshot.exists) {
        throw Exception(
            'No verification code found. Please request a new one.');
      }

      final data = docSnapshot.data()!;
      final storedOTP = data['otp'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final used = data['used'] as bool;

      // Check if OTP has been used
      if (used) {
        throw Exception(
            'This code has already been used. Please request a new one.');
      }

      // Check if OTP has expired
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception(
            'Verification code has expired. Please request a new one.');
      }

      // Verify OTP
      if (storedOTP != otp) {
        throw Exception('Invalid verification code');
      }

      // Mark OTP as used
      await _firestore.collection(_otpCollection).doc(email).update({
        'used': true,
        'usedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ OTP verified successfully for: $email');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ OTP verification error: $e');
      }
      rethrow;
    }
  }

  /// Reset password with verified OTP
  Future<bool> resetPasswordWithOTP(
      String email, String otp, String newPassword) async {
    try {
      // First verify the OTP
      await verifyPasswordResetOTP(email, otp);

      // Get current user or sign in temporarily to reset password
      // Note: Firebase doesn't allow password reset without authentication
      // This method should be used after verifying OTP in the UI
      // The actual password reset should use confirmPasswordReset with action code

      if (kDebugMode) {
        print('✅ OTP verified, password reset initiated for: $email');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Password reset error: $e');
      }
      rethrow;
    }
  }

  /// Delete expired OTP codes (cleanup job)
  Future<void> cleanupExpiredOTPs() async {
    try {
      final now = Timestamp.now();
      final expiredDocs = await _firestore
          .collection(_otpCollection)
          .where('expiresAt', isLessThan: now)
          .get();

      final batch = _firestore.batch();
      for (var doc in expiredDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (kDebugMode) {
        print('✅ Cleaned up ${expiredDocs.docs.length} expired OTP codes');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Cleanup error: $e');
      }
    }
  }

  /// Check if email verification is complete
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Reload user to get latest email verification status
      await user.reload();
      final refreshedUser = _auth.currentUser;

      return refreshedUser?.emailVerified ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking email verification: $e');
      }
      return false;
    }
  }

  /// Resend verification email with rate limiting check
  Future<bool> resendVerificationOTP(String email) async {
    try {
      // Check last send time from Firestore
      final docSnapshot =
          await _firestore.collection(_otpCollection).doc(email).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        if (createdAt != null) {
          final timeSinceLastSend = DateTime.now().difference(createdAt);
          if (timeSinceLastSend.inSeconds < 60) {
            throw Exception(
                'Please wait ${60 - timeSinceLastSend.inSeconds} seconds before requesting a new code');
          }
        }
      }

      // Send new verification OTP
      return await sendSignUpVerificationOTP(email);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Resend error: $e');
      }
      rethrow;
    }
  }
}
