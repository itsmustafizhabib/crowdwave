import 'dart:math';

/// Utility class for location-related calculations
class LocationUtils {
  /// Calculate distance between two coordinates in meters
  /// Uses Haversine formula for accuracy
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const R = 6371000; // Earth's radius in meters

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = R * c; // Distance in meters

    return distance;
  }

  /// Convert degrees to radians
  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Format distance in human-readable format
  /// - Returns "X m" for distances under 1 km
  /// - Returns "X.X km" for distances over 1 km
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Check if user is within acceptable proximity for delivery
  /// Default: 200 meters radius
  static bool isWithinDeliveryRadius({
    required double currentLat,
    required double currentLon,
    required double destinationLat,
    required double destinationLon,
    double radiusMeters = 200,
  }) {
    final distance = calculateDistance(
      lat1: currentLat,
      lon1: currentLon,
      lat2: destinationLat,
      lon2: destinationLon,
    );

    return distance <= radiusMeters;
  }

  /// Get proximity status with color coding
  static ProximityStatus getProximityStatus({
    required double currentLat,
    required double currentLon,
    required double destinationLat,
    required double destinationLon,
  }) {
    final distance = calculateDistance(
      lat1: currentLat,
      lon1: currentLon,
      lat2: destinationLat,
      lon2: destinationLon,
    );

    if (distance <= 200) {
      return ProximityStatus.withinRadius;
    } else if (distance <= 500) {
      return ProximityStatus.nearby;
    } else if (distance <= 1000) {
      return ProximityStatus.moderate;
    } else {
      return ProximityStatus.far;
    }
  }

  /// Get proximity message for UI
  static String getProximityMessage(ProximityStatus status, double distance) {
    switch (status) {
      case ProximityStatus.withinRadius:
        return '✅ You are at the delivery location';
      case ProximityStatus.nearby:
        return '⚠️ You are ${formatDistance(distance)} away. Please move closer.';
      case ProximityStatus.moderate:
        return '⚠️ You are ${formatDistance(distance)} from delivery location';
      case ProximityStatus.far:
        return '❌ You are too far (${formatDistance(distance)}). Please move closer to deliver.';
    }
  }

  /// Calculate bearing/direction between two points
  /// Returns angle in degrees (0-360)
  static double calculateBearing({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLon = _toRadians(lon2 - lon1);
    final y = sin(dLon) * cos(_toRadians(lat2));
    final x = cos(_toRadians(lat1)) * sin(_toRadians(lat2)) -
        sin(_toRadians(lat1)) * cos(_toRadians(lat2)) * cos(dLon);

    final bearing = atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  /// Convert radians to degrees
  static double _toDegrees(double radian) {
    return radian * 180 / pi;
  }

  /// Get compass direction from bearing
  static String getCompassDirection(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }
}

/// Proximity status enum for location verification
enum ProximityStatus {
  withinRadius, // Within 200m - can deliver
  nearby, // Within 500m - close enough
  moderate, // Within 1km - getting closer
  far, // Over 1km - too far
}
