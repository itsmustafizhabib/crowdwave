import 'dart:developer' as developer;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

/// 📝 Production Logging Service
/// Provides structured logging for debugging, monitoring, and analytics
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  static const String _logStorageKey = 'app_logs';
  static const int _maxStoredLogs = 1000;
  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Initialize logging service
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    _initialized = true;

    // Log service initialization
    await logEvent(
      event: LogEvent.appStart,
      level: LogLevel.info,
      message: 'CrowdWave app started',
      data: {
        'environment': EnvironmentConfig.currentEnvironment.name,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log an event with structured data
  Future<void> logEvent({
    required LogEvent event,
    required LogLevel level,
    required String message,
    Map<String, dynamic>? data,
    String? userId,
    String? screen,
    Duration? duration,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    if (!_initialized) await initialize();

    final logEntry = LogEntry(
      timestamp: DateTime.now(),
      event: event,
      level: level,
      message: message,
      data: data ?? {},
      userId: userId,
      screen: screen,
      duration: duration,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
    );

    // Console logging (all environments)
    _logToConsole(logEntry);

    // Store locally for debugging
    if (kDebugMode || level == LogLevel.error || level == LogLevel.critical) {
      await _storeLogLocally(logEntry);
    }

    // Send to analytics in production
    if (EnvironmentConfig.currentEnvironment == Environment.production &&
        _shouldLogToAnalytics(event, level)) {
      await _logToAnalytics(logEntry);
    }
  }

  /// Log user action for analytics
  Future<void> logUserAction({
    required UserAction action,
    required String screen,
    Map<String, dynamic>? properties,
    String? userId,
  }) async {
    await logEvent(
      event: LogEvent.userAction,
      level: LogLevel.info,
      message: 'User action: ${action.name}',
      data: {
        'action': action.name,
        'screen': screen,
        'properties': properties ?? {},
      },
      userId: userId,
      screen: screen,
    );
  }

  /// Log API call for debugging
  Future<void> logApiCall({
    required String endpoint,
    required String method,
    required int statusCode,
    Duration? duration,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
    Object? error,
  }) async {
    final isError = statusCode >= 400;

    await logEvent(
      event: LogEvent.apiCall,
      level: isError ? LogLevel.error : LogLevel.info,
      message: '$method $endpoint - $statusCode',
      data: {
        'endpoint': endpoint,
        'method': method,
        'statusCode': statusCode,
        'duration_ms': duration?.inMilliseconds,
        'requestData': _sanitizeData(requestData),
        'responseData': _sanitizeData(responseData),
      },
      duration: duration,
      error: error,
    );
  }

  /// Log business event for analytics
  Future<void> logBusinessEvent({
    required BusinessEvent event,
    required Map<String, dynamic> properties,
    String? userId,
  }) async {
    await logEvent(
      event: LogEvent.businessEvent,
      level: LogLevel.info,
      message: 'Business event: ${event.name}',
      data: {
        'event': event.name,
        'properties': properties,
      },
      userId: userId,
    );
  }

  /// Log performance metric
  Future<void> logPerformance({
    required String operation,
    required Duration duration,
    String? screen,
    Map<String, dynamic>? metadata,
  }) async {
    await logEvent(
      event: LogEvent.performance,
      level: duration.inMilliseconds > 5000 ? LogLevel.warning : LogLevel.info,
      message: 'Performance: $operation',
      data: {
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        'is_slow': duration.inMilliseconds > 5000,
        'metadata': metadata ?? {},
      },
      screen: screen,
      duration: duration,
    );
  }

  /// Get stored logs for debugging
  Future<List<LogEntry>> getStoredLogs({LogLevel? minLevel}) async {
    if (!_initialized) await initialize();

    final logsJson = _prefs.getStringList(_logStorageKey) ?? [];
    final logs = logsJson
        .map((json) => LogEntry.fromJson(jsonDecode(json)))
        .where((log) => minLevel == null || log.level.index >= minLevel.index)
        .toList();

    // Sort by timestamp (newest first)
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  /// Clear stored logs
  Future<void> clearLogs() async {
    if (!_initialized) await initialize();
    await _prefs.remove(_logStorageKey);
  }

  /// Export logs as JSON string
  Future<String> exportLogs({LogLevel? minLevel}) async {
    final logs = await getStoredLogs(minLevel: minLevel);
    return jsonEncode(logs.map((log) => log.toJson()).toList());
  }

  void _logToConsole(LogEntry entry) {
    final prefix = _getLevelPrefix(entry.level);

    developer.log(
      '$prefix ${entry.message}',
      name: 'CrowdWave.${entry.event.name}',
      level: _getLevelValue(entry.level),
      time: entry.timestamp,
      error: entry.error,
      stackTrace: entry.stackTrace != null
          ? StackTrace.fromString(entry.stackTrace!)
          : null,
    );

    // Additional console output for development
    if (kDebugMode && entry.data.isNotEmpty) {
      developer.log(
        'Data: ${jsonEncode(entry.data)}',
        name: 'CrowdWave.${entry.event.name}',
        level: _getLevelValue(entry.level),
      );
    }
  }

  Future<void> _storeLogLocally(LogEntry entry) async {
    final logs = _prefs.getStringList(_logStorageKey) ?? [];
    logs.insert(0, jsonEncode(entry.toJson()));

    // Keep only the most recent logs
    if (logs.length > _maxStoredLogs) {
      logs.removeRange(_maxStoredLogs, logs.length);
    }

    await _prefs.setStringList(_logStorageKey, logs);
  }

  Future<void> _logToAnalytics(LogEntry entry) async {
    try {
      // TODO: Integrate with Firebase Analytics when available
      // For now, just log to console in production for server-side pickup
      if (EnvironmentConfig.currentEnvironment == Environment.production) {
        final analyticsData = {
          'event': entry.event.name,
          'level': entry.level.name,
          'message': entry.message,
          'user_id': entry.userId,
          'screen': entry.screen,
          'timestamp': entry.timestamp.toIso8601String(),
          ...entry.data,
        };
        print('ANALYTICS: ${jsonEncode(analyticsData)}');
      }
    } catch (e) {
      // Don't let analytics logging break the app
      developer.log('Failed to log to analytics: $e', name: 'LoggingService');
    }
  }

  bool _shouldLogToAnalytics(LogEvent event, LogLevel level) {
    // Only log important events to analytics to avoid noise
    switch (event) {
      case LogEvent.userAction:
      case LogEvent.businessEvent:
      case LogEvent.error:
        return true;
      case LogEvent.apiCall:
        return level == LogLevel.error;
      case LogEvent.performance:
        return level == LogLevel.warning || level == LogLevel.error;
      default:
        return level == LogLevel.error || level == LogLevel.critical;
    }
  }

  Map<String, dynamic>? _sanitizeData(Map<String, dynamic>? data) {
    if (data == null) return null;

    // Remove sensitive data from logs
    final sanitized = Map<String, dynamic>.from(data);
    const sensitiveKeys = [
      'password',
      'token',
      'secret',
      'key',
      'cardNumber',
      'cvv'
    ];

    for (final key in sensitiveKeys) {
      if (sanitized.containsKey(key)) {
        sanitized[key] = '***REDACTED***';
      }
    }

    return sanitized;
  }

  String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '💥';
    }
  }

  int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.critical:
        return 1200;
    }
  }
}

