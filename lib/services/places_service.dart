import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class PlacesService {
  static final String _baseUrl = ApiConstants.googlePlacesUrl;
  static final String _apiKey = ApiConstants.googleMapsApiKey;

  /// Search for places using Google Places API Autocomplete
  Future<List<PlaceAutocompletePrediction>> getPlaceAutocomplete(
      String input) async {
    if (input.isEmpty) return [];

    final url = Uri.parse('$_baseUrl/autocomplete/json').replace(
      queryParameters: {
        'input': input,
        'key': _apiKey,
        'types': 'geocode', // For addresses only
        'components':
            'country:us|country:ca', // Limit to US and Canada (adjust as needed)
      },
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions
              .map((prediction) =>
                  PlaceAutocompletePrediction.fromJson(prediction))
              .toList();
        } else {
          throw Exception(
              'Places API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch place predictions: $e');
    }
  }

  /// Get detailed place information by place ID
  Future<PlaceDetails> getPlaceDetails(String placeId) async {
    final url = Uri.parse('$_baseUrl/details/json').replace(
      queryParameters: {
        'place_id': placeId,
        'key': _apiKey,
        'fields': 'place_id,formatted_address,geometry,name,types',
      },
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        } else {
          throw Exception(
              'Places API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch place details: $e');
    }
  }

  /// Search for nearby places
  Future<List<PlaceSearchResult>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    String type = 'point_of_interest',
  }) async {
    final url = Uri.parse('$_baseUrl/nearbysearch/json').replace(
      queryParameters: {
        'location': '$latitude,$longitude',
        'radius': radiusMeters.toString(),
        'type': type,
        'key': _apiKey,
      },
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return results
              .map((result) => PlaceSearchResult.fromJson(result))
              .toList();
        } else {
          throw Exception(
              'Places API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search nearby places: $e');
    }
  }
}

// Supporting classes for Places API responses
class PlaceAutocompletePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceAutocompletePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceAutocompletePrediction.fromJson(Map<String, dynamic> json) {
    return PlaceAutocompletePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: json['structured_formatting']?['main_text'] ?? '',
      secondaryText: json['structured_formatting']?['secondary_text'] ?? '',
    );
  }

  @override
  String toString() => description;
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final List<String> types;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.types,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] ?? {};
    final location = geometry['location'] ?? {};

    return PlaceDetails(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      latitude: (location['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (location['lng'] as num?)?.toDouble() ?? 0.0,
      types: List<String>.from(json['types'] ?? []),
    );
  }
}

class PlaceSearchResult {
  final String placeId;
  final String name;
  final double latitude;
  final double longitude;
  final String vicinity;
  final double? rating;
  final List<String> types;

  PlaceSearchResult({
    required this.placeId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.vicinity,
    this.rating,
    required this.types,
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] ?? {};
    final location = geometry['location'] ?? {};

    return PlaceSearchResult(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      latitude: (location['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (location['lng'] as num?)?.toDouble() ?? 0.0,
      vicinity: json['vicinity'] ?? '',
      rating: (json['rating'] as num?)?.toDouble(),
      types: List<String>.from(json['types'] ?? []),
    );
  }
}
