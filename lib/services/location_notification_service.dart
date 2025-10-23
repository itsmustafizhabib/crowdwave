import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/auth_state_service.dart';
import '../services/location_service.dart';

class LocationBasedNotificationService {
  static final LocationBasedNotificationService _instance =
      LocationBasedNotificationService._internal();

  factory LocationBasedNotificationService() => _instance;
  LocationBasedNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthStateService _authService = AuthStateService();
  final NotificationService _notificationService = NotificationService.instance;
  final LocationService _locationService = LocationService();

  // Track user's current location and preferences
  Position? _currentPosition;
  double _notificationRadius = 50.0; // 50km radius by default
  bool _isListening = false;

  // Collection to track sent notifications to avoid duplicates
  final Set<String> _sentNotifications = {};

  /// Start listening for new trips/orders in user's area
  /// Only requests permissions if explicitly allowed
  Future<void> startLocationBasedNotifications(
      {bool requestPermissions = false}) async {
    if (_isListening) return;

    try {
      // Check if location permissions are available
      final hasPermissions = await _locationService.hasLocationPermission();

      if (!hasPermissions) {
        if (requestPermissions) {
          // Only request permissions if explicitly allowed
          final granted = await _locationService.requestLocationPermission(
              reason: 'To find nearby trips and packages for notifications');
          if (!granted) {
            throw Exception('Location permissions denied');
          }
        } else {
          if (kDebugMode) {
            print('Location permissions not available and not requesting them');
          }
          return;
        }
      }

      // Get current location using the smart location service
      await _updateCurrentLocation();

      if (_currentPosition == null) {
        if (kDebugMode) {
          print('Cannot start location notifications: No location available');
        }
        return;
      }

      _isListening = true;

      // Listen for new trips
      _listenForNewTrips();

      if (kDebugMode) {
        print(
            'Started location-based notifications for radius: ${_notificationRadius}km');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting location notifications: $e');
      }
      rethrow;
    }
  }

  /// Stop listening for location-based notifications
  void stopLocationBasedNotifications() {
    _isListening = false;
    _sentNotifications.clear();

    if (kDebugMode) {
      print('Stopped location-based notifications');
    }
  }

  /// Update notification radius (in kilometers)
  void updateNotificationRadius(double radiusKm) {
    _notificationRadius = radiusKm;

    if (kDebugMode) {
      print('Updated notification radius to: ${_notificationRadius}km');
    }
  }

  /// Update current user location using the smart location service
  Future<void> _updateCurrentLocation() async {
    try {
      // Use the smart location service to get cached or fresh location
      _currentPosition = await _locationService.getLocationForNotifications();

      if (_currentPosition != null && kDebugMode) {
        print(
            'Updated location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating location: $e');
      }
    }
  }

  /// Listen for new trips in the user's area
  void _listenForNewTrips() {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null || _currentPosition == null) return;

