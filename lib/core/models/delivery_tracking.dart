import 'package:cloud_firestore/cloud_firestore.dart';

enum DeliveryStatus {
  pending,
  picked_up,
  in_transit,
  delivered,
  cancelled,
}

class LocationPoint {
  final double latitude;
  final double longitude;
  final String address;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'] ?? '',
    );
  }
}

class DeliveryTracking {
  final String id;
  final String packageRequestId;
  final String travelerId;
  final String senderId; // Added senderId field
  final DeliveryStatus status;
  final List<LocationPoint> trackingPoints;
  final DateTime? pickupTime;
  final DateTime? deliveryTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final LocationPoint? currentLocation;

  // New fields for delivery confirmation system
  final bool senderConfirmed; // Sender confirmed delivery
  final DateTime? senderConfirmedAt; // When sender confirmed
  final String? deliveryPhotoUrl; // Photo proof from traveler
  final String? senderFeedback; // Feedback from sender
  final double? senderRating; // Rating from sender (1-5)

  DeliveryTracking({
    required this.id,
    required this.packageRequestId,
    required this.travelerId,
    required this.senderId, // Added senderId parameter
    required this.status,
    required this.trackingPoints,
    this.pickupTime,
    this.deliveryTime,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.currentLocation,
    this.senderConfirmed = false,
    this.senderConfirmedAt,
    this.deliveryPhotoUrl,
    this.senderFeedback,
    this.senderRating,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageRequestId': packageRequestId,
      'travelerId': travelerId,
      'senderId': senderId, // Added senderId to map
      'status': status.name,
      'trackingPoints': trackingPoints.map((point) => point.toMap()).toList(),
      'pickupTime': pickupTime != null ? Timestamp.fromDate(pickupTime!) : null,
      'deliveryTime':
          deliveryTime != null ? Timestamp.fromDate(deliveryTime!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'notes': notes,
      'currentLocation': currentLocation?.toMap(),
      'senderConfirmed': senderConfirmed,
      'senderConfirmedAt': senderConfirmedAt != null
          ? Timestamp.fromDate(senderConfirmedAt!)
          : null,
      'deliveryPhotoUrl': deliveryPhotoUrl,
      'senderFeedback': senderFeedback,
      'senderRating': senderRating,
    };
  }

  factory DeliveryTracking.fromMap(Map<String, dynamic> map) {
    return DeliveryTracking(
      id: map['id'] ?? '',
      packageRequestId: map['packageRequestId'] ?? '',
      travelerId: map['travelerId'] ?? '',
      senderId: map['senderId'] ?? '', // Added senderId from map
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DeliveryStatus.pending,
      ),
      trackingPoints: (map['trackingPoints'] as List<dynamic>?)
              ?.map((point) =>
                  LocationPoint.fromMap(point as Map<String, dynamic>))
              .toList() ??
          [],
      pickupTime: (map['pickupTime'] as Timestamp?)?.toDate(),
      deliveryTime: (map['deliveryTime'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'],
      currentLocation: map['currentLocation'] != null
          ? LocationPoint.fromMap(
              map['currentLocation'] as Map<String, dynamic>)
          : null,
      senderConfirmed: map['senderConfirmed'] ?? false,
      senderConfirmedAt: (map['senderConfirmedAt'] as Timestamp?)?.toDate(),
      deliveryPhotoUrl: map['deliveryPhotoUrl'],
      senderFeedback: map['senderFeedback'],
      senderRating: map['senderRating']?.toDouble(),
    );
  }

  DeliveryTracking copyWith({
    String? id,
    String? packageRequestId,
    String? travelerId,
    String? senderId, // Added senderId parameter
    DeliveryStatus? status,
    List<LocationPoint>? trackingPoints,
    DateTime? pickupTime,
    DateTime? deliveryTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    LocationPoint? currentLocation,
    bool? senderConfirmed,
    DateTime? senderConfirmedAt,
    String? deliveryPhotoUrl,
    String? senderFeedback,
    double? senderRating,
  }) {
    return DeliveryTracking(
      id: id ?? this.id,
      packageRequestId: packageRequestId ?? this.packageRequestId,
      travelerId: travelerId ?? this.travelerId,
      senderId: senderId ?? this.senderId, // Added senderId assignment
      status: status ?? this.status,
      trackingPoints: trackingPoints ?? this.trackingPoints,
      pickupTime: pickupTime ?? this.pickupTime,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      currentLocation: currentLocation ?? this.currentLocation,
      senderConfirmed: senderConfirmed ?? this.senderConfirmed,
      senderConfirmedAt: senderConfirmedAt ?? this.senderConfirmedAt,
      deliveryPhotoUrl: deliveryPhotoUrl ?? this.deliveryPhotoUrl,
      senderFeedback: senderFeedback ?? this.senderFeedback,
      senderRating: senderRating ?? this.senderRating,
    );
  }

  // Helper methods
  bool get isInProgress => [
        DeliveryStatus.picked_up,
        DeliveryStatus.in_transit,
      ].contains(status);

  bool get isCompleted => status == DeliveryStatus.delivered;

  bool get isCancelled => status == DeliveryStatus.cancelled;

  double? get progressPercentage {
    switch (status) {
      case DeliveryStatus.pending:
        return 0.0;
      case DeliveryStatus.picked_up:
        return 25.0;
      case DeliveryStatus.in_transit:
        return 75.0;
      case DeliveryStatus.delivered:
        return 100.0;
      case DeliveryStatus.cancelled:
        return null;
    }
  }
}
