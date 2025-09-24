import 'package:cloud_firestore/cloud_firestore.dart';
import 'package_request.dart';

class TravelTrip {
  final String id;
  final String travelerId;
  final String travelerName;
  final String travelerPhotoUrl;
  final Location departureLocation;
  final Location destinationLocation;
  final DateTime departureDate;
  final DateTime? arrivalDate;
  final TransportMode transportMode;
  final TripCapacity capacity;
  final double suggestedReward;
  final List<PackageType> acceptedItemTypes;
  final List<String> routeStops;
  final TripStatus status;
  final List<String> acceptedPackageIds;
  final int totalPackagesAccepted;
  final double totalEarnings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final bool isFlexibleRoute;
  final double? maxDetourKm;
  final List<String> verificationDocuments;

  // Match percentage for smart matching (not persisted)
  double? matchPercentage;

  // UI convenience properties (computed or fallback values)
  double? get rating => null; // Will be computed from reviews
  int? get reviewCount => null; // Will be computed from reviews
  bool? get isVerified => null; // Will be computed from verification status
  String? get fromLocation =>
      departureLocation.city ?? departureLocation.country;
  String? get toLocation =>
      destinationLocation.city ?? destinationLocation.country;
  double? get availableSpace =>
      capacity.maxWeightKg; // Available weight capacity
  double? get pricePerKg => suggestedReward; // Price per kg

  TravelTrip({
    required this.id,
    required this.travelerId,
    required this.travelerName,
    required this.travelerPhotoUrl,
    required this.departureLocation,
    required this.destinationLocation,
    required this.departureDate,
    required this.transportMode,
    required this.capacity,
    required this.suggestedReward,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.arrivalDate,
    this.acceptedItemTypes = const [],
    this.routeStops = const [],
    this.acceptedPackageIds = const [],
    this.totalPackagesAccepted = 0,
    this.totalEarnings = 0.0,
    this.notes,
    this.isFlexibleRoute = false,
    this.maxDetourKm,
    this.verificationDocuments = const [],
  }) {
    matchPercentage = null; // Initialize as null
  }

  Map<String, dynamic> toJson() {
    final json = {
      'travelerId': travelerId,
      'travelerName': travelerName,
      'travelerPhotoUrl': travelerPhotoUrl,
      'departureLocation': departureLocation.toJson(),
      'destinationLocation': destinationLocation.toJson(),
      'departureDate': departureDate.toIso8601String(),
      'arrivalDate': arrivalDate?.toIso8601String(),
      'transportMode': transportMode.name,
      'capacity': capacity.toJson(),
      'suggestedReward': suggestedReward,
      'acceptedItemTypes': acceptedItemTypes.map((e) => e.name).toList(),
      'routeStops': routeStops,
      'status': status.name,
      'acceptedPackageIds': acceptedPackageIds,
      'totalPackagesAccepted': totalPackagesAccepted,
      'totalEarnings': totalEarnings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notes': notes,
      'isFlexibleRoute': isFlexibleRoute,
      'maxDetourKm': maxDetourKm,
      'verificationDocuments': verificationDocuments,
    };

    // Only include ID if it's not empty (for updates)
    if (id.isNotEmpty) {
      json['id'] = id;
    }

    return json;
  }