    // Listen for newly created trips
    _firestore
        .collection('trips')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      if (!_isListening) return;

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _handleNewTrip(change.doc, currentUserId);
        }
      }
    });

    // Also listen for new package requests
    _firestore
        .collection('packageRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      if (!_isListening) return;

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _handleNewPackageRequest(change.doc, currentUserId);
        }
      }
    });
  }

  /// Handle new trip and check if it's in user's area
  void _handleNewTrip(DocumentSnapshot doc, String currentUserId) {
    try {
      final tripData = doc.data() as Map<String, dynamic>;
      final tripId = doc.id;

      // Don't notify about own trips
      if (tripData['userId'] == currentUserId) return;

      // Check if we already sent notification for this trip
      if (_sentNotifications.contains('trip_$tripId')) return;

      // Check if trip is in user's area
      if (_isTripInUserArea(tripData)) {
        _sendNewTravellerNotification(tripData, tripId);
        _sentNotifications.add('trip_$tripId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling new trip: $e');
      }
    }
  }

  /// Handle new package request and check if it's in user's area
  void _handleNewPackageRequest(DocumentSnapshot doc, String currentUserId) {
    try {
      final packageData = doc.data() as Map<String, dynamic>;
      final packageId = doc.id;

      // Don't notify about own packages
      if (packageData['userId'] == currentUserId) return;

      // Check if we already sent notification for this package
      if (_sentNotifications.contains('package_$packageId')) return;

      // Check if package pickup/delivery is in user's area
      if (_isPackageInUserArea(packageData)) {
        _sendNewOrderNotification(packageData, packageId);
        _sentNotifications.add('package_$packageId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling new package: $e');
      }
    }
  }

  /// Check if trip route passes through user's area
  bool _isTripInUserArea(Map<String, dynamic> tripData) {
    if (_currentPosition == null) return false;

    try {
      // Check origin
      final originLat = tripData['origin']?['latitude']?.toDouble();
      final originLng = tripData['origin']?['longitude']?.toDouble();

      if (originLat != null && originLng != null) {
        final originDistance = _locationService.calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          originLat,
          originLng,
        );

        if (originDistance <= _notificationRadius) return true;
      }

      // Check destination
      final destLat = tripData['destination']?['latitude']?.toDouble();
      final destLng = tripData['destination']?['longitude']?.toDouble();

      if (destLat != null && destLng != null) {
        final destDistance = _locationService.calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          destLat,
          destLng,
        );

        if (destDistance <= _notificationRadius) return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking trip location: $e');
      }
    }

    return false;
  }

  /// Check if package pickup/delivery is in user's area
  bool _isPackageInUserArea(Map<String, dynamic> packageData) {
    if (_currentPosition == null) return false;

    try {
      // Check pickup location
      final pickupLat = packageData['pickupLocation']?['latitude']?.toDouble();
      final pickupLng = packageData['pickupLocation']?['longitude']?.toDouble();

      if (pickupLat != null && pickupLng != null) {
        final pickupDistance = _locationService.calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          pickupLat,
          pickupLng,
        );

        if (pickupDistance <= _notificationRadius) return true;
      }

      // Check delivery location
      final deliveryLat =
          packageData['deliveryLocation']?['latitude']?.toDouble();
      final deliveryLng =
          packageData['deliveryLocation']?['longitude']?.toDouble();

      if (deliveryLat != null && deliveryLng != null) {
        final deliveryDistance = _locationService.calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          deliveryLat,
          deliveryLng,
        );

        if (deliveryDistance <= _notificationRadius) return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking package location: $e');
      }
    }

    return false;
  }

  /// Send notification for new traveller in area
  void _sendNewTravellerNotification(
      Map<String, dynamic> tripData, String tripId) {
    final fromCity = tripData['originAddress'] ?? 'Unknown';
    final toCity = tripData['destinationAddress'] ?? 'Unknown';

    _notificationService.createNotification(
      userId: _authService.currentUser!.uid,
      title: '$fromCity to $toCity: New Traveller Alert!',
      body:
          'Send/Receive your packages now with our new traveller from $fromCity to $toCity. Place your bid now',
      type: NotificationType.general,
      relatedEntityId: tripId,
      data: {
        'type': 'new_traveller',
        'tripId': tripId,
        'route': '$fromCity to $toCity',
      },
    );
  }

  /// Send notification for new order in area
  void _sendNewOrderNotification(
      Map<String, dynamic> packageData, String packageId) {
    final fromAddress = packageData['pickupAddress'] ?? 'Unknown';
    final toAddress = packageData['deliveryAddress'] ?? 'Unknown';

    _notificationService.createNotification(
      userId: _authService.currentUser!.uid,
      title: 'debug.test_package_title'.tr(),
      body:
          'Someone needs to send a package from $fromAddress to $toAddress. Accept this delivery request now!',
      type: NotificationType.general,
      relatedEntityId: packageId,
      data: {
        'type': 'new_package',
        'packageId': packageId,
        'route': '$fromAddress to $toAddress',
      },
    );
  }

  /// Manually refresh location and check for nearby opportunities
  Future<void> refreshAndCheckNearbyOpportunities() async {
    // Check permissions first
    final hasPermissions = await _locationService.hasLocationPermission();
    if (!hasPermissions) {
      throw Exception(
          'Location permissions are required to check nearby opportunities');
    }

    // Force refresh location for manual check
    _currentPosition =
        await _locationService.getCurrentLocation(forceRefresh: true);

    if (_currentPosition == null) {
      throw Exception('Unable to get current location');
    }

    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    // Check for active trips
    final tripsSnapshot = await _firestore
        .collection('trips')
        .where('status', isEqualTo: 'active')
        .limit(50)
        .get();

    int nearbyTrips = 0;
    for (var doc in tripsSnapshot.docs) {
      final tripData = doc.data();
      if (tripData['userId'] != currentUserId && _isTripInUserArea(tripData)) {
        nearbyTrips++;
      }
    }

    // Check for pending packages
    final packagesSnapshot = await _firestore
        .collection('packageRequests')
        .where('status', isEqualTo: 'pending')
        .limit(50)
        .get();

    int nearbyPackages = 0;
    for (var doc in packagesSnapshot.docs) {
      final packageData = doc.data();
      if (packageData['userId'] != currentUserId &&
          _isPackageInUserArea(packageData)) {
        nearbyPackages++;
      }
    }

    // Send summary notification if there are opportunities
    if (nearbyTrips > 0 || nearbyPackages > 0) {
      String title = 'Opportunities in Your Area!';
      String body = '';

      if (nearbyTrips > 0 && nearbyPackages > 0) {
        body =
            'Found $nearbyTrips travellers and $nearbyPackages package requests near you. Check them out!';
      } else if (nearbyTrips > 0) {
        body =
            'Found $nearbyTrips travellers near you looking for packages to carry. Start earning!';
      } else {
        body =
            'Found $nearbyPackages package requests near you. Accept deliveries and earn money!';
      }

      _notificationService.createNotification(
        userId: currentUserId,
        title: title,
        body: body,
        type: NotificationType.general,
        data: {
          'type': 'nearby_opportunities',
          'nearbyTrips': nearbyTrips,
          'nearbyPackages': nearbyPackages,
        },
      );
    }
  }
}
