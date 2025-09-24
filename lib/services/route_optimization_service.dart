import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models/models.dart';
import '../core/constants/api_constants.dart';

class RouteOptimizationService {
  static final String _baseUrl = ApiConstants.googleMapsBaseUrl;
  static final String _apiKey = ApiConstants.googleMapsApiKey;

  /// Calculate optimal route between multiple points
  Future<RouteOptimizationResult> optimizeRoute({
    required Location origin,
    required Location destination,
    required List<Location> waypoints,
    required TransportMode transportMode,
  }) async {
    try {
      final waypointsStr =
          waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|');

      final url = Uri.parse('$_baseUrl/directions/json').replace(
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'waypoints': 'optimize:true|$waypointsStr',
          'mode': _getGoogleTransportMode(transportMode),
          'key': _apiKey,
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return RouteOptimizationResult.fromGoogleDirections(data);
        } else {
          throw Exception('Route optimization failed: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to optimize route: $e');
    }
  }

  /// Calculate distance matrix for multiple locations
  Future<DistanceMatrixResult> calculateDistanceMatrix({
    required List<Location> origins,
    required List<Location> destinations,
    required TransportMode transportMode,
  }) async {
    try {
      final originsStr =
          origins.map((loc) => '${loc.latitude},${loc.longitude}').join('|');

      final destinationsStr = destinations
          .map((loc) => '${loc.latitude},${loc.longitude}')
          .join('|');

      final url = Uri.parse('$_baseUrl/distancematrix/json').replace(
        queryParameters: {
          'origins': originsStr,
          'destinations': destinationsStr,
          'mode': _getGoogleTransportMode(transportMode),
          'units': 'metric',
          'key': _apiKey,
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return DistanceMatrixResult.fromGoogle(data);
        } else {
          throw Exception(
              'Distance matrix calculation failed: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to calculate distance matrix: $e');
    }
  }

  /// Find optimal package pickup sequence for a trip
  Future<List<PackagePickupOptimization>> optimizePackagePickups({
    required TravelTrip trip,
    required List<PackageRequest> packages,
  }) async {
    try {
      // Create waypoints for all package pickup and delivery locations
      final waypoints = <Location>[];
      final packageLocationMap = <String, PackageRequest>{};

      for (final package in packages) {
        waypoints.add(package.pickupLocation);
        waypoints
            .add(package.destinationLocation); // Fixed: use destinationLocation
        packageLocationMap['pickup_${package.id}'] = package;
        packageLocationMap['delivery_${package.id}'] = package;
      }

      // Optimize route including all waypoints
      final optimizedRoute = await optimizeRoute(
        origin: trip.departureLocation,
        destination: trip.destinationLocation,
        waypoints: waypoints,
        transportMode: trip.transportMode,
      );

      // Convert optimized waypoint order back to package pickup sequence
      return _convertToPackageSequence(optimizedRoute, packages);
    } catch (e) {
      throw Exception('Failed to optimize package pickups: $e');
    }
  }

  /// Check if a detour is feasible within trip constraints
  Future<DetourFeasibilityResult> checkDetourFeasibility({
    required TravelTrip trip,
    required Location detourLocation,
    required double maxDetourKm,
  }) async {
    try {
      // Calculate original route
      final originalRoute = await _calculateRoute(
        trip.departureLocation,
        trip.destinationLocation,
        trip.transportMode,
      );

      // Calculate route with detour
      final detourRoute = await optimizeRoute(
        origin: trip.departureLocation,
        destination: trip.destinationLocation,
        waypoints: [detourLocation],
        transportMode: trip.transportMode,
      );

      final additionalDistance =
          detourRoute.totalDistanceKm - originalRoute.totalDistanceKm;
      final additionalTime =
          detourRoute.totalDurationMinutes - originalRoute.totalDurationMinutes;

      return DetourFeasibilityResult(
        isFeasible: additionalDistance <= maxDetourKm,
        additionalDistanceKm: additionalDistance,
        additionalTimeMinutes: additionalTime,
        originalRoute: originalRoute,
        detourRoute: detourRoute,
      );
    } catch (e) {
      throw Exception('Failed to check detour feasibility: $e');
    }
  }

  String _getGoogleTransportMode(TransportMode mode) {
    switch (mode) {
      case TransportMode.walking:
        return 'walking';
      case TransportMode.bicycle:
        return 'bicycling';
      case TransportMode.car:
        return 'driving';
      case TransportMode.bus:
      case TransportMode.train:
        return 'transit';
      case TransportMode.flight:
        return 'driving'; // Fallback to driving for flights
      case TransportMode.motorcycle:
        return 'driving';
      case TransportMode.ship:
        return 'driving'; // Fallback to driving for ships
    }
  }

  Future<RouteResult> _calculateRoute(
    Location origin,
    Location destination,
    TransportMode transportMode,
  ) async {
    final url = Uri.parse('$_baseUrl/directions/json').replace(
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': _getGoogleTransportMode(transportMode),
        'key': _apiKey,
      },
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return RouteResult.fromGoogleDirections(data);
      } else {
        throw Exception('Route calculation failed: ${data['status']}');
      }
    } else {
      throw Exception('HTTP error: ${response.statusCode}');
    }
  }

  List<PackagePickupOptimization> _convertToPackageSequence(
    RouteOptimizationResult optimizedRoute,
    List<PackageRequest> packages,
  ) {
    // Implementation to convert waypoint order to package sequence
    // This is a simplified version - you'd need to implement the full logic
    return packages
        .map((package) => PackagePickupOptimization(
              package: package,
              pickupOrder: 0, // Calculate based on optimized route
              estimatedPickupTime:
                  DateTime.now(), // Calculate based on route timing
              estimatedDeliveryTime:
                  DateTime.now(), // Calculate based on route timing
            ))
        .toList();
  }
}

// Supporting classes
class RouteOptimizationResult {
  final List<Location> optimizedWaypoints;
  final double totalDistanceKm;
  final int totalDurationMinutes;
  final List<RouteStep> steps;

