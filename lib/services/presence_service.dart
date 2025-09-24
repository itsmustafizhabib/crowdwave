import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  // Stream subscriptions
  StreamSubscription? _connectivitySubscription;
  StreamSubscription<User?>? _authSubscription;
  Timer? _heartbeatTimer;

  // State variables
  bool _isOnline = false;
  bool _isInitialized = false;
  String? _currentUserId;

  // Callback for when user comes online (for message delivery updates)
  Function(String userId)? _onUserOnlineCallback;

  // Constants
  static const String _usersCollection = 'users';
  static const String _presenceCollection = 'presence';
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _presenceTimeout = Duration(minutes: 2);

  // Public getters
  bool get isOnline => _isOnline;
  String? get currentUserId => _currentUserId;

  /// Set callback for when user comes online (used by ChatService)
  void setOnUserOnlineCallback(Function(String userId)? callback) {
    _onUserOnlineCallback = callback;
  }

  /// Initialize the presence service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Listen to auth state changes
      _authSubscription =
          _auth.authStateChanges().listen(_handleAuthStateChange);

      // Listen to connectivity changes with proper type handling
      _connectivitySubscription =
          _connectivity.onConnectivityChanged.map((dynamic result) {
        // Handle both single result and list of results
        if (result is List<ConnectivityResult>) {
          return result.isNotEmpty ? result.first : ConnectivityResult.none;
        } else if (result is ConnectivityResult) {
          return result;
        } else {
          return ConnectivityResult.none;
        }
      }).listen(_handleConnectivityChange);

      // Setup current user if already logged in
      if (_auth.currentUser != null) {
        await _setupPresenceForUser(_auth.currentUser!.uid);
      }

      _isInitialized = true;
      if (kDebugMode) {
        print('PresenceService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PresenceService initialization error: $e');
      }
      rethrow;
    }
  }

  /// Handle authentication state changes
  void _handleAuthStateChange(User? user) async {
    if (user != null && user.uid != _currentUserId) {
      // User logged in or switched
      await _setupPresenceForUser(user.uid);
    } else if (user == null && _currentUserId != null) {
      // User logged out
      await _cleanupPresence();
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(ConnectivityResult result) async {
    final bool hasConnection = result != ConnectivityResult.none;

    if (hasConnection && !_isOnline && _currentUserId != null) {
      // Connection restored
      await _goOnline();
    } else if (!hasConnection && _isOnline) {
      // Connection lost
      await _goOffline();
    }

    if (kDebugMode) {
      print('Connectivity changed: $result, online: $_isOnline');
    }
  }

  /// Setup presence system for a specific user
  Future<void> _setupPresenceForUser(String userId) async {
    try {
      // Cleanup previous user's presence if any
      await _cleanupPresence();

      _currentUserId = userId;

      // Start heartbeat timer
      _startHeartbeat();

      // Go online
      await _goOnline();

      if (kDebugMode) {
        print('Presence setup completed for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Setup presence error: $e');
      }
      rethrow;
    }
  }

  /// Update presence status in Firestore
  Future<void> _updatePresenceStatus(bool online) async {
    if (_currentUserId == null) return;

    final wasOnline = _isOnline;
    _isOnline = online;

    try {
      final now = FieldValue.serverTimestamp();

      // Update main presence document
      await _firestore.collection(_presenceCollection).doc(_currentUserId).set({
        'online': online,
        'lastSeen': now,
        'userId': _currentUserId,
        'lastHeartbeat': now,
      }, SetOptions(merge: true));

      // Also update user document for consistency
      await _firestore.collection(_usersCollection).doc(_currentUserId).set({
        'isOnline': online,
        'lastSeen': now,
      }, SetOptions(merge: true));

      // ✅ Trigger message delivery updates when user comes online
      if (online && !wasOnline && _onUserOnlineCallback != null) {
        _onUserOnlineCallback!(_currentUserId!);
      }

      if (kDebugMode) {
        print('Presence updated: online=$online, user=$_currentUserId');
        if (online && !wasOnline) {
          print('🔔 User came online - triggering message delivery updates');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update presence error: $e');
      }
    }
  }

  /// Start heartbeat timer for periodic presence updates
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) async {
      if (_isOnline && _currentUserId != null) {
        await _sendHeartbeat();
      }
    });

    if (kDebugMode) {
      print('Heartbeat timer started');
    }
  }

  /// Send heartbeat to indicate user is still active
  Future<void> _sendHeartbeat() async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection(_presenceCollection)
          .doc(_currentUserId)
          .update({
        'lastHeartbeat': FieldValue.serverTimestamp(),
        'online': true,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Heartbeat error: $e');
      }
    }
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (kDebugMode) {
      print('Heartbeat timer stopped');
    }
  }

  /// Set user as online
  Future<void> _goOnline() async {
    if (_currentUserId == null) return;

    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if (kDebugMode) {
        print('Cannot go online: No internet connection');
      }
      return;
    }

    await _updatePresenceStatus(true);
  }

  /// Set user as offline
  Future<void> _goOffline() async {
    await _updatePresenceStatus(false);
  }

  /// Public method to set online status manually
  Future<void> setOnlineStatus(bool online) async {
    if (online) {
      await _goOnline();
    } else {
      await _goOffline();
    }
  }

  /// Get user's online status stream
  Stream<bool> getUserOnlineStatus(String userId) {
    return _firestore
        .collection(_presenceCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final online = data['online'] as bool? ?? false;
      final lastHeartbeat = data['lastHeartbeat'] as Timestamp?;

      // Check if user is truly online based on heartbeat
      if (online && lastHeartbeat != null) {
        final lastHeartbeatTime = lastHeartbeat.toDate();
        final timeDiff = DateTime.now().difference(lastHeartbeatTime);

        // Consider offline if no heartbeat within timeout period
        if (timeDiff > _presenceTimeout) {
          return false;
        }
      }

      return online;
    });
  }

  /// Get user's last seen time
  Stream<DateTime?> getUserLastSeen(String userId) {
    return _firestore
        .collection(_presenceCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      final lastSeen = data['lastSeen'] as Timestamp?;
      return lastSeen?.toDate();
    });
  }

  /// Check if user is currently online
  Future<bool> isUserOnline(String userId) async {
    try {
      final doc =
          await _firestore.collection(_presenceCollection).doc(userId).get();

      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final online = data['online'] as bool? ?? false;
      final lastHeartbeat = data['lastHeartbeat'] as Timestamp?;

      if (online && lastHeartbeat != null) {
        final lastHeartbeatTime = lastHeartbeat.toDate();
        final timeDiff = DateTime.now().difference(lastHeartbeatTime);

        return timeDiff <= _presenceTimeout;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Check user online error: $e');
      }
      return false;
    }
  }

  /// Get count of online users
  Future<int> getOnlineUsersCount() async {
    try {
      final cutoffTime =
          Timestamp.fromDate(DateTime.now().subtract(_presenceTimeout));

      final snapshot = await _firestore
          .collection(_presenceCollection)
          .where('online', isEqualTo: true)
          .where('lastHeartbeat', isGreaterThan: cutoffTime)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('Get online users count error: $e');
      }
      return 0;
    }
  }

  /// Cleanup stale presence records (should be called periodically)
  Future<void> cleanupStalePresence() async {
    try {
      final cutoffTime =
          Timestamp.fromDate(DateTime.now().subtract(_presenceTimeout));

      final staleRecords = await _firestore
          .collection(_presenceCollection)
          .where('online', isEqualTo: true)
          .where('lastHeartbeat', isLessThan: cutoffTime)
          .get();

      final batch = _firestore.batch();

      for (final doc in staleRecords.docs) {
        batch.update(doc.reference, {
          'online': false,
          'lastSeen': doc.data()['lastHeartbeat'],
        });
      }

      await batch.commit();

      if (kDebugMode) {
        print('Cleaned up ${staleRecords.docs.length} stale presence records');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cleanup stale presence error: $e');
      }
    }
  }

  /// Cleanup presence when user logs out or app is disposed
  Future<void> _cleanupPresence() async {
    try {
      // Stop heartbeat
      _stopHeartbeat();

      // Set offline status
      if (_currentUserId != null) {
        await _updatePresenceStatus(false);
      }

      // Clear references
      _currentUserId = null;
      _isOnline = false;

      if (kDebugMode) {
        print('Presence cleanup completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Presence cleanup error: $e');
      }
    }
  }

  /// Dispose the service
  Future<void> dispose() async {
    try {
      await _cleanupPresence();

      await _connectivitySubscription?.cancel();
      await _authSubscription?.cancel();

      _connectivitySubscription = null;
      _authSubscription = null;
      _isInitialized = false;

      if (kDebugMode) {
        print('PresenceService disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PresenceService dispose error: $e');
      }
    }
  }

  /// Handle app lifecycle changes
  Future<void> handleAppLifecycleChange(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        await _goOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        await _goOffline();
        break;
      case AppLifecycleState.hidden:
        // No action needed
        break;
    }
  }
}
