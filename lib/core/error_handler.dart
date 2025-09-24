import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  static String getReadableError(dynamic error) {
    if (error == null) return 'Something went wrong. Please try again';

    // Handle FirebaseAuthException specifically
    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthError(error);
    }

    String errorString = error.toString().toLowerCase();

    // Network related errors
    if (errorString.contains('network') ||
        errorString.contains('internet') ||
        errorString.contains('connection')) {
      return 'Please check your internet connection and try again';
    }

    // Authentication errors
    if (errorString.contains('user not authenticated') ||
        errorString.contains('not authenticated')) {
      return 'Please sign in to continue';
    }

    if (errorString.contains('permission denied')) {
      return 'You don\'t have permission to perform this action';
    }

    // Firebase/Server errors
    if (errorString.contains('firebase') || errorString.contains('server')) {
      return 'Our services are temporarily unavailable. Please try again in a moment';
    }

    // Location errors
    if (errorString.contains('location') || errorString.contains('gps')) {
      return 'Unable to access location. Please enable location services';
    }

    // File/Photo errors
    if (errorString.contains('file') ||
        errorString.contains('image') ||
        errorString.contains('photo')) {
      return 'Unable to process the selected file. Please try another one';
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Request took too long. Please try again';
    }

    // Platform specific errors
    if (error is PlatformException) {
      switch (error.code) {
        case 'sign_in_canceled':
          return 'Sign in was cancelled';
        case 'sign_in_failed':
          return 'Sign in failed. Please try again';
        case 'network_error':
          return 'Network error. Please check your connection';
        default:
          return 'Something went wrong. Please try again';
      }
    }

    // Default fallback for unknown errors
    return 'Something went wrong. Please try again';
  }

  static String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password. Please try again';
      case 'email-already-in-use':
        return 'An account already exists with this email address';
      case 'weak-password':
        return 'Please choose a stronger password';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been temporarily disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again';
      case 'operation-not-allowed':
        return 'This sign-in method is not available';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action';
      case 'invalid-credential':
        return 'The login information is incorrect';
      case 'account-exists-with-different-credential':
        return 'An account exists with this email using a different sign-in method';
      case 'network-request-failed':
        return 'Check your internet connection and try again';
      case 'sign_in_failed':
        return 'Sign in was unsuccessful. Please try again';
      default:
        return 'Sign in failed. Please try again';
    }
  }

  static String getFieldValidationError(String field, String? value) {
    if (value == null || value.trim().isEmpty) {
      return '${_getFieldDisplayName(field)} is required';
    }
    return '';
  }

  static String _getFieldDisplayName(String field) {
    switch (field.toLowerCase()) {
      case 'email':
        return 'Email address';
      case 'password':
        return 'Password';
      case 'confirmpassword':
        return 'Password confirmation';
      case 'fullname':
      case 'displayname':
        return 'Full name';
      case 'phonenumber':
        return 'Phone number';
      default:
        return field;
    }
  }
}
