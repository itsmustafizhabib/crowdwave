import 'package:cloud_firestore/cloud_firestore.dart';

class PackageRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String senderPhotoUrl;
  final Location pickupLocation;
  final Location destinationLocation;
  final PackageDetails packageDetails;
  final DateTime preferredDeliveryDate;
  final DateTime? flexibleDateStart;
  final DateTime? flexibleDateEnd;
  final double compensationOffer;
  final bool insuranceRequired;
  final double? insuranceValue;
  final List<String> photoUrls;
  final PackageStatus status;
  final String? assignedTravelerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? specialInstructions;
  final bool isUrgent;
  final List<String> preferredTransportModes;

  PackageRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.packageDetails,
    required this.preferredDeliveryDate,
    required this.compensationOffer,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.flexibleDateStart,
    this.flexibleDateEnd,
    this.insuranceRequired = false,
    this.insuranceValue,
    this.photoUrls = const [],
    this.assignedTravelerId,
    this.specialInstructions,
    this.isUrgent = false,
    this.preferredTransportModes = const [],
  });

  Map<String, dynamic> toJson() {
    final json = {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'pickupLocation': pickupLocation.toJson(),
      'destinationLocation': destinationLocation.toJson(),
      'packageDetails': packageDetails.toJson(),
      'preferredDeliveryDate': preferredDeliveryDate.toIso8601String(),
      'flexibleDateStart': flexibleDateStart?.toIso8601String(),
      'flexibleDateEnd': flexibleDateEnd?.toIso8601String(),
      'compensationOffer': compensationOffer,
      'insuranceRequired': insuranceRequired,
      'insuranceValue': insuranceValue,
      'photoUrls': photoUrls,
      'status': status.name,
      'assignedTravelerId': assignedTravelerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'specialInstructions': specialInstructions,
      'isUrgent': isUrgent,
      'preferredTransportModes': preferredTransportModes,
    };

    // Only include ID if it's not empty (for updates)
    if (id.isNotEmpty) {
      json['id'] = id;
    }

    return json;
  }

  factory PackageRequest.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      throw Exception('Unknown date type: \\${value.runtimeType}');
    }

    return PackageRequest(
      id: json['id'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderPhotoUrl: json['senderPhotoUrl'],
      pickupLocation: Location.fromJson(json['pickupLocation']),
      destinationLocation: Location.fromJson(json['destinationLocation']),
      packageDetails: PackageDetails.fromJson(json['packageDetails']),
      preferredDeliveryDate: _parseDate(json['preferredDeliveryDate']),
      flexibleDateStart: json['flexibleDateStart'] != null
          ? _parseDate(json['flexibleDateStart'])
          : null,
      flexibleDateEnd: json['flexibleDateEnd'] != null
          ? _parseDate(json['flexibleDateEnd'])
          : null,
      compensationOffer: json['compensationOffer'].toDouble(),
      insuranceRequired: json['insuranceRequired'] ?? false,
      insuranceValue: json['insuranceValue']?.toDouble(),
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      status: PackageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PackageStatus.pending,
      ),
      assignedTravelerId: json['assignedTravelerId'],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      specialInstructions: json['specialInstructions'],
      isUrgent: json['isUrgent'] ?? false,
      preferredTransportModes:
          List<String>.from(json['preferredTransportModes'] ?? []),
    );
  }

  PackageRequest copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    Location? pickupLocation,
    Location? destinationLocation,
    PackageDetails? packageDetails,
    DateTime? preferredDeliveryDate,
    DateTime? flexibleDateStart,
    DateTime? flexibleDateEnd,
    double? compensationOffer,
    bool? insuranceRequired,
    double? insuranceValue,
    List<String>? photoUrls,
    PackageStatus? status,
    String? assignedTravelerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? specialInstructions,
    bool? isUrgent,
    List<String>? preferredTransportModes,
  }) {
    return PackageRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      packageDetails: packageDetails ?? this.packageDetails,
      preferredDeliveryDate:
          preferredDeliveryDate ?? this.preferredDeliveryDate,
      flexibleDateStart: flexibleDateStart ?? this.flexibleDateStart,
      flexibleDateEnd: flexibleDateEnd ?? this.flexibleDateEnd,
      compensationOffer: compensationOffer ?? this.compensationOffer,
      insuranceRequired: insuranceRequired ?? this.insuranceRequired,
      insuranceValue: insuranceValue ?? this.insuranceValue,
      photoUrls: photoUrls ?? this.photoUrls,
      status: status ?? this.status,
      assignedTravelerId: assignedTravelerId ?? this.assignedTravelerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      isUrgent: isUrgent ?? this.isUrgent,
      preferredTransportModes:
          preferredTransportModes ?? this.preferredTransportModes,
    );
  }
}

class PackageDetails {
  final String description;
  final PackageSize size;
  final double weightKg;
  final PackageType type;
  final String? brand;
  final double? valueUSD;
  final bool isFragile;
  final bool isPerishable;
  final bool requiresRefrigeration;
  final List<String> prohibitedItems;

  PackageDetails({
    required this.description,
    required this.size,
    required this.weightKg,
    required this.type,
    this.brand,
    this.valueUSD,
    this.isFragile = false,
    this.isPerishable = false,
    this.requiresRefrigeration = false,
    this.prohibitedItems = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'size': size.name,
      'weightKg': weightKg,
      'type': type.name,
      'brand': brand,
      'valueUSD': valueUSD,
      'isFragile': isFragile,
      'isPerishable': isPerishable,
      'requiresRefrigeration': requiresRefrigeration,
      'prohibitedItems': prohibitedItems,
    };
  }

  factory PackageDetails.fromJson(Map<String, dynamic> json) {
    return PackageDetails(
      description: json['description'],
      size: PackageSize.values.firstWhere(
        (e) => e.name == json['size'],
        orElse: () {
          print('[ERROR] Unknown package size: \\${json['size']}');
          return PackageSize.values.first;
        },
      ),
      weightKg: (json['weightKg'] as num?)?.toDouble() ??
          1.0, // Default to 1kg if null
      type: PackageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () {
          print('[ERROR] Unknown package type: \\${json['type']}');
          return PackageType.other;
        },
      ),
      brand: json['brand'],
      valueUSD: (json['valueUSD'] as num?)?.toDouble(),
      isFragile: json['isFragile'] ?? false,
      isPerishable: json['isPerishable'] ?? false,
      requiresRefrigeration: json['requiresRefrigeration'] ?? false,
      prohibitedItems: List<String>.from(json['prohibitedItems'] ?? []),
    );
  }
}

class Location {
  final String address;
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? placeId;

  Location({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.placeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'placeId': placeId,
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ??
          0.0, // Default to 0.0 if null
      longitude: (json['longitude'] as num?)?.toDouble() ??
          0.0, // Default to 0.0 if null
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postalCode'],
      placeId: json['placeId'],
    );
  }
}

enum PackageStatus {
  pending,
  matched,
  confirmed,
  pickedUp,
  inTransit,
  delivered,
  cancelled,
  disputed
}

enum PackageSize {
  small, // Fits in pocket/small bag
  medium, // Shoebox size
  large, // Suitcase space required
  extraLarge // Requires special arrangement
}

enum PackageType {
  documents,
  electronics,
  clothing,
  food,
  medicine,
  gifts,
  books,
  cosmetics,
  other
}
