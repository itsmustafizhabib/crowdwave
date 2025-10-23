import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for converting coordinates to human-readable addresses
/// Uses OpenStreetMap Nominatim API (free, no API key required)
class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/reverse';

  /// Convert latitude/longitude to human-readable address
  /// Returns formatted address like: "Street 5, F-7, Islamabad, Pakistan"
  Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?'
        'lat=$latitude&'
        'lon=$longitude&'
        'format=json&'
        'addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'CrowdWave/1.0', // Required by Nominatim
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Geocoding request timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _formatAddress(data);
      } else {
        throw Exception('Failed to get address: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Geocoding error: $e');
      // Return coordinates as fallback
      return 'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }
  }

  /// Format the geocoding response into a readable address
  String _formatAddress(Map<String, dynamic> data) {
    try {
      final address = data['address'] as Map<String, dynamic>?;
      if (address == null) {
        return data['display_name'] ?? 'Unknown Location';
      }

      // Build address from most specific to general
      final parts = <String>[];

      // House number and road
      if (address['house_number'] != null && address['road'] != null) {
        parts.add('${address['house_number']} ${address['road']}');
      } else if (address['road'] != null) {
        parts.add(address['road']);
      }

      // Neighborhood or suburb
      if (address['neighbourhood'] != null) {
        parts.add(address['neighbourhood']);
      } else if (address['suburb'] != null) {
        parts.add(address['suburb']);
      }

      // City
      if (address['city'] != null) {
        parts.add(address['city']);
      } else if (address['town'] != null) {
        parts.add(address['town']);
      } else if (address['village'] != null) {
        parts.add(address['village']);
      }

      // State/Province
      if (address['state'] != null) {
        parts.add(address['state']);
      }

      // Country
      if (address['country'] != null) {
        parts.add(address['country']);
      }

      // If we have parts, join them
      if (parts.isNotEmpty) {
        return parts.join(', ');
      }

      // Fallback to display_name
      return data['display_name'] ?? 'Unknown Location';
    } catch (e) {
      print('⚠️ Error formatting address: $e');
      return data['display_name'] ?? 'Unknown Location';
    }
  }

  /// Get short address (just street and area)
  Future<String> getShortAddress({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?'
        'lat=$latitude&'
        'lon=$longitude&'
        'format=json&'
        'addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'CrowdWave/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address == null) return 'Unknown Location';

        final parts = <String>[];

        // Just street and neighborhood/suburb
        if (address['road'] != null) {
          parts.add(address['road']);
        }
        if (address['neighbourhood'] != null) {
          parts.add(address['neighbourhood']);
        } else if (address['suburb'] != null) {
          parts.add(address['suburb']);
        }

        return parts.isNotEmpty ? parts.join(', ') : 'Unknown Location';
      }

      return 'Unknown Location';
    } catch (e) {
      print('❌ Short address error: $e');
      return 'Unknown Location';
    }
  }

  /// Get city name from coordinates
  Future<String> getCityFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?'
        'lat=$latitude&'
        'lon=$longitude&'
        'format=json&'
        'addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'CrowdWave/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address == null) return 'Unknown City';

        return address['city'] ??
            address['town'] ??
            address['village'] ??
            'Unknown City';
      }

      return 'Unknown City';
    } catch (e) {
      print('❌ City lookup error: $e');
      return 'Unknown City';
    }
  }
}
