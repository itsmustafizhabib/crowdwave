import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';

/// 🚨 Centralized Error Handling Service
/// Provides consistent error handling, logging, and user feedback across the app
class ErrorHandlingService {
  static final ErrorHandlingService _instance =
      ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  /// Initialize error handling service
  Future<void> initialize() async {
    if (!kDebugMode &&
        EnvironmentConfig.currentEnvironment == Environment.production) {
      // Set up Flutter error handling for production
      FlutterError.onError = (errorDetails) {
        developer.log(
          'Flutter Fatal Error: ${errorDetails.exception}',
          name: 'CrowdWave.Fatal',
          level: 1200,
          error: errorDetails.exception,
          stackTrace: errorDetails.stack,
        );
      };
    }
  }

  /// Log error with context and severity
  void logError({
    required String message,
    required ErrorSeverity severity,
    required ErrorCategory category,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? userId,
  }) {
    // Enhanced logging with structured data
    final errorDetails = {
      'message': message,
      'severity': severity.name,
      'category': category.name,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
      'context': context ?? {},
      'error': error?.toString(),
    };

    // Unified logging for both development and production
    developer.log(
      message,
      name: 'CrowdWave.${category.name}',
      level: _getSeverityLevel(severity),
      error: error,
      stackTrace: stackTrace,
    );

    // Additional production-specific logging to console for server logs
    if (EnvironmentConfig.currentEnvironment == Environment.production &&
        severity == ErrorSeverity.critical) {
      // Log critical errors to console for server-side monitoring
      print('CRITICAL ERROR: ${errorDetails}');
    }
  }

  /// Handle and format user-friendly error messages
  String handleUserError(Object error, {ErrorCategory? category}) {
    // Network errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException') ||
        error.toString().contains('TimeoutException')) {
      return 'Please check your internet connection and try again.';
    }

    // Firebase Auth errors
    if (error.toString().contains('firebase_auth') ||
        error.toString().contains('user-not-found') ||
        error.toString().contains('wrong-password')) {
      return 'Authentication failed. Please check your credentials.';
    }

    // Payment errors
    if (error.toString().contains('stripe') ||
        error.toString().contains('payment')) {
      return 'Payment processing failed. Please try again or use a different payment method.';
    }

    // Firebase/Firestore errors
    if (error.toString().contains('firestore') ||
        error.toString().contains('firebase')) {
      return 'Service temporarily unavailable. Please try again in a moment.';
    }

    // Location/GPS errors
    if (error.toString().contains('location') ||
        error.toString().contains('gps') ||
        error.toString().contains('LocationServiceDisabledException')) {
      return 'Please enable location services and try again.';
    }

    // Permission errors
    if (error.toString().contains('permission')) {
      return 'Required permissions not granted. Please check app settings.';
    }

    // Generic error based on category
    switch (category) {
      case ErrorCategory.booking:
        return 'Booking operation failed. Please try again.';
      case ErrorCategory.payment:
        return 'Payment processing failed. Please try again.';
      case ErrorCategory.authentication:
        return 'Authentication failed. Please try logging in again.';
      case ErrorCategory.location:
        return 'Location service error. Please check your settings.';
      case ErrorCategory.network:
        return 'Network error. Please check your connection.';
      case ErrorCategory.storage:
        return 'File operation failed. Please try again.';
      case ErrorCategory.chat:
        return 'Message sending failed. Please try again.';
      case ErrorCategory.navigation:
        return 'Navigation error occurred. Please try again.';
      case null:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Try-catch wrapper with automatic error handling
  static Future<T?> tryAsync<T>({
    required Future<T> Function() operation,
    required ErrorCategory category,
    String? context,
    String? userId,
    T? fallback,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      ErrorHandlingService().logError(
        message: 'Error in ${category.name}: ${error.toString()}',
        severity: ErrorSeverity.error,
        category: category,
        error: error,
        stackTrace: stackTrace,
        context: context != null ? {'context': context} : null,
        userId: userId,
      );
      return fallback;
    }
  }

  /// Synchronous try-catch wrapper
  static T? trySync<T>({
    required T Function() operation,
    required ErrorCategory category,
    String? context,
    String? userId,
    T? fallback,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      ErrorHandlingService().logError(
        message: 'Error in ${category.name}: ${error.toString()}',
        severity: ErrorSeverity.error,
        category: category,
        error: error,
        stackTrace: stackTrace,
        context: context != null ? {'context': context} : null,
        userId: userId,
      );
      return fallback;
    }
  }

  int _getSeverityLevel(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return 800;
      case ErrorSeverity.warning:
        return 900;
      case ErrorSeverity.error:
        return 1000;
      case ErrorSeverity.critical:
        return 1200;
    }
  }
}

/// Error severity levels for proper categorization
enum ErrorSeverity {
  info, // Informational messages
  warning, // Potential issues that don't break functionality
  error, // Errors that affect user experience
  critical, // Critical errors that may crash the app
}

/// Error categories for better organization and handling
enum ErrorCategory {
  authentication,
  booking,
  payment,
  location,
  network,
  storage,
  chat,
  navigation,
}

/// Mixin for easy error handling in services and controllers
mixin ErrorHandlingMixin {
  final ErrorHandlingService _errorService = ErrorHandlingService();

  void logError({
    required String message,
    required ErrorSeverity severity,
    required ErrorCategory category,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _errorService.logError(
      message: message,
      severity: severity,
      category: category,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  String getUserFriendlyError(Object error, {ErrorCategory? category}) {
    return _errorService.handleUserError(error, category: category);
  }
}

/// Extension for easy error handling on Future operations
extension FutureErrorHandling<T> on Future<T> {
  Future<T?> catchErrors({
    required ErrorCategory category,
    String? context,
    String? userId,
    T? fallback,
  }) async {
    return ErrorHandlingService.tryAsync<T>(
      operation: () => this,
      category: category,
      context: context,
      userId: userId,
      fallback: fallback,
    );
  }
}
