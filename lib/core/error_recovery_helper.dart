import 'package:flutter/material.dart';
import '../widgets/enhanced_snackbar.dart';
import '../core/error_handler.dart';

class ErrorRecoveryHelper {
  /// Show error with retry option
  static void showErrorWithRetry(
    BuildContext context,
    dynamic error,
    VoidCallback onRetry, {
    String? customMessage,
    String? retryText,
  }) {
    final message = customMessage ?? ErrorHandler.getReadableError(error);

    EnhancedSnackBar.showError(
      context,
      message,
      onRetry: onRetry,
      retryText: retryText ?? 'Try Again',
    );
  }

  /// Show network error with retry
  static void showNetworkError(
    BuildContext context,
    VoidCallback onRetry,
  ) {
    EnhancedSnackBar.showError(
      context,
      'Check your internet connection and try again',
      onRetry: onRetry,
      retryText: 'Retry',
    );
  }

  /// Show authentication error with sign-in option
  static void showAuthError(
    BuildContext context,
    VoidCallback onSignIn,
  ) {
    EnhancedSnackBar.showError(
      context,
      'Please sign in to continue',
      onRetry: onSignIn,
      retryText: 'Sign In',
    );
  }

  /// Show permission error with settings option
  static void showPermissionError(
    BuildContext context,
    String permission,
    VoidCallback onOpenSettings,
  ) {
    EnhancedSnackBar.showError(
      context,
      'Permission required for $permission. Please enable in settings.',
      onRetry: onOpenSettings,
      retryText: 'Settings',
    );
  }

  /// Show generic error with helpful context
  static void showContextualError(
    BuildContext context,
    String action,
    dynamic error, {
    VoidCallback? onRetry,
  }) {
    final message =
        'Failed to $action. ${ErrorHandler.getReadableError(error)}';

    if (onRetry != null) {
      EnhancedSnackBar.showError(
        context,
        message,
        onRetry: onRetry,
        retryText: 'Try Again',
      );
    } else {
      EnhancedSnackBar.showError(context, message);
    }
  }

  /// Show loading error with refresh option
  static void showLoadingError(
    BuildContext context,
    VoidCallback onRefresh,
  ) {
    EnhancedSnackBar.showError(
      context,
      'Unable to load content. Please try refreshing.',
      onRetry: onRefresh,
      retryText: 'Refresh',
    );
  }

  /// Show form submission error
  static void showSubmissionError(
    BuildContext context,
    String formType,
    dynamic error,
    VoidCallback onRetry,
  ) {
    final message =
        'Failed to submit $formType. ${ErrorHandler.getReadableError(error)}';

    EnhancedSnackBar.showError(
      context,
      message,
      onRetry: onRetry,
      retryText: 'Try Again',
    );
  }
}
