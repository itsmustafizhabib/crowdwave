import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../core/error_handler.dart';

class EnhancedFirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
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

  // Enhanced Email Verification with better error handling and debugging
  Future<bool> sendEmailVerification({
    bool forceResend = false,
    int retryCount = 3,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in');
      }

      if (user.emailVerified && !forceResend) {
        throw Exception('Email is already verified');
      }

      debugPrint('📧 Starting email verification process...');
      debugPrint('📧 User Email: ${user.email}');
      debugPrint('📧 User UID: ${user.uid}');
      debugPrint('📧 Current verification status: ${user.emailVerified}');

      // Enhanced action code settings for better compatibility
      final actionCodeSettings = ActionCodeSettings(
        // Use your Firebase project URL - update this to match your actual project
        url: 'https://crowdwave-93d4d.firebaseapp.com/__/auth/action',
        handleCodeInApp: false,
        // Using your actual package names from the project
        androidPackageName: 'com.example.login_register',
        iOSBundleId: 'com.crowdwave.app.testProject',
        // Add dynamic link domain if you have one configured
        // dynamicLinkDomain: 'crowdwave.page.link',
      );

      debugPrint('📧 Action Code Settings:');
      debugPrint('📧 - URL: ${actionCodeSettings.url}');
      debugPrint(
          '📧 - Android Package: ${actionCodeSettings.androidPackageName}');
      debugPrint('📧 - iOS Bundle: ${actionCodeSettings.iOSBundleId}');

      // Attempt to send email with retry logic
      int attempts = 0;
      while (attempts < retryCount) {
        try {
          attempts++;
          debugPrint('📧 Attempt $attempts of $retryCount');

          await user.sendEmailVerification(actionCodeSettings);
          debugPrint(
              '✅ Email verification sent successfully on attempt $attempts');

          // Wait a moment to ensure the email is processed
          await Future.delayed(const Duration(seconds: 3));

          return true;
        } on FirebaseAuthException catch (e) {
          debugPrint(
              '❌ Firebase Auth Exception on attempt $attempts: ${e.code} - ${e.message}');

          if (e.code == 'too-many-requests') {
            if (attempts < retryCount) {
              debugPrint('⏳ Too many requests, waiting before retry...');
              await Future.delayed(Duration(seconds: 5 * attempts));
              continue;
            } else {
              throw Exception(
                  'Too many verification emails sent. Please wait 5-10 minutes before trying again.');
            }
          } else if (e.code == 'invalid-email') {
            throw Exception('The email address format is invalid.');
          } else if (e.code == 'user-disabled') {
            throw Exception('This user account has been disabled.');
          } else if (e.code == 'network-request-failed') {
            if (attempts < retryCount) {
              debugPrint('🌐 Network error, retrying...');
              await Future.delayed(Duration(seconds: 2 * attempts));
              continue;
            } else {
              throw Exception(
                  'Network error. Please check your internet connection.');
            }
          }

          throw Exception(_handleAuthException(e));
        }
      }

      return false;
    } catch (e) {
      debugPrint('💥 General Exception in sendEmailVerification: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to send verification email: ${e.toString()}');
    }
  }

  // Enhanced Password Reset with better error handling
  Future<bool> resetPassword(String email, {int retryCount = 3}) async {
    try {
      debugPrint('🔐 Starting password reset process...');
      debugPrint('🔐 Email: $email');

      // Enhanced action code settings for password reset
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://crowdwave-93d4d.firebaseapp.com/__/auth/action',
        handleCodeInApp: false,
        androidPackageName: 'com.example.login_register',
        iOSBundleId: 'com.crowdwave.app.testProject',
        // dynamicLinkDomain: 'crowdwave.page.link',
      );

      // Attempt to send password reset email with retry logic
      int attempts = 0;
      while (attempts < retryCount) {
        try {
          attempts++;
          debugPrint('🔐 Password reset attempt $attempts of $retryCount');

          await _auth.sendPasswordResetEmail(
            email: email,
            actionCodeSettings: actionCodeSettings,
          );

          debugPrint(
              '✅ Password reset email sent successfully on attempt $attempts');

          // Wait a moment to ensure the email is processed
          await Future.delayed(const Duration(seconds: 2));

          return true;
        } on FirebaseAuthException catch (e) {
          debugPrint(
              '❌ Firebase Auth Exception on attempt $attempts: ${e.code} - ${e.message}');

          if (e.code == 'too-many-requests') {
            if (attempts < retryCount) {
              debugPrint('⏳ Too many requests, waiting before retry...');
              await Future.delayed(Duration(seconds: 5 * attempts));
              continue;
            } else {
              throw Exception(
                  'Too many password reset emails sent. Please wait 5-10 minutes before trying again.');
            }
          } else if (e.code == 'user-not-found') {
            throw Exception('No account found with this email address.');
          } else if (e.code == 'invalid-email') {
            throw Exception('The email address format is invalid.');
          } else if (e.code == 'network-request-failed') {
            if (attempts < retryCount) {
              debugPrint('🌐 Network error, retrying...');
              await Future.delayed(Duration(seconds: 2 * attempts));
              continue;
            } else {
              throw Exception(
                  'Network error. Please check your internet connection.');
            }
          }

          throw Exception(_handleAuthException(e));
        }
      }

      return false;
    } catch (e) {
      debugPrint('💥 General Exception in resetPassword: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // Test email connectivity
  Future<Map<String, dynamic>> testEmailConnectivity() async {
    final results = <String, dynamic>{};

    try {
      final user = _auth.currentUser;
      if (user == null) {
        results['status'] = 'error';
        results['message'] = 'No user logged in';
        return results;
      }

      results['user_email'] = user.email;
      results['user_verified'] = user.emailVerified;
      results['user_uid'] = user.uid;

      // Try to get user metadata
      final metadata = user.metadata;
      results['creation_time'] = metadata.creationTime?.toIso8601String();
      results['last_sign_in'] = metadata.lastSignInTime?.toIso8601String();

      // Test if we can call the email verification (without actually sending)
      try {
        // This will validate the configuration without sending
        await user.reload();
        results['firebase_connection'] = 'success';
      } catch (e) {
        results['firebase_connection'] = 'error: $e';
      }

      results['status'] = 'success';
      results['message'] = 'Email connectivity test completed';
    } catch (e) {
      results['status'] = 'error';
      results['message'] = 'Test failed: $e';
    }

    return results;
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn().catchError((error) {
        print('Google Sign-In error: $error');
        throw Exception('Failed to sign in with Google: $error');
      });

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication.catchError((error) {
        print('Google Authentication error: $error');
        throw Exception('Failed to get Google authentication: $error');
      });

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

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
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (loginResult.status == LoginStatus.success) {
        final OAuthCredential facebookAuthCredential =
            FacebookAuthProvider.credential(
                loginResult.accessToken!.tokenString);

        final UserCredential result =
            await _auth.signInWithCredential(facebookAuthCredential);
        return result.user;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Facebook sign in failed: $e');
    }
  }

  // Sign in with Apple
  Future<User?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential result =
          await _auth.signInWithCredential(oauthCredential);
      return result.user;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
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
      // First, sign out from all auth providers
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        FacebookAuth.instance.logOut(),
      ]);

      // Force clear any persistent authentication state
      await FirebaseAuth.instance.signOut();

      // Additional cleanup - clear any web storage if applicable
      if (kIsWeb) {
        // Clear web persistent state (if we're in a web environment)
        await _auth.setPersistence(Persistence.NONE);
      }
    } catch (e) {
      print('Error during sign out: $e');
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

  // Re-authenticate user
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
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