  factory TravelTrip.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (v is String) {
        return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
      if (v is Timestamp) return v.toDate();
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    double _parseDouble(dynamic v, [double fallback = 0.0]) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    String _parseString(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      return v.toString();
    }

    TransportMode _parseTransportMode(dynamic v) {
      if (v is String) {
        return TransportMode.values.firstWhere(
          (e) => e.name == v,
          orElse: () => TransportMode.car,
        );
      }
      return TransportMode.car;
    }

    TripStatus _parseTripStatus(dynamic v) {
      if (v is String) {
        return TripStatus.values.firstWhere(
          (e) => e.name == v,
          orElse: () => TripStatus.active,
        );
      }
      return TripStatus.active;
    }

    List<PackageType> _parseAcceptedTypes(dynamic v) {
      if (v is List) {
        return v
            .map((item) => PackageType.values.firstWhere(
                  (e) => e.name == item.toString(),
                  orElse: () => PackageType.other,
                ))
            .toList();
      }
      return [];
    }

    return TravelTrip(
      id: _parseString(json['id'], ''),
      travelerId: _parseString(json['travelerId']),
      travelerName: _parseString(json['travelerName'], 'Traveler'),
      travelerPhotoUrl: _parseString(json['travelerPhotoUrl']),
      departureLocation: Location.fromJson(
        (json['departureLocation'] as Map).cast<String, dynamic>(),
      ),
      destinationLocation: Location.fromJson(
        (json['destinationLocation'] as Map).cast<String, dynamic>(),
      ),
      departureDate: _parseDate(json['departureDate']),
      arrivalDate:
          json['arrivalDate'] != null ? _parseDate(json['arrivalDate']) : null,
      transportMode: _parseTransportMode(json['transportMode']),
      capacity: TripCapacity.fromJson(
        (json['capacity'] as Map).cast<String, dynamic>(),
      ),
      suggestedReward: _parseDouble(json['suggestedReward']),
      acceptedItemTypes: _parseAcceptedTypes(json['acceptedItemTypes']),
      routeStops: List<String>.from(json['routeStops'] ?? const []),
      status: _parseTripStatus(json['status']),
      acceptedPackageIds:
          List<String>.from(json['acceptedPackageIds'] ?? const []),
      totalPackagesAccepted:
          (json['totalPackagesAccepted'] as num?)?.toInt() ?? 0,
      totalEarnings: _parseDouble(json['totalEarnings']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      notes: json['notes']?.toString(),
      isFlexibleRoute: (json['isFlexibleRoute'] as bool?) ?? false,
      maxDetourKm: (json['maxDetourKm'] as num?)?.toDouble(),
      verificationDocuments:
          List<String>.from(json['verificationDocuments'] ?? const []),
    );
  }

  TravelTrip copyWith({
    String? id,
    String? travelerId,
    String? travelerName,
    String? travelerPhotoUrl,
    Location? departureLocation,
    Location? destinationLocation,
    DateTime? departureDate,
    DateTime? arrivalDate,
    TransportMode? transportMode,
    TripCapacity? capacity,
    double? suggestedReward,
    List<PackageType>? acceptedItemTypes,
    List<String>? routeStops,
    TripStatus? status,
    List<String>? acceptedPackageIds,
    int? totalPackagesAccepted,
    double? totalEarnings,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    bool? isFlexibleRoute,
    double? maxDetourKm,
    List<String>? verificationDocuments,
  }) {
    return TravelTrip(
      id: id ?? this.id,
      travelerId: travelerId ?? this.travelerId,
      travelerName: travelerName ?? this.travelerName,
      travelerPhotoUrl: travelerPhotoUrl ?? this.travelerPhotoUrl,
      departureLocation: departureLocation ?? this.departureLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      departureDate: departureDate ?? this.departureDate,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      transportMode: transportMode ?? this.transportMode,
      capacity: capacity ?? this.capacity,
      suggestedReward: suggestedReward ?? this.suggestedReward,
      acceptedItemTypes: acceptedItemTypes ?? this.acceptedItemTypes,
      routeStops: routeStops ?? this.routeStops,
      status: status ?? this.status,
      acceptedPackageIds: acceptedPackageIds ?? this.acceptedPackageIds,
      totalPackagesAccepted:
          totalPackagesAccepted ?? this.totalPackagesAccepted,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      isFlexibleRoute: isFlexibleRoute ?? this.isFlexibleRoute,
      maxDetourKm: maxDetourKm ?? this.maxDetourKm,
      verificationDocuments:
          verificationDocuments ?? this.verificationDocuments,
    );
  }
}

class TripCapacity {
  final double maxWeightKg;
  final double maxVolumeLiters;
  final int maxPackages;
  final List<PackageSize> acceptedSizes;

  TripCapacity({
    required this.maxWeightKg,
    required this.maxVolumeLiters,
    required this.maxPackages,
    this.acceptedSizes = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'maxWeightKg': maxWeightKg,
      'maxVolumeLiters': maxVolumeLiters,
      'maxPackages': maxPackages,
      'acceptedSizes': acceptedSizes.map((e) => e.name).toList(),
    };
  }

  factory TripCapacity.fromJson(Map<String, dynamic> json) {
    return TripCapacity(
      maxWeightKg: (json['maxWeightKg'] as num?)?.toDouble() ??
          10.0, // Default to 10kg if null
      maxVolumeLiters: (json['maxVolumeLiters'] as num?)?.toDouble() ??
          50.0, // Default to 50L if null
      maxPackages: json['maxPackages'] ?? 5, // Default to 5 packages if null
      acceptedSizes: (json['acceptedSizes'] as List?)
              ?.map((item) =>
                  PackageSize.values.firstWhere((e) => e.name == item))
              .toList() ??
          [],
    );
  }
}

enum TransportMode {
  flight,
  train,
  bus,
  car,
  motorcycle,
  bicycle,
  walking,
  ship
}

enum TripStatus { active, full, inProgress, completed, cancelled }