  RouteOptimizationResult({
    required this.optimizedWaypoints,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.steps,
  });

  factory RouteOptimizationResult.fromGoogleDirections(
      Map<String, dynamic> json) {
    // Implementation to parse Google Directions API response
    final routes = json['routes'] as List;
    if (routes.isEmpty) {
      throw Exception('No routes found');
    }

    final route = routes.first;
    final legs = route['legs'] as List;

    double totalDistance = 0;
    int totalDuration = 0;

    for (final leg in legs) {
      totalDistance +=
          (leg['distance']['value'] as num) / 1000.0; // Convert to km
      totalDuration += ((leg['duration']['value'] as num) / 60)
          .round(); // Convert to minutes
    }

    return RouteOptimizationResult(
      optimizedWaypoints: [], // Parse waypoint order from response
      totalDistanceKm: totalDistance,
      totalDurationMinutes: totalDuration,
      steps: [], // Parse route steps
    );
  }
}

class DistanceMatrixResult {
  final List<List<DistanceElement>> elements;

  DistanceMatrixResult({required this.elements});

  factory DistanceMatrixResult.fromGoogle(Map<String, dynamic> json) {
    // Implementation to parse Google Distance Matrix API response
    final rows = json['rows'] as List;
    final elements = <List<DistanceElement>>[];

    for (final row in rows) {
      final rowElements = <DistanceElement>[];
      for (final element in row['elements']) {
        rowElements.add(DistanceElement.fromGoogle(element));
      }
      elements.add(rowElements);
    }

    return DistanceMatrixResult(elements: elements);
  }
}

class DistanceElement {
  final double distanceKm;
  final int durationMinutes;
  final String status;

  DistanceElement({
    required this.distanceKm,
    required this.durationMinutes,
    required this.status,
  });

  factory DistanceElement.fromGoogle(Map<String, dynamic> json) {
    return DistanceElement(
      distanceKm: json['status'] == 'OK'
          ? (json['distance']['value'] as num) / 1000.0
          : 0,
      durationMinutes: json['status'] == 'OK'
          ? ((json['duration']['value'] as num) / 60).round()
          : 0,
      status: json['status'],
    );
  }
}

class RouteStep {
  final String instruction;
  final double distanceKm;
  final int durationMinutes;
  final Location startLocation;
  final Location endLocation;

  RouteStep({
    required this.instruction,
    required this.distanceKm,
    required this.durationMinutes,
    required this.startLocation,
    required this.endLocation,
  });
}

class RouteResult {
  final double totalDistanceKm;
  final int totalDurationMinutes;
  final List<RouteStep> steps;

  RouteResult({
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.steps,
  });

  factory RouteResult.fromGoogleDirections(Map<String, dynamic> json) {
    final routes = json['routes'] as List;
    if (routes.isEmpty) {
      throw Exception('No routes found');
    }

    final route = routes.first;
    final legs = route['legs'] as List;

    double totalDistance = 0;
    int totalDuration = 0;

    for (final leg in legs) {
      totalDistance += (leg['distance']['value'] as num) / 1000.0;
      totalDuration += ((leg['duration']['value'] as num) / 60).round();
    }

    return RouteResult(
      totalDistanceKm: totalDistance,
      totalDurationMinutes: totalDuration,
      steps: [], // Parse steps from legs
    );
  }
}

class DetourFeasibilityResult {
  final bool isFeasible;
  final double additionalDistanceKm;
  final int additionalTimeMinutes;
  final RouteResult originalRoute;
  final RouteOptimizationResult detourRoute;

  DetourFeasibilityResult({
    required this.isFeasible,
    required this.additionalDistanceKm,
    required this.additionalTimeMinutes,
    required this.originalRoute,
    required this.detourRoute,
  });
}

class PackagePickupOptimization {
  final PackageRequest package;
  final int pickupOrder;
  final DateTime estimatedPickupTime;
  final DateTime estimatedDeliveryTime;

  PackagePickupOptimization({
    required this.package,
    required this.pickupOrder,
    required this.estimatedPickupTime,
    required this.estimatedDeliveryTime,
  });
}
