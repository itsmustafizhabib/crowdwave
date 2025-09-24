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
  final DeliveryStatus status;
  final List<LocationPoint> trackingPoints;
  final DateTime? pickupTime;
  final DateTime? deliveryTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final LocationPoint? currentLocation;

  DeliveryTracking({
    required this.id,
    required this.packageRequestId,
    required this.travelerId,
    required this.status,
    required this.trackingPoints,
    this.pickupTime,
    this.deliveryTime,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.currentLocation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageRequestId': packageRequestId,
      'travelerId': travelerId,
      'status': status.name,
      'trackingPoints': trackingPoints.map((point) => point.toMap()).toList(),
      'pickupTime': pickupTime != null ? Timestamp.fromDate(pickupTime!) : null,
      'deliveryTime': deliveryTime != null ? Timestamp.fromDate(deliveryTime!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'notes': notes,
      'currentLocation': currentLocation?.toMap(),
    };
  }

  factory DeliveryTracking.fromMap(Map<String, dynamic> map) {
    return DeliveryTracking(
      id: map['id'] ?? '',
      packageRequestId: map['packageRequestId'] ?? '',
      travelerId: map['travelerId'] ?? '',
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DeliveryStatus.pending,
      ),
      trackingPoints: (map['trackingPoints'] as List<dynamic>?)
          ?.map((point) => LocationPoint.fromMap(point as Map<String, dynamic>))
          .toList() ?? [],
      pickupTime: (map['pickupTime'] as Timestamp?)?.toDate(),
      deliveryTime: (map['deliveryTime'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'],
      currentLocation: map['currentLocation'] != null 
          ? LocationPoint.fromMap(map['currentLocation'] as Map<String, dynamic>)
          : null,
    );
  }

  DeliveryTracking copyWith({
    String? id,
    String? packageRequestId,
    String? travelerId,
    DeliveryStatus? status,
    List<LocationPoint>? trackingPoints,
    DateTime? pickupTime,
    DateTime? deliveryTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    LocationPoint? currentLocation,
  }) {
    return DeliveryTracking(
      id: id ?? this.id,
      packageRequestId: packageRequestId ?? this.packageRequestId,
      travelerId: travelerId ?? this.travelerId,
      status: status ?? this.status,
      trackingPoints: trackingPoints ?? this.trackingPoints,
      pickupTime: pickupTime ?? this.pickupTime,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      currentLocation: currentLocation ?? this.currentLocation,
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