/// Log entry structure
class LogEntry {
  final DateTime timestamp;
  final LogEvent event;
  final LogLevel level;
  final String message;
  final Map<String, dynamic> data;
  final String? userId;
  final String? screen;
  final Duration? duration;
  final String? error;
  final String? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.event,
    required this.level,
    required this.message,
    required this.data,
    this.userId,
    this.screen,
    this.duration,
    this.error,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'event': event.name,
        'level': level.name,
        'message': message,
        'data': data,
        'userId': userId,
        'screen': screen,
        'duration_ms': duration?.inMilliseconds,
        'error': error,
        'stackTrace': stackTrace,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        timestamp: DateTime.parse(json['timestamp']),
        event: LogEvent.values.firstWhere((e) => e.name == json['event']),
        level: LogLevel.values.firstWhere((l) => l.name == json['level']),
        message: json['message'],
        data: Map<String, dynamic>.from(json['data'] ?? {}),
        userId: json['userId'],
        screen: json['screen'],
        duration: json['duration_ms'] != null
            ? Duration(milliseconds: json['duration_ms'])
            : null,
        error: json['error'],
        stackTrace: json['stackTrace'],
      );
}

/// Log event types
enum LogEvent {
  appStart,
  appBackground,
  appForeground,
  userAction,
  apiCall,
  businessEvent,
  performance,
  error,
  navigation,
  authentication,
}

/// Log severity levels
enum LogLevel {
  debug, // Detailed debugging information
  info, // General information
  warning, // Potentially problematic situation
  error, // Error events but app can continue
  critical, // Critical error that may cause app crash
}

/// User action types for analytics
enum UserAction {
  // Authentication
  login,
  logout,
  signup,
  socialLogin,

  // Booking
  createBooking,
  confirmBooking,
  cancelBooking,
  shareBooking,

  // Payment
  addPaymentMethod,
  makePayment,
  viewPaymentHistory,

  // Search & Discovery
  searchPackages,
  searchTrips,
  viewPackageDetails,
  viewTripDetails,

  // Communication
  sendMessage,
  makeCall,
  sendNotification,

  // Profile
  updateProfile,
  uploadDocument,
  changeSettings,
}

/// Business event types for analytics
enum BusinessEvent {
  // Core business metrics
  packageCreated,
  tripCreated,
  matchMade,
  bookingCompleted,
  paymentSuccessful,

  // User engagement
  userOnboarded,
  profileCompleted,
  firstBooking,
  repeatBooking,

  // Performance metrics
  searchPerformed,
  filterApplied,
  locationShared,

  // Issues
  paymentFailed,
  bookingCancelled,
  disputeRaised,
  errorEncountered,
}

/// Mixin for easy logging integration
mixin LoggingMixin {
  final LoggingService _logger = LoggingService();

  Future<void> logInfo(String message, {Map<String, dynamic>? data}) =>
      _logger.logEvent(
        event: LogEvent.userAction,
        level: LogLevel.info,
        message: message,
        data: data,
      );

  Future<void> logError(String message,
          {Object? error, Map<String, dynamic>? data}) =>
      _logger.logEvent(
        event: LogEvent.error,
        level: LogLevel.error,
        message: message,
        error: error,
        data: data,
      );

  Future<void> logUserAction(UserAction action,
          {Map<String, dynamic>? properties}) =>
      _logger.logUserAction(
        action: action,
        screen: runtimeType.toString(),
        properties: properties,
      );
}
