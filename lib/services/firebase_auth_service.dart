import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../core/error_handler.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Use the web client ID for web platform
    clientId: kIsWeb
        ? '351442774180-8h5ngsn5sok47lui3hnpjijv2l18k1km.apps.googleusercontent.com'
        : null,
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(ErrorHandler.getReadableError(e));
    }
  }

  // Register with email and password
  Future<User?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  // Sign in with Google - Modern implementation with web support
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow - with additional error handling for web
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn().catchError((error) {
        print('Google Sign-In error: $error');
        throw Exception('Failed to sign in with Google: $error');
      });

      if (googleUser == null) {
        // User cancelled the sign-in flow
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication.catchError((error) {
        print('Google Authentication error: $error');
        throw Exception('Failed to get Google authentication: $error');
      });

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential result =
          await _auth.signInWithCredential(credential);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // Sign in with Facebook
  Future<User?> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (loginResult.status == LoginStatus.success) {
        // Create a credential from the access token
        final OAuthCredential facebookAuthCredential =
            FacebookAuthProvider.credential(
                loginResult.accessToken!.tokenString);

        // Once signed in, return the UserCredential
        final UserCredential result =
            await _auth.signInWithCredential(facebookAuthCredential);
        return result.user;
      } else if (loginResult.status == LoginStatus.cancelled) {
        // User cancelled the sign-in flow
        return null;
      } else {
        throw Exception('Facebook sign in failed: ${loginResult.message}');
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Facebook sign in failed: $e');
    }
  }

  // Sign in with Apple
  Future<User?> signInWithApple() async {
    try {
      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: "com.crowdwave.service", // ✅ Your Apple Service ID
          redirectUri: Uri.parse(
            "https://crowdwave-93d4d.firebaseapp.com/__/auth/handler", // ✅ Firebase redirect URI
          ),
        ),
      );

      // Create an `OAuthCredential` from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in the user with Firebase
      final UserCredential result =
          await _auth.signInWithCredential(oauthCredential);

      // Update display name if available from Apple ID
      if (appleCredential.givenName != null &&
          appleCredential.familyName != null) {
        await result.user?.updateDisplayName(
          '${appleCredential.givenName} ${appleCredential.familyName}',
        );
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        // User cancelled the sign-in flow
        return null;
      } else {
        throw Exception('Apple Sign In failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Apple sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        FacebookAuth.instance.logOut(),
      ]);
    } catch (e) {
      // Log error but don't throw - user should still be signed out of Firebase
      print('Error during sign out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  // Update user profile
  Future<void> updateUserProfile(
      {String? displayName, String? photoURL}) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  // Delete user account
  Future<void> deleteUserAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  // Re-authenticate user (required for sensitive operations)
  Future<void> reauthenticateUser(String email, String password) async {
    try {
      final AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await _auth.currentUser?.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  // Check if user is email verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in');
      }

      if (user.emailVerified) {
        throw Exception('Email is already verified');
      }

      print('Sending verification email to: ${user.email}');

      // Add action code settings for better Zoho SMTP compatibility
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://crowdwave-93d4d.firebaseapp.com/__/auth/action',
        handleCodeInApp: false,
        androidPackageName: 'com.example.crowdwave',
        iOSBundleId: 'com.example.crowdwave',
      );

      await user.sendEmailVerification(actionCodeSettings);
      print('Verification email sent successfully');

      // Wait a moment to let the email process
      await Future.delayed(const Duration(seconds: 2));
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');

      // Handle specific SMTP/email delivery errors
      if (e.code == 'too-many-requests') {
        throw Exception(
            'Too many verification emails sent. Please wait before trying again.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address format.');
      } else if (e.code == 'user-disabled') {
        throw Exception('This user account has been disabled.');
      }

      throw Exception(_handleAuthException(e));
    } catch (e) {
      print('General Exception in sendEmailVerification: $e');
      throw Exception('Failed to send verification email: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://crowdwaveflutter.page.link/password-reset',
        handleCodeInApp: true,
        androidPackageName: 'com.crowdwave.flutter',
        androidInstallApp: true,
        androidMinimumVersion: '1',
        iOSBundleId: 'com.example.crowdwave',
      );

      await _auth.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      print('Password reset email sent successfully to: $email');
    } on FirebaseAuthException catch (e) {
      print(
          'Firebase Auth Exception in sendPasswordResetEmail: ${e.code} - ${e.message}');
      throw Exception(_handleAuthException(e));
    } catch (e) {
      print('General Exception in sendPasswordResetEmail: $e');
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Confirm password reset with code
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
      print('Password reset confirmed successfully');
    } on FirebaseAuthException catch (e) {
      print(
          'Firebase Auth Exception in confirmPasswordReset: ${e.code} - ${e.message}');

      // Handle specific password reset errors
      if (e.code == 'expired-action-code') {
        throw Exception('Reset code has expired. Please request a new one.');
      } else if (e.code == 'invalid-action-code') {
        throw Exception('Invalid reset code. Please check and try again.');
      } else if (e.code == 'weak-password') {
        throw Exception(
            'Password is too weak. Please choose a stronger password.');
      }

      throw Exception(_handleAuthException(e));
    } catch (e) {
      print('General Exception in confirmPasswordReset: $e');
      throw Exception('Failed to reset password: $e');
    }
  }

  // Verify password reset code (optional - to check if code is valid before resetting)
  Future<String> verifyPasswordResetCode(String code) async {
    try {
      final email = await _auth.verifyPasswordResetCode(code);
      return email;
    } on FirebaseAuthException catch (e) {
      print(
          'Firebase Auth Exception in verifyPasswordResetCode: ${e.code} - ${e.message}');

      if (e.code == 'expired-action-code') {
        throw Exception('Reset code has expired. Please request a new one.');
      } else if (e.code == 'invalid-action-code') {
        throw Exception('Invalid reset code. Please check and try again.');
      }

      throw Exception(_handleAuthException(e));
    } catch (e) {
      print('General Exception in verifyPasswordResetCode: $e');
      throw Exception('Failed to verify reset code: $e');
    }
  }

  // Handle Firebase Auth exceptions with user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      case 'invalid-credential':
        return 'Invalid credentials provided.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'expired-action-code':
        return 'The action code has expired. Please request a new one.';
      case 'invalid-action-code':
        return 'The action code is invalid. Please check and try again.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
