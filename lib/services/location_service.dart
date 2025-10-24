import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Cache settings
  static const String _locationCacheKey = 'cached_location';
  static const String _locationTimestampKey = 'location_timestamp';
  static const Duration _cacheValidDuration =
      Duration(minutes: 15); // Cache for 15 minutes

  Position? _cachedPosition;
  DateTime? _lastLocationUpdate;
  bool _isUpdatingLocation = false;

  /// Get current location with smart caching
  /// Only requests new location if cache is expired or force refresh is requested
  Future<Position?> getCurrentLocation({
    bool forceRefresh = false,
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) async {
    try {
      // Return cached location if valid and not forcing refresh
      if (!forceRefresh && _isCacheValid()) {
        if (kDebugMode) {
          print(
              'Returning cached location: ${_cachedPosition?.latitude}, ${_cachedPosition?.longitude}');
        }
        return _cachedPosition;
      }

      // Prevent multiple simultaneous location requests
      if (_isUpdatingLocation) {
        if (kDebugMode) {
          print('Location update already in progress, waiting...');
        }
        // Wait for ongoing request to complete and return cached result
        while (_isUpdatingLocation) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        return _cachedPosition;
      }

      _isUpdatingLocation = true;

      // Check permissions
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        _isUpdatingLocation = false;
        throw LocationPermissionException('Location permission not granted');
      }

      // Get fresh location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: const Duration(seconds: 10), // Timeout after 10 seconds
      );

      // Cache the new location
      await _cacheLocation(position);

      _isUpdatingLocation = false;

      if (kDebugMode) {
        print(
            'Fresh location obtained: ${position.latitude}, ${position.longitude}');
      }

      return position;
    } catch (e) {
      _isUpdatingLocation = false;

      if (kDebugMode) {
        print('Error getting location: $e');
      }

      // Return cached location as fallback if available
      if (_cachedPosition != null) {
        if (kDebugMode) {
          print('Returning cached location as fallback');
        }
        return _cachedPosition;
      }

      rethrow;
    }
  }

  /// Get location specifically for trip creation (high accuracy)
  Future<Position?> getLocationForTrip() async {
    if (kDebugMode) {
      print('Getting high-accuracy location for trip creation');
    }
    return await getCurrentLocation(
      accuracy: LocationAccuracy.high,
      forceRefresh: true, // Always get fresh location for trip creation
    );
  }

  /// Get location for package pickup/delivery (high accuracy)
  Future<Position?> getLocationForPackage() async {
    if (kDebugMode) {
      print('Getting high-accuracy location for package');
    }
    return await getCurrentLocation(
      accuracy: LocationAccuracy.high,
      forceRefresh: true, // Always get fresh location for package operations
    );
  }

  /// Get location for search/filtering (balanced accuracy, cached OK)
  Future<Position?> getLocationForSearch() async {
    if (kDebugMode) {
      print('Getting location for search/filtering');
    }
    return await getCurrentLocation(
      accuracy: LocationAccuracy.medium,
      forceRefresh: false, // Cached location is OK for search
    );
  }

  /// Get location for notifications (low accuracy, cached OK)
  Future<Position?> getLocationForNotifications() async {
    if (kDebugMode) {
      print('Getting location for notifications');
    }
    return await getCurrentLocation(
      accuracy: LocationAccuracy.low,
      forceRefresh: false, // Cached location is fine for notifications
    );
  }

  /// Check if user has location permission without requesting it
  Future<bool> hasLocationPermission() async {
    return await _checkLocationPermission();
  }

  /// Request location permission with user-friendly explanation
  Future<bool> requestLocationPermission({String? reason}) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceException(
            'Location services are disabled. Please enable them in device settings.');
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionException(
            'Location permissions are permanently denied. Please enable them in app settings.');
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationPermissionException('Location permission was denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionException(
            'Location permissions are permanently denied. Please enable them in app settings.');
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting location permission: $e');
      }
      rethrow;
    }
  }

  /// Clear cached location (useful when user changes location significantly)
  void clearLocationCache() {
    _cachedPosition = null;
    _lastLocationUpdate = null;
    _clearLocationFromPrefs();

    if (kDebugMode) {
      print('Location cache cleared');
    }
  }

  /// Get distance between two points in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Check if a location is within a certain radius of user's location
  Future<bool> isLocationWithinRadius(
      double targetLat, double targetLon, double radiusKm) async {
    final userLocation = await getLocationForSearch();
    if (userLocation == null) return false;

    final distance = calculateDistance(
        userLocation.latitude, userLocation.longitude, targetLat, targetLon);

    return distance <= radiusKm;
  }

  // Private helper methods

  Future<bool> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }

  bool _isCacheValid() {
    if (_cachedPosition == null || _lastLocationUpdate == null) {
      return false;
    }

    final now = DateTime.now();
    final cacheAge = now.difference(_lastLocationUpdate!);

    return cacheAge < _cacheValidDuration;
  }

  Future<void> _cacheLocation(Position position) async {
    _cachedPosition = position;
    _lastLocationUpdate = DateTime.now();

    // Also save to persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': _lastLocationUpdate!.millisecondsSinceEpoch,
      };

      await prefs.setString(_locationCacheKey, json.encode(locationData));
      await prefs.setInt(
          _locationTimestampKey, _lastLocationUpdate!.millisecondsSinceEpoch);

      if (kDebugMode) {
        print('Location cached to persistent storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error caching location to storage: $e');
      }
    }
  }

  Future<void> _loadCachedLocationFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationString = prefs.getString(_locationCacheKey);
      final timestamp = prefs.getInt(_locationTimestampKey);

      if (locationString != null && timestamp != null) {
        final locationData = json.decode(locationString);
        final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

        // Check if cached data is still valid
        final age = DateTime.now().difference(cachedTime);
        if (age < _cacheValidDuration) {
          _cachedPosition = Position(
            latitude: locationData['latitude'],
            longitude: locationData['longitude'],
            timestamp: cachedTime,
            accuracy: locationData['accuracy'],
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
          _lastLocationUpdate = cachedTime;

          if (kDebugMode) {
            print('Loaded cached location from storage');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cached location: $e');
      }
    }
  }

  Future<void> _clearLocationFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_locationCacheKey);
      await prefs.remove(_locationTimestampKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cached location: $e');
      }
    }
  }

  /// Initialize the service (call once at app startup)
  Future<void> initialize() async {
    await _loadCachedLocationFromPrefs();
    if (kDebugMode) {
      print('LocationService initialized');
    }
  }

  /// Get Google Maps URL for viewing a location
  String getGoogleMapsUrl(double latitude, double longitude, {String? label}) {
    if (label != null && label.isNotEmpty) {
      final encodedLabel = Uri.encodeComponent(label);
      return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$encodedLabel';
    }
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  /// Get Google Maps URL for directions from current location to target
  String getDirectionsUrl(
    double targetLat,
    double targetLng, {
    double? startLat,
    double? startLng,
  }) {
    if (startLat != null && startLng != null) {
      return 'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$targetLat,$targetLng&travelmode=driving';
    }
    return 'https://www.google.com/maps/dir/?api=1&destination=$targetLat,$targetLng&travelmode=driving';
  }

  /// Format coordinates for display
  String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Open device app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Get continuous location updates stream (for live location sharing)
  Stream<Position> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
  }) {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}

// Custom exceptions for better error handling
class LocationPermissionException implements Exception {
  final String message;
  LocationPermissionException(this.message);
  @override
  String toString() => 'LocationPermissionException: $message';
}

class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);
  @override
  String toString() => 'LocationServiceException: $message';
}
