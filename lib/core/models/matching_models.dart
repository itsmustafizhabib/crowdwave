import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

// Enum for matching types
enum MatchingType { auto, manual }

// Matching criteria for filtering
class MatchingCriteria {
  final DateTime? startDate;
  final DateTime? endDate;
  final PackageSize? maxPackageSize;
  final double? maxWeight;
  final List<PackageType>? acceptedPackageTypes;
  final double? maxDistance;
  final double? minTravelerRating;
  final int? maxDeliveryDays;
  final double? maxCompensation;
  final double? minCompensation;
  final bool? urgentOnly;
  final bool? verifiedTravelersOnly;
  final TransportMode? preferredTransportMode;

  const MatchingCriteria({
    this.startDate,
    this.endDate,
    this.maxPackageSize,
    this.maxWeight,
    this.acceptedPackageTypes,
    this.maxDistance,
    this.minTravelerRating,
    this.maxDeliveryDays,
    this.maxCompensation,
    this.minCompensation,
    this.urgentOnly,
    this.verifiedTravelersOnly,
    this.preferredTransportMode,
  });

  Map<String, dynamic> toMap() {
    return {
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'maxPackageSize': maxPackageSize?.name,
      'maxWeight': maxWeight,
      'acceptedPackageTypes': acceptedPackageTypes?.map((e) => e.name).toList(),
      'maxDistance': maxDistance,
      'minTravelerRating': minTravelerRating,
      'maxDeliveryDays': maxDeliveryDays,
      'maxCompensation': maxCompensation,
      'minCompensation': minCompensation,
      'urgentOnly': urgentOnly,
      'verifiedTravelersOnly': verifiedTravelersOnly,
      'preferredTransportMode': preferredTransportMode?.name,
    };
  }

  factory MatchingCriteria.fromMap(Map<String, dynamic> map) {
    return MatchingCriteria(
      startDate:
          map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      maxPackageSize: map['maxPackageSize'] != null
          ? PackageSize.values
              .firstWhere((e) => e.name == map['maxPackageSize'])
          : null,
      maxWeight: map['maxWeight']?.toDouble(),
      acceptedPackageTypes: map['acceptedPackageTypes'] != null
          ? (map['acceptedPackageTypes'] as List<dynamic>)
              .map((e) =>
                  PackageType.values.firstWhere((type) => type.name == e))
              .toList()
          : null,
      maxDistance: map['maxDistance']?.toDouble(),
      minTravelerRating: map['minTravelerRating']?.toDouble(),
      maxDeliveryDays: map['maxDeliveryDays'],
      maxCompensation: map['maxCompensation']?.toDouble(),
      minCompensation: map['minCompensation']?.toDouble(),
      urgentOnly: map['urgentOnly'],
      verifiedTravelersOnly: map['verifiedTravelersOnly'],
      preferredTransportMode: map['preferredTransportMode'] != null
          ? TransportMode.values
              .firstWhere((e) => e.name == map['preferredTransportMode'])
          : null,
    );
  }
}

// Match result between a package and a trip
class MatchResult {
  final String id;
  final String packageRequestId;
  final String tripId;
  final String senderId;
  final String travelerId;
  final double matchScore; // 0.0 to 100.0
  final MatchingType matchingType;
  final Map<String, dynamic> matchingFactors;
  final MatchStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final double? negotiatedPrice;

  MatchResult({
    required this.id,
    required this.packageRequestId,
    required this.tripId,
    required this.senderId,
    required this.travelerId,
    required this.matchScore,
    required this.matchingType,
    required this.matchingFactors,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.negotiatedPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageRequestId': packageRequestId,
      'tripId': tripId,
      'senderId': senderId,
      'travelerId': travelerId,
      'matchScore': matchScore,
      'matchingType': matchingType.name,
      'matchingFactors': matchingFactors,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'rejectionReason': rejectionReason,
      'negotiatedPrice': negotiatedPrice,
    };
  }

  factory MatchResult.fromMap(Map<String, dynamic> map) {
    return MatchResult(
      id: map['id'] ?? '',
      packageRequestId: map['packageRequestId'] ?? '',
      tripId: map['tripId'] ?? '',
      senderId: map['senderId'] ?? '',
      travelerId: map['travelerId'] ?? '',
      matchScore: (map['matchScore'] ?? 0.0).toDouble(),
      matchingType: MatchingType.values.firstWhere(
        (e) => e.name == map['matchingType'],
        orElse: () => MatchingType.manual,
      ),
      matchingFactors: Map<String, dynamic>.from(map['matchingFactors'] ?? {}),
      status: MatchStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MatchStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (map['rejectedAt'] as Timestamp?)?.toDate(),
      rejectionReason: map['rejectionReason'],
      negotiatedPrice: map['negotiatedPrice']?.toDouble(),
    );
  }
}

enum MatchStatus { pending, accepted, rejected, expired, cancelled }

// Matching preferences for users
class UserMatchingPreferences {
  final String userId;
  final MatchingCriteria senderCriteria;
  final MatchingCriteria travelerCriteria;
  final bool autoMatchingEnabled;
  final bool pushNotificationsEnabled;
  final int maxDailyMatches;
  final DateTime updatedAt;

  UserMatchingPreferences({
    required this.userId,
    required this.senderCriteria,
    required this.travelerCriteria,
    required this.autoMatchingEnabled,
    required this.pushNotificationsEnabled,
    required this.maxDailyMatches,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'senderCriteria': senderCriteria.toMap(),
      'travelerCriteria': travelerCriteria.toMap(),
      'autoMatchingEnabled': autoMatchingEnabled,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'maxDailyMatches': maxDailyMatches,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserMatchingPreferences.fromMap(Map<String, dynamic> map) {
    return UserMatchingPreferences(
      userId: map['userId'] ?? '',
      senderCriteria: MatchingCriteria.fromMap(map['senderCriteria'] ?? {}),
      travelerCriteria: MatchingCriteria.fromMap(map['travelerCriteria'] ?? {}),
      autoMatchingEnabled: map['autoMatchingEnabled'] ?? true,
      pushNotificationsEnabled: map['pushNotificationsEnabled'] ?? true,
      maxDailyMatches: map['maxDailyMatches'] ?? 10,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// Nearby suggestion data
class NearbySuggestion {
  final String id;
  final String title;
  final String description;
  final double distance; // in kilometers
  final LocationPoint location;
  final String type; // 'package', 'trip', 'landmark'
  final DateTime validUntil;
  final Map<String, dynamic>? metadata;

  NearbySuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.distance,
    required this.location,
    required this.type,
    required this.validUntil,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'distance': distance,
      'location': location.toMap(),
      'type': type,
      'validUntil': Timestamp.fromDate(validUntil),
      'metadata': metadata,
    };
  }

  factory NearbySuggestion.fromMap(Map<String, dynamic> map) {
    return NearbySuggestion(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      distance: (map['distance'] ?? 0.0).toDouble(),
      location: LocationPoint.fromMap(map['location']),
      type: map['type'] ?? '',
      validUntil: (map['validUntil'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }
}
